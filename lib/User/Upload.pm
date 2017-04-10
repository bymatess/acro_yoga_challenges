package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Template;

use Data::Dumper;
our $VERSION = '0.1';


use Web::oEmbed;

# at server start
my $consumer = Web::oEmbed->new({ format => 'json' });
$consumer->register_provider({
		url  => 'https://*.youtube.com/*',
		api  => 'http://www.youtube.com/oembed',
		});
$consumer->register_provider({
		url  => 'http://*.youtube.com/*',
		api  => 'http://www.youtube.com/oembed',
		});
get '/video_test' => sub {
	my $link = "https://www.youtube.com/watch?v=3ETxM33dV9o";
	my $embeded = Meet::App->get_embeded_content($link);
	
	flash('error', "Couldn't embed the provided link '$link'.") unless $embeded;
	return template('test', { embeded => $embeded});
};

sub get_embeded_content {
	my $class = shift;
	my $link = shift;
;
	return undef if $link !~ /^https?:\/\//;

	my $embeded;
	my $response = eval { $consumer->embed($link) };
	if ($response) {
		$embeded = $response->render;  # handy shortcut to generate <img/> tag
	} else {
		# todo default fallback video
		print STDERR "not working\n";
	}
	
	return $embeded;
}

1;
