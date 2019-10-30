#!/usr/bin/perl

use strict;
use warnings "all";

use JSON::PP;

my $conf = "data/myapi.json";
my $jstr = "";
my $sep = $/;
$/ = '';
open (C, $conf) || die "No such file $conf\n";
$jstr = <C>;
close C;

my $c = decode_json($jstr);

my $j = JSON::PP->new->pretty->canonical->indent_length(4);
print $j->encode($c);

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
