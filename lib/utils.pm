package utils;

use strict;
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

1;
