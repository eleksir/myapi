package joyproxy;

use strict;
use warnings "all";
use lib qw(./lib ./vendor_perl);
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use HTTP::Tiny;
use URI::URL;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(joyproxy);


sub joyproxy ($) {
	my $str = shift;
	chomp($str);

	return ('500', 'text/plain', 'This is not reactor video') if ($str !~ /^img[0|1]\.reactor\.cc/);

	my ($file, $filesize) = __dlfunc("http://$str");

	if (defined($file)) {
		my $buf = '';

		if (open(VID, '<', $file)) {
			read(VID, $buf, $filesize);
			close VID;

			if ($file =~ /\.mp4/i) {
				return ('200', 'video/mp4', $buf);
			} elsif ($file =~ /\.webm/i) {
				return ('200', 'video/webm', $buf);
			} else {
				return ('200', 'video/mpeg', $buf);
			}
		} else {
			unlink $file if (-f $file);
			return ('500', 'text/plain', "Unable to open file in temporary loaction: $!\n");
		}
	} else {
		return ('500', 'text/plain', "Unable to get file from remote source!\n");
	}
}

sub __urlencode($) {
	my $str = shift;
	my $urlobj = url $str;
	$str = $urlobj->as_string;
	$urlobj = undef;
	undef $urlobj;
	return $str;
}


sub __dlfunc($) {
	my $url = shift;

	if (! -d "/tmp/joyproxy") {
		warn "no /tmp/joyproxy";
		return (undef, undef) unless (mkdir("/tmp/joyproxy"));
	}

	my @tmparray = split(/\//, $url);
	my $file = $tmparray[@tmparray - 1];
	@tmparray = -1; undef @tmparray;
	$file = "/tmp/joyproxy/" . $file;
	$url = __urlencode($url);

	my $http = HTTP::Tiny->new(max_size => 10485760);

	my $response = $http->get(
		$url,
		{
			headers => {
				"Accept" => '*/*',
				"Accept-Encoding" => 'identity;q=1, *;q=0',
				"Accept-Language" => 'ru-RU,ru;q=0.9,en-US;q=0.8,en;q=0.7',
				"Range" => 'bytes=0-',
				"Referer" => 'http://old.reactor.cc/all',
				"User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.116 Safari/537.36"
			}
		}
	);

	if ($response->{success}) {
		sysopen (FILE, $file, O_WRONLY|O_CREAT|O_TRUNC) or do {
			$http = undef;
			$response = undef;
			return (undef, undef);
		};

		my $filesize = length($response->{content});

		syswrite (FILE, $response->{content}, $filesize) or do {
			$http = undef;
			$response = undef;
			return (undef, undef);
		};

		close FILE;
		$http = undef;
		$response = undef;
		return ($file, $filesize);
	} else {
		$http = undef;
		$response = undef;
		return (undef, undef);
	}
}


1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
