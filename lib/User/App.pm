package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';

get '/' => sub {
	my $events;
	#print Dumper($events);
	return template('index', {cal => $events});
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

true;
