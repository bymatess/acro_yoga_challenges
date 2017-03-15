package Meet::Invitation;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';

post '/application/send/:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_not_author => 1,
			author_id => $user->{id},
			is_not_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my $answer_text = params->{answer_text}||"";
		$answer_text =~ s/^\s+//;
		$answer_text =~ s/\s+$//;
		if ($answer_text) {
			my $invitation = Meet::Helpers::get_invitation_info($event_id, $user->{id});
			my $ok = 0;
			if ($invitation->{_ERROR}) {
				# invitation/application doesn't exist -> insert
				my $sth = database->prepare("
				insert into e_invitation
				(event_id, user_id, answer, answer_text)
				values (?, ?, '1', ?)
				");
				$ok = $sth->execute($event_id, $user->{id}, $answer_text);
			} else {
				# invitation/application does exist -> update
				my $sth = database->prepare("
				update e_invitation
				set answer = 1, answer_text = ?
				where event_id = ?
				and user_id = ?
				");
				$ok = $sth->execute($answer_text, $event_id, $user->{id});
			}
			if ($ok) {
				flash('ok',"Your application was sent.");
				return redirect('/event/show/'.$event_id);
			} else {
				flash('error', 'There was a problem in saving your application to database, please try it again.');
				return forward('/application/'.$event_id, undef, {method => 'GET'});
			}
		} else {
			flash('error', "Text of your application must not be empty.");
			return forward('/application/'.$event_id, undef, {method => 'GET'});
		}
	}
};

post '/application/answer/:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	database->{AutoCommit} = 0;
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_author => 1,
			author_id => $user->{id},
			is_not_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my $ok = 1;
		my @applications;
		if (defined params->{applications}) {
			if (params->{applications} =~ /^ARRAY/) {
# TODO this is weird, INTERNET find how to do it better
				push @applications, @{params->{applications}};
			} else {
				push @applications, params->{applications};
			}
			my $sth = database->prepare("update e_invitation
			set invitation = ?, invitation_text = ?
			where event_id = ? and user_id = ?");
			for my $user_id (@applications) {
				if ((not defined params->{"invitation_$user_id"}) ||
					(params->{"invitation_$user_id"} !~ /[01]/)
				) {
					next;
				}
				my $invitation = params->{"invitation_$user_id"};
				if (defined params->{"invitation_text_$user_id"}) {
					my $invitation_text = params->{"invitation_text_$user_id"};
					$invitation_text =~ s/^\s+//;
					$invitation_text =~ s/\s+$//;
					$ok = $sth->execute($invitation, $invitation_text,
								 $event_id, $user_id);
					if (!$ok) {
						goto END;
					}
				}
			}
		}
END:
		my $result = ($ok ? database->commit : database->rollback );
		if ($ok && $result) {
			flash('ok', "Your answers were sent to the users.");
			return redirect("/application/show/$event_id");
		} else {
			debug(database->errstr);
			flash('error', 'There was a problem in saving your application to database, please try it again.');
			return forward(request->{path_info}, undef, {method => 'GET'});
		}
	}
};
get '/application/answer/:event_id' => sub {
	my $event_id = params->{event_id};
	show_edit_applications($event_id, {answering => 1});
};
get '/application/show/:event_id' => sub {
	my $event_id = params->{event_id};
	show_edit_applications($event_id, {answering => 0});
};
sub show_edit_applications {
	my ($event_id, $params) = @_;
	my $answering = 0;
	if ($params->{answering}) {
		$answering = $params->{answering};
	}
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_author => 1,
			author_id => session->{user}->{id},
			is_not_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my $applications;
		$applications = database->selectall_hashref("
		select event_id, user_id,
		(select CONCAT(first_name, ' ', last_name) from users where id = user_id) full_name,
		 invitation, invitation_text,
		answer, answer_text, 
		date_format(timestamp, '%e.%c.%Y %k:%i') timestamp
		from e_invitation
		where event_id = ?
		and answer_text is not null
		", "user_id", {}, $event_id);
		return template("show_applications", { 
			applications => $applications,
			event => $event,
			answering => $answering
			});
	}
};
get '/application/:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_not_author => 1,
			author_id => $user->{id},
			is_not_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		return template('application', {event => $event});
	}
};
post '/invitation/answer/:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_not_author => 1,
			author_id => $user->{id},
			is_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect('/');
	} else {
		my $invitation = Meet::Helpers::get_invitation_info($event_id, $user->{id});
		if ($invitation->{_ERROR}) {
			flash('error', $invitation->{_ERROR});
			return redirect('/');
		} else {
			my ($answer, $answer_text);
			if (defined params->{"answer_text_".$event_id}) {
				$answer_text = params->{"answer_text_".$event_id};
				$answer_text =~ s/^\s+//;
				$answer_text =~ s/\s+$//;
				if (!$answer_text) {
					$answer_text = "User didn't leave any personal message.";
				}
			}
			if (params->{"accept_$event_id"}) {
				$answer = 1;
			} elsif (params->{"reject_$event_id"}) {
				$answer = 0;
			}
			my $sth = database->prepare("
			update e_invitation
			set answer = ?, answer_text = ?
			where event_id = ?
			and user_id = ?
			");
			my $ok = $sth->execute($answer, $answer_text, $event_id, $user->{id});
			if ($ok) {
				if ($answer) {
					flash('ok', 'Invitation was accepted.');
				} else {
					flash('ok', 'Invitation was rejected.');
				}
				return redirect('/event/show/'.$event_id);
			} else {
				flash('error', 'There was a problem in saving your answer to database, please try it again.');
				return forward('/invitation/answer/'.$event_id, undef, {method => 'GET'});
			}
		}
	}
};
get '/invitation/answer/:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_not_author => 1,
			author_id => $user->{id},
			is_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my $invitation = Meet::Helpers::get_invitation_info($event_id, $user->{id});
		if ($invitation->{_ERROR}) {
			flash('error', $invitation->{_ERROR});
			return redirect('/');
		} else {
			return template('invitation_answer', {event => $event, invitation => $invitation});
		}
	}
};
true;

