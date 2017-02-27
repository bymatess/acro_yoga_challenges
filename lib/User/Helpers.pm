package Meet::Helpers;
use Dancer ':syntax';
use Dancer::Plugin::Database;

our $VERSION = '0.1';

sub strong_password {
# my $is_strong_enough = strong_password($password, $params_hashref);
# return true or false
# I don't really care about that, but user shouldn't use stupidly easy password...
	my ($password) = @_;
	if (	length($password) < 8 ||
		$password !~ /[0-9]/ ||
		$password !~ /[a-zA-Z]/	
	#	$password eq $params_hashref->{email} ||
	#	$password eq $params_hashref->{first_name} ||
	#	$password eq $params_hashref->{last_name} ||
	#	$password eq $params_hashref->{last_name}.$params_hashref->{first_name} ||
	#	$password eq $params_hashref->{first_name}.$params_hashref->{last_name} 
	) {
		return 0;
	} else {
		return 1;
	}

}

=head1 place_holders
my $question_marks_string = place_holders(@array)
prints as many '?' as scalar @array
use for SQL statements IN
=cut
sub place_holders {
	my @array = @_;
	if (scalar @array) {
		my $question_marks = "?," x scalar @array;
		$question_marks =~ s/,$//;
		return $question_marks;
	} else {
		return '';
	}
};
sub is_date {
	my ($params) = @_;
	#use Data::Dumper;
	#print Dumper($params);
	if ($params->{day} !~ /^\d+$/ || $params->{month} !~ /^\d+$/ || $params->{year} !~ /^\d+$/ || $params->{month} > 12) {
		return 0;
	}
	if ($params->{day} > 28 && $params->{day} > month_length($params->{month}, $params->{year})) {
		return 0;
	} else {
		return 1;
	}
};
sub month_length {
	my ($month, $year) = @_;
	my @MonthLengths = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
	my @LeapYearMonthLengths = @MonthLengths;
        $LeapYearMonthLengths[1]++;

	if (is_leap_year($year)) {
		return $LeapYearMonthLengths[$month-1];	
	} else {
		return $MonthLengths[$month-1];	
	}
};
sub is_leap_year {
	my ($year) = @_;

# According to Bjorn Tackmann, this line prevents an infinite loop
# when running the tests under Qemu. I cannot reproduce this on
# Ubuntu or with Strawberry Perl on Win2K.
#return 0 if $year == INFINITY() || $year == NEG_INFINITY();
	return 0 if $year % 4;
	return 1 if $year % 100;
	return 0 if $year % 400;

	return 1;
};

