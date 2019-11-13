package buildinfo;

use strict;
use warnings "all";
use vars qw/$VERSION/;
use conf;
use JSON::PP;
use Data::Dumper;

use Exporter qw(import);
our @EXPORT = qw(buildinfo);

$VERSION = "1.0";

my $c = loadConf();

sub buildinfo($) {
	my $repo = shift;
	my ($status, $content, $msg) = ('400', 'text/plain', "Bad Request?\n");

	return ($status, $content, $msg) unless ($repo =~ /\//);

	my ($config, $package) = split(/\//, $repo);

	unless (defined($c->{buildinfo}->{$config})) {
		$msg = "Config repo $config is not defined in config.\n";
		return ($status, $content, $msg);
	}

	open (JSON, "<", $c->{buildinfo}->{$config}) or do {
		$status = '500';
		$msg = "Unable to open $c->{buildinfo}->{$config}; $!\n";
		return ($status, $content, $msg);
	};

	my $sep = $/;
	my $json = <JSON>;
	close JSON;
	$/ = $sep;

	my $j = eval { decode_json($json) } or do {
		$status = '500';
		$msg = "Error during decoding $c->{buildinfo}->{$config}; $@\n";
		return ($status, $content, $msg);
	};

	unless (defined($j->{$package})) {
		$msg = "$package is not defined in config for $config.\n";
		return ($status, $content, $msg);
	}

	$json = JSON::PP->new->pretty->canonical->indent_length(4)->encode($j->{$package}) or do {
		$status = '500';
		$msg = "Unable to encode json.\n";
		return ($status, $content, $msg);
	};

	$status = '200';
	$content = 'application/json';
	$msg = $json;
	return ($status, $content, $msg);
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
