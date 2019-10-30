package conf;

use strict;
use warnings "all";
use diagnostics;
use vars qw/$VERSION/;
use JSON::PP;

use Exporter qw(import);
our @EXPORT = qw(loadConf saveConf);

$VERSION = "1.0";

sub loadConf() {
	my $c = "data/myapi.json";
	my $sep = $/;
	$/ = '';
	open (C, $c) or die "No conf at $c\n";
	my $json = <C>;
	close C;
	return decode_json($json);
}

sub saveConf($) {
	my $c = shift;
	my $file = "data/myapi.json";
	my $j = JSON::PP->new->pretty->canonical->indent_length(4);
	my $json = $j->encode($c);
	# TODO: make it transactional
	open (C, ">", $file) or die "Unable to open $file\n";
	print C $json;
	close C;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4: