package Meet::Event;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';

post '/event_create' => sub {
	return create_edit_event();
};
get '/event_create' => sub {
	my $user = session('user');
	my $sth = database->prepare("select * from e_kind_reg");
	$sth->execute();
	my $kinds = $sth->fetchall_hashref('id');

	var specific_scripts => q`
	<link href="plugins/bootstrap-timepicker/bootstrap-timepicker.min.css" rel="stylesheet" type="text/css">
	<script type="text/javascript" src='plugins/bootstrap-timepicker/bootstrap-timepicker.min.js'></script>
 <script type="text/javascript">
 $(window).load(function() 
                 {
		                 "use strict";

				                 $( "#datepicker-datetime" ).datepicker({ 
						 dateFormat: 'dd.mm.yy',
						 changeMonth: true,
						 changeYear: true,
						 yearRange: "-0:+10"
						 });
						                 })
$('#timepicker-default').timepicker({
		minuteStep: 1,
				template: false,
						showSeconds: false,
								showMeridian: false,
								maxTime: 23,
									});		
	</script>

	`;
	return template("event_create", {kinds => $kinds});
};
post '/event_edit_:event_id' => sub {
	my $event_id = params->{event_id};
	my $event = database->selectrow_hashref("
	select
	date_format(date_of_event, '%e.%c.%Y') date_of_event,
	(select headline from e_kind_reg where e_kind_reg.id = kind_id) kind_headline,
	date_format(date_of_event, '%k:%i') time_of_event,
	id, headline, description, author_id 
	from events 
	where id = ?
	", {}, $event_id);
        if ($event && $event->{author_id} eq session->{user}->{id}) {
		return create_edit_event($event_id);
	} else {
		flash error => "Event doesn't exist or you don't have permission to edit it.";
		return template('index', {});
	}
};
get '/event_edit_:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = database->selectrow_hashref("
	select
	date_format(date_of_event, '%e.%c.%Y') date_of_event,
	(select headline from e_kind_reg where e_kind_reg.id = kind_id) kind_headline,
	date_format(date_of_event, '%k:%i') time_of_event,
	id, headline, description, author_id 
	from events 
	where id = ?
	", {}, $event_id);
        if ($event && $event->{author_id} eq session->{user}->{id}) {
		my $sth = database->prepare("select * from e_kind_reg");
		$sth->execute();
		my $kinds = $sth->fetchall_hashref('id');
		my $sth_info = database->prepare("select 
			author_id, headline, description, capacity,
			invitation, kind_id, date_format(date_of_event, '%e.%c.%Y@%k:%i') date_of_event
			from events
			where id = ?");
		$sth_info->execute($event_id);
		my $event;
		$event = $sth_info->fetchrow_hashref();
		if (!$event || $user->{id} ne $event->{author_id}) {
			flash error => "Event doesn't exist or you don't hav permission to edit it.";
			return template("index");
		}
		for my $key (keys %$event) {
			if ($key eq 'date_of_event') {
				my ($date, $time) = split('@', $event->{$key});
				params->{date_of_event} = $date;
				params->{time_of_event} = $time;
			} else {
				params->{$key} = $event->{$key};
			}
		}
		return template("event_create", {kinds => $kinds});
	} else {
		flash error => "Event doesn't exist or you don't have permission to edit it.";
		return template('index', {});
	}
};
post '/event/invite/:event_id/send/' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_author => 1,
			author_id => $user->{id},
			is_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		# invitation_text to insert to db is in param invitation_USER_ID
		my @params = grep {$_ =~ /^invitation_\d+$/} params;
		my $sth = database->prepare('
		select id, first_name, last_name,
		(select max(id) from u_photo where user_id = users.id) photo_id
		from users
		where id = ?
		-- TODO conditions when I can invite him/her
		and not exists (select 1 from e_invitation where users.id = e_invitation.user_id and e_invitation.event_id = ?) 
		-- invitation doesnt exist
		');
		my $sth_insert = database->prepare("
		insert into e_invitation
		(event_id, user_id, invitation, invitation_text)
		values (?, ?, '1', ?)
		");
		for my $i_u (@params) {
			my (undef, $user_id) = split('_', $i_u);
			$sth->execute($user_id, $event_id);
			my ($u_id, $first_name, $last_name);
			($u_id, $first_name, $last_name) = $sth->fetchrow_array();
			if ($u_id) {
				params->{$i_u} =~ s/^\s+//; # remove white spaces
				params->{$i_u} =~ s/\s+$//;
				if (params->{$i_u}) {
					$sth_insert->execute($event_id, $u_id, params->{$i_u});
					flash('ok', flash('ok')."User $first_name $last_name was invited."."<br>");
				} else {
					flash('error', "Invitation for one or more users is empty, please write them, why should they come.");
					return forward('/event/invite/'.$event_id, {invite_user => });
				}
			} else {
				flash error => "One or more checked users have been already invited or they don't exist at all.";
			}
		}
		return forward('/event/show/'.$event_id, undef, {method => 'GET'});
	}
};
post '/event_invite_:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_author => 1,
			author_id => $user->{id},
			is_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my @invite_users;
		if (!params->{invite_user}) {
			flash('error',"You didn't choose any users to invite.");
			return forward('/event/invite/'.$event_id, undef, {method => 'GET'});
		} else {
			if (params->{invite_user} =~ /^ARRAY/) {
# TODO this is weird, INTERNET find how to do it better
				push @invite_users, @{params->{invite_user}};
			} else {
				push @invite_users, params->{invite_user};
			}
		}
		my $sth_u = database->prepare("
		select first_name, last_name, id,
		(select max(id) from u_photo where user_id = users.id) photo_id
		from users
		where id in (".Meet::Helpers::place_holders(@invite_users).")
		");
		$sth_u->execute(@invite_users);
		my $users = $sth_u->fetchall_hashref('id');
		return template('event_invite', {users => $users, event => $event, textarea => '1'});
	}
};
get '/event_invite_:event_id' => sub {
# TODO how to select the partners? how to write the invitation? AJAX (add next)?
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = Meet::Helpers::get_event_info($event_id, {
			is_author => 1,
			author_id => $user->{id},
			is_invitation => 1,
		 });
	if ($event->{_ERROR}) {
		flash('error', $event->{_ERROR});
		return redirect($event->{_GOTO});
	} else {
		my $sth = database->prepare("
			select first_name, 
			last_name, id, birth_date, 
			(select max(id) from u_photo where user_id = users.id) photo_id
			from users
			where not exists (select 1 from e_invitation e_i where users.id = e_i.user_id and e_i.event_id = ?) 
			-- invitation doesnt exist yet
			");
		$sth->execute($event_id);
		my $users = $sth->fetchall_hashref('id');
		$sth = database->prepare("
			select first_name, 
			last_name, id, birth_date, 
			(select max(id) from u_photo where user_id = users.id) photo_id
			from users
			where exists (select 1 from e_invitation e_i where users.id = e_i.user_id and e_i.event_id = ?) 
			-- invitation exists already
			");
		$sth->execute($event_id);
		my $invited_users = $sth->fetchall_hashref('id');
		return template('event_invite', {event => $event, users => $users, invited_users => $invited_users});
	}
};
any ['get', 'post'] => '/event_delete_:event_id' => sub {
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = database->selectrow_hashref("
	select
	date_format(date_of_event, '%e.%c.%Y') date_of_event,
	date_format(date_of_event, '%k:%i') time_of_event,
	(select headline from e_kind_reg where e_kind_reg.id = kind_id) kind_headline,
	id, headline, description, author_id 
	from events 
	where id = ?
	", {}, $event_id);
	if ($event && $event->{author_id} eq $user->{id}) {
		if (request->{method} eq 'GET') {
			return template('event_delete', {event => $event});
		} elsif (request->{method} eq 'POST') {
			my $sth_i = database->prepare('
				delete from e_invitation
				where event_id = ?
			');
			$sth_i->execute($event_id);
			my $sth_e = database->prepare("delete from events where id = ?");
			$sth_e->execute($event_id);
			
			flash ok => "Event was deleted.";
			return template('index', {});
		}
	} else {
		flash error => "Event doesn't exist or you don't have permission to edit it.";
		return template('index', {});
	}
};
get '/event/show/invited' => sub {
	my $user = session('user');
	my $sth = database->prepare("
	select id, headline, description, 
	date_format(date_of_event, '%e.%c.%Y %k:%i') date_of_event,
	events.invitation, capacity, author_id, e_invitation.invitation, invitation_text,
	e_invitation.answer, e_invitation.answer_text
	from events, e_invitation
	where event_id = events.id
	and user_id = ?
	and events.invitation = 1 

	-- and date_of_event >= NOW() -- and it is in future TODO posibility to set time from to
	order by date_of_event
	");
	$sth->execute($user->{id});
	my $events;
	$events = $sth->fetchall_arrayref();
	return template('event_show_invited', {events => $events});
};
get '/event/show/my' => sub {
	my $user = session('user');
	my $sth = database->prepare("
	select id, headline, description, 
	date_format(date_of_event, '%e.%c.%Y %k:%i') date_of_event,
	invitation, capacity, author_id
	from events
	where author_id = ? 
	-- and date_of_event >= NOW() -- and it is in future TODO posibility to set time from to
	order by date_of_event
	");
	$sth->execute($user->{id});
	my $events;
	$events = $sth->fetchall_arrayref();
	return template('event_show_all', {events => $events});
};
get '/events/month/:month' => sub {
	my $user = session('user');
	my $month = params->{month};
	if ($month !~ /^\d+-\d{4}$/) {
		flash('error', "Couldn't recognize the month.");
		return redirect('/');
	}
	my $events;
	$events = Meet::Helpers::get_events({month => $month});
	if ($events->{_ERROR}) {
		flash('error', $events->{_ERROR});
		return redirect("/");
	} else {
		return template("events_month", {cal => $events});
	}
};

get '/events/:date' => sub {
	my $user = session('user');
	my $date = params->{date};
	if ($date !~ /^\d+-\d+-\d{4}$/) {
		flash('error', "Date is not in right format.");
		return redirect('/');
	}
	my $sth = database->prepare("
	select id, headline, description, 
	date_format(date_of_event, '%e.%c.%Y %k:%i') date_of_event,
	invitation, capacity, author_id
	from events
	where (invitation = 0  -- open for everybody
		or ( -- or user is invited
			invitation = 1 
			and exists (
				select 1 from e_invitation 
				where event_id = events.id
				and user_id = ?
			)
		) 
		or author_id = ? -- or user is author
	)
	and date_format(date_of_event, '%e-%c-%Y') = ?
	order by date_of_event
	");
	$sth->execute($user->{id}, $user->{id}, $date);
	my $events;
	$events = $sth->fetchall_arrayref();
	return template('event_show_all', {events => $events});
};
get '/event_show_calendar' => sub {
	my $user = session('user');
	
	var specific_scripts => q`
	<script type="text/javascript" src='plugins/moment/moment.min.js'></script>
	<script type="text/javascript" src='plugins/jquery-ui/jquery-ui.custom.min.js'></script>
	<script type="text/javascript" src='plugins/fullcalendar/fullcalendar.min.js'></script>
	<script type="text/javascript">
	$(window).load(function() 
	{
	"use strict";

	function renderCalendar(){

	if (!jQuery().fullCalendar) {
	return;
	}

	var date = new Date();
	var d = date.getDate();
	var m = date.getMonth();
	var y = date.getFullYear();


	var h = {
	left: 'prev,next today',
	center: 'title',
	right: 'today'
	};

	$('#fullcalendar').html("");
	$('#fullcalendar').fullCalendar({
	header: h,
	editable: true,
	eventLimit: true, 

	eventSources: 
	[
		{
			url: '/helpers_calendar',
			color: 'red'
		}
	]

	});

	}

	renderCalendar();

	});
	</script>

	`;
	return template('event_show_calendar', {});
};
get '/helpers_calendar' => sub {
	my $user = session('user');
	my $start = params->{start};
	my $end = params->{end};
	if ($start !~ /^\d{4}-\d{2}-\d{2}$/ || $end !~ /^\d{4}-\d{2}-\d{2}$/) {
		return qq|
		[
		{
		"allDay": true,
		"title": "There was an error during loading the events",
		"id": "664",
		"end": "2020-01-01 14:00:00",
		"start": "2015-01-02 06:00:00",
		"color": "red"
		},
		{
		"allDay": true,
		"title": "There was an error during loading the events",
		"id": "666",
		"end": "2020-01-01 14:00:00",
		"start": "2015-01-02 06:00:00",
		"color": "red"
		}
		]
		|;
	} else {
		my $sth = database->prepare("
			select id, 
			headline, 
			date_format(date_of_event, '%Y') year,
			date_format(date_of_event, '%c') month,
			date_format(date_of_event, '%e') day,
			date_format(date_of_event, '%k') hour,
			date_format(date_of_event, '%i') minute
			from events
			where (invitation = 0  -- open for everybody
				or ( -- or user is invited
			invitation = 1 
				and exists (
			select 1 from e_invitation 
			where event_id = events.id
				and user_id = ?
			)
			) 
				or author_id = ? -- or user is author
			)
			and date_of_event >= str_to_date(?, '%Y-%m-%d') -- from
			and date_of_event <= str_to_date(?, '%Y-%m-%d') -- to
			order by date_of_event
			");
		$sth->execute($user->{id}, $user->{id}, $start, $end);
		my $events;
		$events = $sth->fetchall_hashref('id');
		my $string_events = "";
		for my $event_id (keys $events) {
			if ($string_events) {
				$string_events .= ",";
			}
			
			$string_events .= qq|
			{
			"title": "$events->{$event_id}->{headline}",
			"start": "$events->{$event_id}->{year}-$events->{$event_id}->{month}-$events->{$event_id}->{day} $events->{$event_id}->{hour}:$events->{$event_id}->{minute}:00",
			"end": "$events->{$event_id}->{year}-$events->{$event_id}->{month}-$events->{$event_id}->{day} 23:59:59",
			"url": "./event_show_$event_id",
			"allDay": false,
			"id": "$event_id"
			}|;
		}
		if ($string_events) {
			return qq|[$string_events]|;
		} else {
			return q|[]|;
		}
	}

};
get '/event_show_all' => sub {
	my $user = session('user');
	my $sth = database->prepare("
	select id, headline, description, 
	date_format(date_of_event, '%e.%c.%Y %k:%i') date_of_event,
	invitation, capacity, author_id
	from events
	where (invitation = 0  -- open for everybody
		or ( -- or user is invited
			invitation = 1 
			and exists (
				select 1 from e_invitation 
				where event_id = events.id
				and user_id = ?
			)
		) 
		or author_id = ? -- or user is author
	)
	-- and date_of_event >= NOW() -- and it is in future TODO posibility to set time from to
	order by date_of_event
	");
	$sth->execute($user->{id}, $user->{id});
	my $events;
	$events = $sth->fetchall_arrayref();
	return template('event_show_all', {events => $events});
};
get '/event_show_:event_id' => sub {
# TODO show invitation_text on a click
	my $user = session('user');
	my $event_id = params->{event_id};
	my $event = database->selectrow_hashref("
		select id, headline, description, invitation, 
		capacity, 
		(select CONCAT(invitation_text, '&nbsp;')
			from e_invitation
			where event_id = events.id
			and user_id = ?
			and (invitation is null or invitation = 1) -- null when user offer himself (maybe not need that TODO)
			-- and (answer is null or answer = 1) -- event with rejected invitation won't be displayed
		) invitation_text,
		author_id,
		date_format(date_of_event, '%e.%c.%Y') date_of_event,
		date_format(date_of_event, '%k:%i') time_of_event,
		(select headline from e_kind_reg where e_kind_reg.id = kind_id) kind_headline
		from events 
		where id = ?
		", {}, $user->{id}, $event_id);
	if ($event) {
		my $is_author = 0;
		if ($user->{id} eq $event->{author_id}) {
			# user is an author so I really don't care if the event is invitation-only
			$is_author = 1;
		} elsif ($event->{invitation}) {
			#check that user is invited
			my $is_invited;
			my $invitation_text = '';
			if ($event->{invitation_text}) {
				# user is invited
			} else {
				flash('error', "Event doesn't exist or you are not invited.");
				return template("index");
			}
		}
		# want to display users who are coming, are invited or are applying to attend...
		if ("A setting of the event?") {
			my $users;
			$users = database->selectall_hashref("
			select user_id id, first_name, last_name, about, event_id,
			(select max(id) from u_photo where u_photo.user_id = e_invitation.user_id) photo_id,
			invitation, invitation_text, 
			answer, answer_text
			from e_invitation, users
			where event_id = ?
			and user_id = users.id
			", 'id', {}, $event_id);
			for my $u_id (keys $users) {
				if (defined $users->{$u_id}->{invitation}) {
					if ($users->{$u_id}->{invitation} eq '1') {
						if (defined $users->{$u_id}->{answer}) {
							if ($users->{$u_id}->{answer} eq '1') {
# accepted invitation, approved application
								$event->{coming}->{$users->{$u_id}->{last_name}.$users->{$u_id}->{first_name}} = $users->{$u_id};
							} elsif ($users->{$u_id}->{answer} eq '0') {
# invited but not coming
								$event->{notcoming}->{$users->{$u_id}->{last_name}.$users->{$u_id}->{first_name}} = $users->{$u_id};
							}
						} else {
# invited
							$event->{invited}->{$users->{$u_id}->{last_name}.$users->{$u_id}->{first_name}} = $users->{$u_id};
						}
					} elsif ($users->{$u_id}->{invitation} eq '0') {
# host doesn't want that user there...
						$event->{rejected}->{$users->{$u_id}->{last_name}.$users->{$u_id}->{first_name}} = $users->{$u_id};
					}
				} else {
# invitation is null, so somebody is applying
					if (defined $users->{$u_id}->{answer}) {
						if ($users->{$u_id}->{answer} eq '1') {
							$event->{applying}->{$users->{$u_id}->{last_name}.$users->{$u_id}->{first_name}} = $users->{$u_id};
						}
					} else {
# nonsence, this should never happen... ??? :-)
					}
				}
			}
#print Dumper($event);
		}
		return template("event_show", {is_author => $is_author, event => $event});
	} else {
		flash('error', "Event doesn't exist or you are not invited.");
		return template("index");
	}
};
sub create_edit_event {
	my ($event_id) = @_;
	my $user = session('user');
	# 
	if (!params->{description} || !params->{headline} || !params->{kind_id} || !params->{date_of_event} ) {
		# something is missing
			flash error => "You didn't fill in all information.";
			return forward('/event_create', {params}, { method => 'GET'});
	} else {
		my $err;
		# everything is filled in, check it
		if (length(params->{headline}) < 3 || params->{headline} !~ /[a-z]/) { #name of event doesnt have any small letters and longer than 3 letters
			$err = 1;
			flash error => "The name of the event is too short or contains only big letters.";
		}
		#if (params->{capacity} <= 0) { 
			# capacity must not be less 1 #and must not be too big
			#$err = 1;
			#flash error => "Capacity is set to zero or less.";
		#}
		if (params->{invitation} !~ /^[01]$/) {
			# invitation is 0 (everyone can come) or 1 (invited only)
			params->{invitation} = 1;
		}
		my $date;
		if (params->{date_of_event}) {
			# should be in format DD.MM.YYYY (TODO template, calendar)
			($date->{day}, $date->{month}, $date->{year}) =  split(/\./, params->{date_of_event});
			if (!Meet::Helpers::is_date($date)) {
				#error
				$err = 1;
				flash error => "Date of event is in incorect format, please use calendar or set it manually (DD.MM.YYYY)";
			} else {
				my $sth = database->prepare("select 1 
				from dual 
				where 
				str_to_date( ?, '%d.%m.%Y') > NOW()
				");
				$sth->execute($date->{day}.".".$date->{month}.".".$date->{year});
				my $is_in_future;
				($is_in_future) = $sth->fetchrow_array();
				if (!$is_in_future) {
					$err = 1;
					flash error => "Date of event must be at least one day in future.";
				}

			}
		}
		if (params->{time_of_event}) {
			($date->{hh}, $date->{mi}) = split (':', params->{time_of_event});
			if ($date->{hh} !~ /^\d+$/ #not a number
				|| $date->{hh} >= 24  # over 23 is non-sence
				|| $date->{hh} < 0 # negative value
				|| $date->{mi} !~ /^\d+$/ # not a number
				|| $date->{mi} >= 60 # over 59 is non-sence
				|| $date->{mi} < 0 # negative value
				) {
				$err = 1;
				flash error => "Time of event is not valid.";
			}
		} else {
			($date->{hh}, $date->{mi}) = ("18","00");
		}

		if ($err) {
			return forward(request->path_info, undef, { method => 'GET'});
		} else {
			if ($event_id) {
# TODO check if there is any change !!
				my $sth = database->prepare("update events
					set headline = ?, description = ?, capacity = ?, invitation = ?,
					kind_id = ?, date_of_event = ?, timestamp = NOW()
					where id = ?");
				$sth->execute(
					params->{headline}, 
					params->{description}, 
					"1", # capacity
					params->{invitation}, 
					params->{kind_id},
					$date->{year}."-".$date->{month}."-".$date->{day}." ".$date->{hh}.":".$date->{mi},
					$event_id
				);
				flash ok => "Changes were saved.";
				return redirect('/event_show_'.$event_id);
			} else {
				my $sth = database->prepare("insert into events
				(author_id, headline, description, capacity, invitation, kind_id, date_of_event, timestamp)
				values (?, ?, ?, ?, ?, ?, ?, NOW())");
				$sth->execute($user->{id}, 
					params->{headline}, 
					params->{description}, 
					"1", #capacity
					params->{invitation}, 
					params->{kind_id},
					$date->{year}."-".$date->{month}."-".$date->{day}." ".$date->{hh}.":".$date->{mi});
				my $sth_id = database->prepare("select max(id) from events");
				$sth_id->execute();
				my $new_e_id;
				($new_e_id) = $sth_id->fetchrow_array();

				flash ok => "Event was created.";
				return redirect('/event_show_'.$new_e_id);
			}
		}
	}
} # end sub create_edit_event	

true;
