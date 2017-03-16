package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';

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



get '/' => sub {
	return template('index', {});
};

hook 'before_template_render' => sub {
	my $tokens = shift;
	my @categories = database->quick_select('category', { }, {columns => ['id', 'name'], order_by => 'name'});
	$tokens->{categories} = \@categories;
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

get "/position/:position_id" => sub {
	my $position_id = params->{position_id};
	my $position_sth = database->prepare("select position.id as position_id,
position.user_id as user_id,
position.name as name,
users.first_name as user_name,
category.name as category_name,
category.id as category_id,
position.created as created,
position.description as description
FROM position, users, category 
WHERE position.id = ? and position.category_id = category.id and position.user_id = users.id");
        $position_sth->execute($position_id);
        my $position = $position_sth->fetchrow_hashref();

	my $sth = database->prepare("select id from p_photo where position_id = ?");
        $sth->execute($position_id);
        my $photos = $sth->fetchall_arrayref();

	return template('position', {position => $position, photos => $photos});
};
get '/position/images/:photo_id' => sub {
        my $user = session('user');
        my $photo_id = params->{photo_id};
        my $user_id = params->{user_id};
        my $photo = database->quick_select("p_photo", { id => $photo_id });
        if ($photo->{id}) {
                header 'Content-Type' => 'image/jpeg';
                return $photo->{photo};
        } else {
                my $default_photo = database->quick_select("u_photo", { user_id => 1, id => 15 });
                header 'Content-Type' => 'image/jpeg';
                return $default_photo->{photo};
        }
};

post '/position/:position_id/upload_photo' => sub {
        my $MAX_PHOTO_SIZE = 5000000;
        my $user = session('user');
        my $file = request->upload('photo');
        #use Data::Dumper;
        #print Dumper($file);
	my $position_id = params->{position_id};
	my $exists = database->quick_select("position", { id => $position_id });
	if (!$exists) {
		flash error => "Position doesn't exist";
                return template("upload_photo");
	}

        if ($file->size > $MAX_PHOTO_SIZE) {
                flash error => "Photo is too big. Max. upload size is 5Mb.";
                return template("upload_photo");
        } elsif ($file->headers->{'Content-Type'} !~ /image/i){
                # TODO more secure checking, not just the header it's stupid and pdf with .jpg will go through;
                flash error => "A file you are trying to upload is not a picture.";
                return template("upload_photo");
        } else {
                my $photo;
                my $fh = $file->file_handle;
                binmode($fh);
                while (my $part = <$fh>) {
                        $photo .= $part;
                }
                my $sth = database->prepare("insert into p_photo (user_id, photo, position_id) values (?, ?, ?)");
                $sth->execute($user->{id}, $photo, $position_id); # insert new one

                flash ok => "Photo was uploaded.";

        }
        return redirect("/position/$position_id");
};
get '/position/:position_id/upload_photo' => sub {
        my $user = session('user');
	my $position_id = params->{position_id};
	my $exists = database->quick_select("position", { id => $position_id });
	if (!$exists) {
		flash error => "Position doesn't exist";
                return template("upload_photo");
	}
        return template("upload_photo");
};



1;