##################### checking of an e-mail ##########################
sub is_email {
	my ($email) = @_;
#
# Program to build a regex to match an internet email address,
# from Chapter 7 of _Mastering Regular Expressions_ (Friedl / O'Reilly)
# (http://www.oreilly.com/catalog/regex/)
#
# Optimized version.
#
# Copyright 1997 O'Reilly & Associates, Inc.
#



# Some things for avoiding backslashitis later on.
	my $esc = '\\\\'; my $Period = '\.';
	my $space = '\040'; my $tab = '\t';
	my $OpenBR = '\['; my $CloseBR = '\]';
	my $OpenParen = '\('; my $CloseParen = '\)';
	my $NonASCII = '\x80-\xff'; my $ctrl = '\000-\037';
	my $CRlist = '\n\015'; # note: this should really be only \015.

# Items 19, 20, 21
	my $qtext = qq/[^$esc$NonASCII$CRlist\"]/; # for within "..."
	my $dtext = qq/[^$esc$NonASCII$CRlist$OpenBR$CloseBR]/; # for within [...]
	my $quoted_pair = qq< $esc [^$NonASCII] >; # an escaped character

##############################################################################
# Items 22 and 23, comment.
# Impossible to do properly with a regex, I make do by allowing at most one level of nesting.
	my $ctext = qq< [^$esc$NonASCII$CRlist()] >;

# $Cnested matches one non-nested comment.
# It is unrolled, with normal of $ctext, special of $quoted_pair.
	my $Cnested = qq<
	$OpenParen # (
	$ctext* # normal*
	(?: $quoted_pair $ctext* )* # (special normal*)*
	$CloseParen # )
	>;

# $comment allows one level of nested parentheses
# It is unrolled, with normal of $ctext, special of ($quoted_pair|$Cnested)
	my $comment = qq<
	$OpenParen # (
	$ctext* # normal*
	(?: # (
	       (?: $quoted_pair | $Cnested ) # special
	       $ctext* # normal*
	      )* # )*
	$CloseParen # )
	>;

##############################################################################

# $X is optional whitespace/comments.
	my $X = qq<
	[$space$tab]* # Nab whitespace.
	(?: $comment [$space$tab]* )* # If comment found, allow more spaces.
	>;



# Item 10: atom
	my $atom_char = qq/[^($space)<>\@,;:\".$esc$OpenBR$CloseBR$ctrl$NonASCII]/;
	my $atom = qq<
	$atom_char+ # some number of atom characters...
	(?!$atom_char) # ..not followed by something that could be part of an atom
	>;

# Item 11: doublequoted string, unrolled.
	my $quoted_str = qq<
	\" # "
	$qtext * # normal
	(?: $quoted_pair $qtext * )* # ( special normal* )*
	\" # "
	>;

# Item 7: word is an atom or quoted string
	my $word = qq<
	(?:
	 $atom # Atom
	 | # or
	 $quoted_str # Quoted string
	 )
	>;

# Item 12: domain-ref is just an atom
	my $domain_ref = $atom;

# Item 13: domain-literal is like a quoted string, but [...] instead of "..."
	my $domain_lit = qq<
	$OpenBR # [
	(?: $dtext | $quoted_pair )* # stuff
	$CloseBR # ]
	>;

# Item 9: sub-domain is a domain-ref or domain-literal
	my $sub_domain = qq<
	(?:
	 $domain_ref
	 |
	 $domain_lit
	 )
	$X # optional trailing comments
	>;

# Item 6: domain is a list of subdomains separated by dots.
	my $domain = qq<
	$sub_domain
	(?:
	 $Period $X $sub_domain
	 )*
	>;

# Item 8: a route. A bunch of "@ $domain" separated by commas, followed by a colon.
	my $route = qq<
	\@ $X $domain
	(?: , $X \@ $X $domain )* # additional domains
	:
	$X # optional trailing comments
	>;

# Item 6: local-part is a bunch of $word separated by periods
	my $local_part = qq<
	$word $X
	(?:
	 $Period $X $word $X # additional words
	 )*
	>;

# Item 2: addr-spec is local@domain
	my $addr_spec = qq<
	$local_part \@ $X $domain
	>;

# Item 4: route-addr is <route? addr-spec>
	my $route_addr = qq[
	< $X # <
	(?: $route )? # optional route
	$addr_spec # address spec
	>                    #                 >
	];


# Item 3: phrase........
	my $phrase_ctrl = '\000-\010\012-\037'; # like ctrl, but without tab

# Like atom-char, but without listing space, and uses phrase_ctrl.
# Since the class is negated, this matches the same as atom-char plus space and tab
	my $phrase_char =
	qq/[^()<>\@,;:\".$esc$OpenBR$CloseBR$NonASCII$phrase_ctrl]/;

# We've worked it so that $word, $comment, and $quoted_str to not consume trailing $X
# because we take care of it manually.
	my $phrase = qq<
	$word # leading word
	$phrase_char * # "normal" atoms and/or spaces
	(?:
	 (?: $comment | $quoted_str ) # "special" comment or quoted string
	 $phrase_char * # more "normal"
	 )*
	>;

## Item #1: mailbox is an addr_spec or a phrase/route_addr
	my $mailbox = qq<
	$X # optional leading comment
	(?:
	 $addr_spec # address
	 | # or
	 $phrase $route_addr # name and address
	 )
	>;

	my $valid = $email =~ m/^$mailbox$/xo;
	if ($valid) {
		return 1;
	} else {
		return 0;
	}

} # end is_email


true;
