package Meet::App;
use strict;
use warnings;
use Dancer ':syntax';
use Dancer::Plugin::FlashMessage;
use Dancer::Plugin::Database;
use Dancer::Plugin::Ajax;
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

ajax '/video/preview' => sub {
	header 'Content-Type' => 'application/json';
	
	my $link = params->{vlink}; # sent via jquery
print STDERR $link."\n\n";
#	$link = "https://www.youtube.com/watch?v=0ZgjmE6xdaw&list=PLenpQ_zBUIjMxAKDqMMpR5mt7QOlx-QEY&index=14";
	my $embeded = Meet::App->get_embeded_content($link);
	
        return to_json { type => "error", text => "Couldn't embed the provided link '$link'."} unless $embeded;
        return to_json { type => "ok", text => "Found the video link.", embeded => $embeded};
	
};

sub get_embeded_content {
	my $class = shift;
	my $link = shift;
;
	return undef if $link !~ /^https?:\/\//;

	my $embeded;
	my $response = eval { $consumer->embed($link, {format => 'xml'}) };
print STDERR Dumper($response);
	if ($response) {
		$embeded = $response->render;  # handy shortcut to generate <img/> tag
	} else {
		# todo default fallback video
		print STDERR "not working\n";
	}
	
	return $embeded;
}

1;
