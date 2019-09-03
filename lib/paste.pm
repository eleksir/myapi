package paste;

use strict;
use vars qw/$VERSION/;

$VERSION = "1.0";

sub shorten {
	if (defined($env{HTTP_LINK}) {

	} else {
		if (defined($env{'QUERY_STRING'}) && $env{'QUERY_STRING'} < 8) {
			unless (open (L, "data/links.txt")) {
				return('500', 'text/plain', "Bad permission\n");
			}

			while (my $str = <L>) {

			}

			return('302', 'text/plain', "$link\n");
		} else {
			return ('200', 'text/plain', "What?\n");
		}
	}

	return ('200', 'text/plain', "$msg\n");
}

1;
