package fortune;

use strict;
use vars qw/$VERSION/;

$VERSION = "1.0";

sub quote {
    return ('200', 'text/plain', `fortune`);
}

1;
