package utils;

use strict;
use Socket; # for name resolves
use Net::LibIDN ':all';
use vars qw/$VERSION/;

$VERSION = "1.0";

sub ip ($) {
	my $env = shift;
	my $msg = '';

	if (defined($env->{X_REAL_IP})) {
		$msg = $env->{X_REAL_IP};
	} elsif (defined($env->{X_FORWARDED_FOR})) {
		$msg = (split(/\,/, $env->{X_FORWARDED_FOR}, 2))[0];
	} else {
		$msg = $env->{REMOTE_ADDR};
	}

	$msg .= "\n";
	return ('200', 'text/plain', $msg);
}

sub getaddrbyname ($) {
	my $name = shift;
	return ('400', 'text/plain', "Supply hostname\n") unless (defined($name));
	my @addresses = gethostbyname($name);

	if (@addresses > 0) {
		@addresses = map { inet_ntoa($_) } @addresses[4 .. $#addresses];

		if (@addresses > 1) {
			return ('200', 'text/plain', join("\n", @addresses) . "\n");
		} else {
			return ('200', 'text/plin', "$addresses[0]\n");
		}
	} else {
		return ('404', 'text/plain', "Not found\n");
	}
}

sub getnamebyaddr ($) {
	my $addr = shift;
	chomp($addr);
	return ('400', 'text/plain', "Supply address\n") unless (defined($addr));
	my $name = gethostbyaddr(inet_aton($addr), AF_INET);

	if (defined($name)) {
		return ('200', 'text/plain', "$name\n");
	} else {
		return ('404', 'text/plain', "Not found\n");
	}
}

sub punycoder ($) {
	my $str = shift;
	$str = Net::LibIDN::idn_to_ascii($str, 'utf-8');
	if (defined($str)) {
		return ('200', 'text/plain', "$str\n");
	} else {
		return ('400', 'text/plain', "Bad string\n")
	}
}

sub punydecoder ($) {
	my $str = shift;
	$str = Net::LibIDN::idn_to_unicode($str, 'utf-8');
	if (defined($str)) {
		return ('200', 'text/plain', "$str\n");
	} else {
		return ('400', 'text/plain', "Bad string\n")
	}
}

sub mytime () {
	return ('200', 'text/plain', time() . "\n");
}

1;
