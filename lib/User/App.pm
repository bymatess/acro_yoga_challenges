package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Net::Facebook::Oauth2;

use Data::Dumper;
our $VERSION = '0.1';

post "/test" => sub {
print STDERR Dumper(params);
	my $photos;
	foreach my $i (qw/1 2 3/) {
		my $file = "photo_$i";
		next unless params->{$file};

		$photos->{$file} = request->upload($file);
		if ($photos->{$file}->size > 500000) {
			flash error => "Photo is too big. Max. upload size is 5Mb.";
		} elsif ($photos->{$file}->headers->{'Content-Type'} !~ /image/i){
# TODO more secure checking, not just the header it's stupid and pdf with .jpg will go through;
			flash error => "A file you are trying to upload is not a picture.";
		}
	}

	return template('test');
};

get "/test" => sub {
	return template('test');
};
get "/position/:position_id/todo" => sub {
    header 'Content-Type' => 'application/json';
	my $position_id = params->{position_id};
	my $user = session("user");
	my $exists = database->quick_select("position", { id => $position_id });
        return to_json { type => "error", text => "Position doesn't exist"} if (!$exists);

	my $todo_exists = database->quick_select("accepted_challenge", { position_id => $position_id, user_id => $user->{id} });
	if ($todo_exists) {
		if ($todo_exists->{accepted}) {
    			return to_json { type => 'ok', text => "Challenge already accepted." };
		}
		if ($todo_exists->{completed}) {
    			return to_json { type => 'ok', text => "Challenge already conquered." };
		}
	} else {
		my $sth = database->prepare("insert into accepted_challenge (user_id, position_id, accepted) values (?, ?, NOW())");
                $sth->execute($user->{id}, $position_id); # insert new one
    		return to_json { type => 'ok', text => "You accepted the challenge. Good luck :-)" };
	}
	
	

    return to_json { type => 'error', text => "TODO position '$position_id'" };
};

get "/position/:position_id/done" => sub {
    header 'Content-Type' => 'application/json';
	my $position_id = params->{position_id};
	my $user = session("user");
	my $exists = database->quick_select("position", { id => $position_id });
        return to_json { type => "error", text => "Position doesn't exist"} if (!$exists);

	my $todo_exists = database->quick_select("accepted_challenge", { position_id => $position_id, user_id => $user->{id} });
	if ($todo_exists) {
		if ($todo_exists->{completed}) {
    			return to_json { type => 'ok', text => "Challenge already conquered." };
		} else {
			my $accepted = "";
			$accepted = ", accepted = NOW()";
			my $sth = database->prepare("update accepted_challenge set completed = NOW() $accepted where user_id = ? and position_id = ?");
			$sth->execute($user->{id}, $position_id); 
			return to_json { type => 'ok', text => "You conquered the challenge. Good job :-)" };
		}
	} else {
		my $sth = database->prepare("insert into accepted_challenge (user_id, position_id, accepted, completed) values (?, ?, NOW(), NOW())");
                $sth->execute($user->{id}, $position_id); # insert new one
    		return to_json { type => 'ok', text => "You conquered the challenge. Good job :-)" };
	}
	
	

    return to_json { type => 'error', text => "TODO position '$position_id'" };
};







sub send_mail {
	my ($from, $to, $subject, $text, $params) = @_;
	if (!$to) {
		return 0;
	}
	if (!$from) {
		if ($params->{"no-reply"}) {
			$from = "no-reply";
		} else {
			$from = "admin";
		}
	}
	if (!$subject) {
		$subject = "";
		return 0;
	}
	open MAIL, "|/usr/local/bin/sendmail -t" or die "No sendmail!\n"; 
## Mail Header
	print MAIL "To: $to\n";
	print MAIL "From: $from\n";
	print MAIL "Subject: $subject\n\n";
## Mail Body
	print MAIL $text;
	close(MAIL);
	return 1;
}


hook 'before_template_render' => sub {
	my $tokens = shift;
	my @categories = database->quick_select('category', { }, {columns => ['id', 'name'], order_by => 'id'});
	$tokens->{categories} = \@categories;
	vars->{categories} = \@categories;
};

hook 'after' => sub {
	my $response = shift;
	# fill in forms before sending them back to users
	#if (request->{path_info} !~ /\/user\/picture\/\d+\/\d+/) {
	if ($response->{content} =~ /<form /i) { #it breaks the url above...
		use HTML::FillInForm;
		$response->{content} = HTML::FillInForm->fill( \$response->{content},
			scalar params,
			 fill_password => 0 );
	}
};

get '/' => sub {
	my $positions_sth = database->prepare("
SELECT position.id AS position_id,
position.name AS position_name, 
category.name AS category_name,
(select id from p_photo where position_id = position.id LIMIT 1) AS photo_id
FROM position, category
WHERE position.category_id = category.id
ORDER BY position.id DESC
LIMIT 12
");
	$positions_sth->execute();
        my $positions = $positions_sth->fetchall_arrayref();
print STDERR Dumper($positions);
	return template('index', {positions => $positions});
};

get '/fb_log' => sub {
	my $fb_token = params->{code};
	return template('login', {}) if !$fb_token; #move to before hook?

	my $fb = Net::Facebook::Oauth2->new(
				application_id     => $app_id, 
				application_secret => $app_secret,
				callback           => 'http://localhost:3000/fb_log'
	);
	my $access_token = $fb->get_access_token(code => $fb_token);

	flash ok => "Login unsuccessful." if !$access_token;
	return template('login', {}) if !$access_token;

	$fb = Net::Facebook::Oauth2->new(
			access_token => $access_token
			);
	my $fields = join(',', qw/id first_name last_name email gender link locale name timezone/);
	my $info = $fb->get(
			'https://graph.facebook.com/v2.8/me?fields='.$fields,   # Facebook API URL
			);
	$info = $info->as_hash;
	$info->{gender} = 0 if $info->{gender} eq 'male';
	$info->{gender} = 1 if $info->{gender} eq 'female';
	print STDERR Dumper($info);
	if (!database->quick_select('users', { fb_id => $info->{id} })) {
		my $sth = database->prepare("insert into users (first_name, last_name, full_name, email, fb_id, gender, locale, timezone, profile_link, created, last_login) 
				values (?,?,?,?,?,?,?,?,?, NOW(), NOW())");
		$sth->execute(
				$info->{first_name},
				$info->{last_name},
				$info->{name},
				$info->{email},
				$info->{id},
				$info->{gender},
				$info->{locale},
				$info->{timezone},
				$info->{profile_link}
			     );
	}
	
	# create user session
	session user => database->quick_select('users', { fb_id => $info->{id} }); 

	flash ok => "Login successful.";
	return template('index', {});
};
get '/fb_login' => sub {

	my $fb = Net::Facebook::Oauth2->new(
			application_id     => $app_id, 
			application_secret => $app_secret,
			callback           => 'http://localhost:3000/fb_log'
			);

	# get the authorization URL for your application
	my $url = $fb->get_authorization_url(
			scope   => [ 'public_profile', 'email', 'user_friends' ],
			display => 'page'
			);
	return redirect($url);
};

1;
