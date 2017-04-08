package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';
our $sender = 'no-reply@localhost';

hook 'before' => sub {
#       if (! session('user') && request->path_info !~ m{^/(login|fb_login|registration|confirmation|$)}) {
#	   var requested_path => request->path_info;
#	   request->path_info('/login');
#       }
};
get '/signout' => sub {
	if (session('user')) {
		params->{flash_ok} = flash('ok');
		params->{flash_error} = flash('error');
		return forward("/login", {signout => "1"}, {method => 'POST'});
		#return template("signout", {});
	} else {
		flash error => "You are not logged in.";
		return template("login", {});
	}
};

get '/login' => sub {
# Display a login page; the original URL they requested is available as
# vars->{requested_path}, so could be put in a hidden field in the form
	my $err;
	if (session('user')) {
		flash error => "You are already logged in. Do you want to sign out and log in as another user?";
		return template "signout", { path => vars->{requested_path} };
	} else {
		if (params->{failed}) {
			flash error => "Login failed - password or user is uncorrect.";
		}
	}
	return template("login", { });
};

post '/login' => sub {
	if (params->{signout}) {
		session->destroy;
		flash ok => "You were logged out.";
		return template("index");
	} else {
		my $sth = database->prepare("select 
				id, first_name, 
				last_name, email, 
				date_format(birth_date, '%d. %m. %Y') birth_date, 
				date_format(confirmed, '%d. %m. %Y') confirmed, 
				password, confirm_code, about, gender
				from users
				where email = ?");
		$sth->execute(params->{user});
		my $user = $sth->fetchrow_hashref();
		if (!$user) {
			warning "Failed login for unrecognised user";
			flash error => "Login failed - password or user is uncorrect.";
			return template("login");
		} else {
			my $password_salt = "matessSoliJakoOZivot";
			use Digest::SHA;
			my $salted_password = Digest::SHA::sha1_hex($password_salt.Digest::SHA::sha1_hex(params->{pass}.$password_salt));
			if ($user->{password} eq $salted_password) {
				debug "Password correct";
# Logged in successfully
				if ($user->{confirmed}) {
					delete $user->{password};
					delete $user->{confirm_code};
					#delete $user->{email};
					session user => $user;
					#return redirect params->{path} || '/'; #TODO redirect back to rquested page
					flash ok => "Loggin successful.";
					return template("index");
				} else {
					debug "User '".params->{user}."' is not confirmed.";
					return template("login");
				}
			} else {
				debug("Login failed - password incorrect for " . params->{user});
#redirect '/login?failed=1';
				flash error => "Login failed - password or user is uncorrect.";
				return template("login");
			}
		}
	}
};

post "/user/change_password" => sub {
	my $user = session("user");
	my $msg;
	my $salted_password;
	if (!params->{password} || !params->{password_confirm} || (params->{password} ne params->{password_confirm}) ) {
		flash('error', "Passwords are not identical.");
		#} elsif (!Meet::Helpers::strong_password(params->{password})) {
		#flash('error', "Passwords is not strong enough.");
	} else {
		use Digest::SHA;
		my $password_salt = "matessSoliJakoOZivot";
		$salted_password = Digest::SHA::sha1_hex($password_salt.Digest::SHA::sha1_hex(params->{password}.$password_salt));
		my $sth = database->prepare("update users set password = ?, date = NOW() where id = ?");
		$sth->execute($salted_password, $user->{id});
		flash('ok', "Password was succesfully changed.");
		return template("index");
	}
	return template("change_password");

};
get "/user/change_password" => sub {
	return template("change_password");
};

post "/user/profile/edit" => sub {
	database->{AutoCommit} = 0;
	my $user = session("user");

	my $ok = 1;
	my $about = params->{about};
	if (defined $about && $about ne $user->{about}) {
		if (length($about) >= 127) {
			flash('error', "'About' text is too long (limit is approx. 127 characters).");
			return redirect("/user/profile/edit");
		}
		my $sth = database->prepare("update users set about = ? where id = ?");
		$ok = $sth->execute(params->{about}, $user->{id});
	} 
	my $result = ($ok ? database->commit : database->rollback );
	if ($ok && $result) {
		flash('ok', "Saved.");
		if (defined params->{about}) {
			# refresh session info
			$user->{about} = params->{about};
			session user => $user;
		}
		return redirect("/user/profile");
	} else {
		debug(database->errstr);
		flash('error', 'There was a problem in saving your application to database, please try it again.');
		return forward(request->{path_info}, undef, {method => 'GET'});
	}
};
get "/user/profile/edit" => sub {
	display_profile("edit");
};

get '/user/picture/:user_id/:photo_id' => sub {
	my $user = session('user');
	my $photo_id = params->{photo_id};
	my $user_id = params->{user_id};
	my $photo = database->quick_select("u_photo", { user_id => $user_id, id => $photo_id });
	if ($photo->{id}) {
		header 'Content-Type' => 'image/jpeg';
		return $photo->{photo};
	} else {
		my $default_photo = database->quick_select("u_photo", { user_id => 1, id => 15 });
		header 'Content-Type' => 'image/jpeg';
		return $default_photo->{photo};
	}
};
post '/user/upload_photo' => sub {
	my $MAX_PHOTO_SIZE = 5000000;
	my $user = session('user');
	my $file = request->upload('photo');
	#use Data::Dumper;
	#print Dumper($file);
	if (!$file) {
		flash error => "No photo selected.";
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
		my $sth_delete = database->prepare("delete from u_photo where user_id = ?");
		my $sth = database->prepare("insert into u_photo (user_id, photo, profile_pic) values (?, ?, ?)");
		$sth_delete->execute($user->{id}); # delete all previous photos # TODO first try insert if ok, delete the rest
		$sth->execute($user->{id}, $photo, '1'); # insert new one
	
		flash ok => "Photo was uploaded.";
		
	}
	return redirect("/user/profile");
};
get '/user/upload_photo' => sub {
	my $user = session('user');
	return template("upload_photo");
};

get '/user/profile/:user_id' => sub {
		display_profile();
};
get '/user/profile' => sub {
		display_profile();
};
get '/user' => sub {
		display_profile();
};

sub display_profile {
	my $edit = shift;
	my $user = session('user');
	my $display_user_id = params->{user_id};
	if (!$display_user_id) {
		$display_user_id = $user->{id};
	}
	my $choosen_user = database->selectrow_hashref("
	select id, first_name, last_name, fb_id, created, 
	about, email
	from users
	where id = ?
	", {}, $display_user_id);
	if (!$choosen_user) {
		flash('error',"User doesn't exist.");
		return template("index");
	} else {
		if ($choosen_user->{hide_email}) {
			# TODO private setting, probably new table in db
			$choosen_user->{email} = "Contact is hidden.";
		}
		$user = $choosen_user;
	}
	if ($edit && $user->{id} ne session('user')->{id}) {
		flash('error',"You don't have permission for this action.");
                return template("index");
	}
	my $information_arrayref;
	my $sth = database->prepare("
		select reg.headline, reg.description, 
		IF (reg.options, 
			(select answer from u_information_answers where information_id = reg.id and id = inf.answer),
			inf.answer)
		  answer
		from u_information inf, u_information_reg reg
		where inf.user_id = ?
			and inf.information_id = reg.id
		order by reg.order_by
		");
	$sth->execute($display_user_id);
	$information_arrayref = $sth->fetchall_arrayref();
	# photo
	my $sth_photo = database->prepare("select max(id) 
		from u_photo
		where user_id = ?
		-- and profile_pic = 1");
	$sth_photo->execute($display_user_id);
	my $photo_id;
	($photo_id) = $sth_photo->fetchrow_array();

	my $page =  "profile";
	$page = "profile_edit" if ($edit);
	return template($page, {
			basic_info => $user,
			photo_id => $photo_id,
			information => $information_arrayref
			});
};

get '/registration' => sub {
	# if logged in - nothing, give him message 
	# if not logged 
		# - form with name, nickname... - get /registration
		# - send form - post /registration
		# - send him mail - later :-) TODO
		# - page for confirmation - get /confirmation?code=XSSWF
		# - confirm registration - post /confirmation?code=XSSWF
	if (session('user')) {
		flash error => 'You are already logged in. It\'s not neccessary to create another account for you.';
		return template("index", {});
	} else {
		return template("registration");
	}
};

post '/registration' => sub {
# check data
# insert new user into database
# send an e-mail (TODO)
# redirect to confirmation (temporary)
	my $error;
	my $salted_password;
#	if (not defined params->{gender} || !params->{gender}
#		|| (params->{gender} !~ /^[01]$/) ) {
#		if ($error) { $error .= " <br>\n"; }
#		$error .= "Please choose your gender.";	
#	} else {
#	}
	if (!params->{first_name}) {
		if ($error) { $error .= " <br>\n"; }
		$error .= "Please fill in your first name.";	
	} else {
		if (params->{first_name} !~ /^\w+$/ ) {
			if ($error) { $error .= " <br>\n"; }
			$error .= "Please don't use special symbols in your first name.";
		}
	}	
	if (!params->{last_name}) {
		if ($error) { $error .= " <br>\n"; }
		$error .= "Please fill in your last name.";	
	} else {
		if (params->{last_name} !~ /^\w+$/ ) {
			if ($error) { $error .= " <br>\n"; }
			$error .= "Please don't use special symbols in your last name.";
		}
	}
	if (!params->{email}) {
		if ($error) { $error .= " <br>\n"; }
		$error .= "Please fill in your e-mail address.";	
	} elsif (!Meet::Helpers::is_email(params->{email})) {
# check the format of e-mail address and the uniquness
		if ($error) { $error .= " <br>\n"; }
		$error .= "E-mail address is not valid.";	
	} else {
		my $user = database->quick_select('users',
				{ email => params->{email} }
				);
		if ($user) {
			if ($error) { $error .= " <br>\n"; }
			$error .= "E-mail address you filled in is already registred. Please use another.";	
		}

	}
	if (!params->{birth_date}) {
		if ($error) { $error .= " <br>\n"; }
		$error .= "Please fill in your date of birth.";	
	} else {
		my $is_valid;
		my $date;
		($date->{year}, $date->{month}, $date->{day}) = split("-", params->{birth_date});
		$is_valid = Meet::Helpers::is_date($date);
		if (!$is_valid) {
			if ($error) { $error .= " <br>\n"; }
			$error .= "Birth date is not valid.";	
		}
# check valid date
	}
	if (!params->{password} || !params->{password_confirm} || (params->{password} ne params->{password_confirm}) ) {
		if ($error) { $error .= " <br>\n"; }
		$error .= "Passwords are not identical.";
#	} elsif (!Meet::Helpers::strong_password(params->{password})) {
#		if ($error) { $error .= " <br>\n"; }
#		$error .= "Password is not strong enough.";
	} else {
		use Digest::SHA;
		my $password_salt = "matessSoliJakoOZivot";
		$salted_password = Digest::SHA::sha1_hex($password_salt.Digest::SHA::sha1_hex(params->{password}.$password_salt));
	}
	if (!$error) {
# all data are ok
		use Digest::SHA;
		my $confirmation_code = Digest::SHA::sha1_hex(rand());
		my $sth = database->prepare("insert into users (first_name, last_name, email, password, birth_date, confirmed, confirm_code, date, gender) values (?,?,?,?, ?, null, ?, NOW(), ? )");
		$sth->execute( 
				params->{first_name},
				params->{last_name},
				params->{email},
				$salted_password,
				params->{birth_date},
				$confirmation_code,
				params->{gender}
			     );
		my $text = "Dear ".params->{first_name}." ".params->{last_name}.",\n\n";
		$text .= "Before you can continue using your account, you need to verify that your e-mail address is valid by clicking the link below:\n";
		$text .= request->{env}->{HTTP_HOST}."/confirmation?confirm_code=$confirmation_code;email=".params->{email}."\n";

# TODO send the e-mail
		#send_mail($sender, params->{email}, "Please confirm your registration at ", $text, {});
		return redirect "/confirmation?confirm_code=$confirmation_code;email=".params->{email};
	} else {
		flash('error', $error);
		return template("registration", {} );
	}
};

get "/confirmation" => sub {
	# user was redirect to confirmation page (from registration form or from link in e-mail (TODO))
	# email should be filled in (get param) and confirmation code (get param) and we just check it against database record
	if (params->{email} && params->{confirm_code} ) {
		return template("confirmation", { email => params->{email}, confirm_code => params->{confirm_code}} );
	} else {
		flash error => "URL is in wrong format.";
		return template("index");
	}
	

};

post "/confirmation" => sub {
	my $user = database->quick_select('users',
			{ email => params->{email}, confirm_code => params->{confirm_code} }
		);
	if (!$user) {
		flash error => "Your confirmation code doesn't match! Please check that the URL in e-mail is the same as in your brwoser, or contact administrator.";
		debug("Couldn't find any user with the e-mail".params->{email}." and confirm_code:".params->{confirm_code});
 
		return template("confirmation", { email => params->{email}, confirm_code => params->{confirm_code}
		});
	}
	if ($user->{confirmed}) {
		# log that
		debug("User ".params->{email}." is trying to confirm his account again. Just to know.");
		flash ok => "Your account was already succesfully confirmed.";
	} else {
			# set confirmed to current date and delete confirmation code so it can be used again
			my $sth = database->prepare("update users set confirmed = NOW() where email = ? and confirm_code = ?");
			$sth->execute(params->{email}, params->{confirm_code});
			debug("User ".params->{email}." confirmed his email.");
			flash ok => "Your account was succesfully created, please log in.";
	}	
	return template("index", {});
};

true;
