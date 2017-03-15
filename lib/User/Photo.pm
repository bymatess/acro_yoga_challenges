package User::Photo;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';
our $sender = 'no-reply@localhost';


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

post '/user_upload_photo' => sub {
        my $MAX_PHOTO_SIZE = 5000000;
        my $user = session('user');
        my $file = request->upload('photo');
        #use Data::Dumper;
        #print Dumper($file);
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
        return redirect("/user_profile");
};
get '/user_upload_photo' => sub {
        my $user = session('user');
        return template("upload_photo");
};


