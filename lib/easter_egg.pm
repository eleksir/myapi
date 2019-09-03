package easter_egg;

use strict;
use warnings "all";
use vars qw/$VERSION/;

$VERSION = "1.0";

use Exporter qw(import);
our @EXPORT = qw(quote chanserv nickserv me);

sub quote {
	if (-f "/usr/games/fortune") {
		return ('200', 'text/plain', `fortune`);
	} else {
		return ('200', 'text/plain', "No fortune here!\n");
	}
}

sub chanserv {
	return ('200', 'text/plain', "There is no conserves here.\n");
}

sub nickserv {
	return ('200', 'text/plain', "Nick is out, please come back later.\n");
}

sub me {
	return ('200', 'text/plain', "Who?\n");
}

1;
