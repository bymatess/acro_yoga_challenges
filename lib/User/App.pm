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
	my $events;
	$events = Meet::Helpers::get_events({week => '1'});
	#print Dumper($events);
	return template('index', {cal => $events});
};

hook 'before_template_render' => sub {
	my $tokens = shift;
	$tokens->{specific_scripts} = vars->{specific_scripts} || "";
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

post "/users" => sub {
	debug("POST request at ".request->{path_info});
return redirect("/users");
};
get "/users" => sub {
	my $user = session('user');
	my $where = "";
	my $where_exists = ""; # for filters based on user's answer to profile questions
	my @params;
	if (defined params->{"send"}) {
# user wants to filter results...
# TODO specialni znaky, diakritika
		if (defined params->{filter_first_name} and params->{filter_first_name}) {
			if (params->{filter_first_name} =~ /^[a-zA-Z0-9 -]+$/) {
# TODO length of the name!!!
				$where .= "AND first_name like CONCAT(?, '%') collate utf8_general_ci ";
				push @params, params->{filter_first_name};
			} else {
				flash("error", "'First name' contains special symbols. Filter is ignored.");
			}
		}
		if (defined params->{filter_last_name} && params->{filter_last_name}) {
			if (params->{filter_last_name} =~ /^[a-zA-Z0-9 -]+$/) {
# TODO length of the name!!!
				$where .= "AND last_name like CONCAT(?, '%') collate utf8_general_ci ";
				push @params, params->{filter_last_name};
			} else {
				flash("error", "'Last name' contains special symbols. Filter is ignored.");
			} 
		}
		if (defined params->{filter_gender}) {
			if (params->{filter_gender} eq 'male') {
				$where .= "AND gender = '0' "; 
			} elsif (params->{filter_gender} eq 'female') {
				$where .= "AND gender = '1' "; 
			}
		}
		my @checked_questions; # params in format i_INFORMATIONID_ANSWERID
		@checked_questions = grep {$_ =~ /^i_\d+_\d+$/} params;
		my $previous_i = "";
		for my $answer (sort {$a cmp $b } @checked_questions) {
			my (undef, $i_id, $a_id) = split("_", $answer);
			if ($previous_i eq $i_id) {
				$where_exists .= "OR (information_id = ? and answer = ?) ";
			} else {
				if ($previous_i) {
					$where_exists .= ") \n ) \n AND ";
				}
				$previous_i = $i_id;
				$where_exists .= "EXISTS (
						select 1 
						from u_information 
						where user_id = users.id 
						AND ( (information_id = ? and answer = ?) 
						";
			}
			push @params, $i_id;
			push @params, $a_id;
		}
		if ($where) {
			$where =~ s/^AND//;
			$where = "WHERE $where ";
		}
		if ($where_exists) {
			if ($where) {
				$where_exists = "\n AND $where_exists ";
			} else {
				$where_exists = "\n WHERE $where_exists ";
			}
			$where_exists = "$where_exists ) ) "; #close braclets
		}
	}
	my $answers;
	$answers = database->selectall_hashref("
	select information_id, answ.id answer_id, reg.headline headline,
	reg.description description, answ.answer
	from u_information_reg reg, u_information_answers answ
	where reg.id = answ.information_id
	and reg.options = 1
	", "answer_id", {});
	my $no_filters = "1";
	# TODO XXX upravit :-)
	if (0 && !$where && !$where_exists) {
		$no_filters = 1;
		return template('user_show_all', { no_filters => $no_filters, answers => $answers});
	} else {
	# TODO this is really shitty SQL and will be slow!! 
		my $sth = database->prepare("
				select first_name, 
				last_name, id, birth_date, about,
				(select max(id) from u_photo where user_id = users.id) photo_id
				from users
				" # .$where.$where_exists
				);
	#print $where_exists."params: ".Dumper(\@params);
		$sth->execute(@params);
		my $users = $sth->fetchall_hashref('id');
	# default sorting is by last_name, I can add other later
		my @order = sort {uc($users->{$a}->{last_name}.$users->{$a}->{first_name}) 
					cmp 
				uc($users->{$b}->{last_name}.$users->{$b}->{first_name})} keys %{$users};
		$no_filters = "0";
		return template('user_show_all', { no_filters => $no_filters, users => $users, order => \@order, answers => $answers });
	}
	
};

true;
