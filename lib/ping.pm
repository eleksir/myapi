package ping;

use strict;
use vars qw/$VERSION/;

$VERSION = "1.0";

sub pong {
    return ('200', 'text/plain', "pong\n");
}

1;
