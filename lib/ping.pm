package ping;

use strict;
use vars qw/$VERSION/;

use Exporter qw(import);
our @EXPORT = qw(pong);

$VERSION = "1.0";

sub pong {
    return ('200', 'text/plain', "pong\n");
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
