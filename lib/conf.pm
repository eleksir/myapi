package conf;

use strict;
use warnings "all";
use vars qw/$VERSION/;
use Fcntl qw(O_WRONLY O_CREAT O_TRUNC);
use JSON::XS;
use utf8;

use Exporter qw(import);
our @EXPORT = qw(loadConf saveConf);

$VERSION = "1.0";

sub loadConf() {
	my $c = "data/myapi.json";
	open (C, "<", $c) or die "[FATA] No conf at $c: $!\n";
	my $len = (stat($c))[7];
	my $json;
	my $readlen = read(C, $json, $len);

	unless ($readlen) {
		close C;
		die "[FATA] Unable to read $c: $!\n";
	}

	if ($readlen != $len) {
		close C;
		die "[FATA] File $c is $len bytes on disk, but we read only $readlen bytes\n";
	}

	close C;
	return decode_json($json);
}

sub saveConf($) {
	my $c = shift;
	my $file = "data/myapi.json";
	my $j = JSON::XS->new->pretty->canonical->indent(1);
	my $json = $j->encode($c);
	$j = undef; undef $j;
	use bytes;
	my $len = length($json);
	no bytes;
	# TODO: make it transactional
	sysopen (C, $file, O_WRONLY|O_CREAT|O_TRUNC) or die "[FATA] Unable to open $file: $!\n";
	binmode C, ':utf8';

	my $written = syswrite(C, $json, $len);

	unless (defined($written)) {
		die "[FATA] Unable to write to $file: $!";
	}

	unless ($written != $len) {
		die "[FATA] We wrote $written bytes to $file, bu buffer length id $len bytes\n";
	}

	close C;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
