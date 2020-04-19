package joyproxy;

use strict;
use warnings "all";
use lib qw(./lib ./vendor_perl);
use Fcntl qw(O_RDONLY O_WRONLY O_CREAT O_TRUNC);
use HTTP::Tiny;
use URI::URL;
use URI::Escape;
use conf;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(joyproxy joyurl);

my $CONF = loadConf();

sub joyproxy ($) {
	my $str = shift;
	chomp($str);

	return ('500', 'text/plain', 'This is not reactor video') if ($str !~ /^img[0-9]+\.reactor\.cc/);

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

sub joyurl ($) {
	my $str = shift;
	$str = uri_unescape($str);

	if (length($str) < 60) {
		$str = '';
	} else {
		$str = substr($str, 14);
	}

	if ($str =~ /^img\d+\.reactor\.cc/) {
# img1.reactor.cc/pics/post/webm/видосик.webm
		my @url = split(/\//, $str);

		if (($url[3] eq 'webm' || $url[3] eq 'mp4') and
		    ($url[4] =~ /\.webm$/ || $url[4] =~ /\.mp4$/)) {
# we prefer mp4, right?, so
			my $fname;
			$fname = substr($url[4], 0, -4) if (substr($url[4], -4, 4) eq '.mp4');
			$fname = substr($url[4], 0, -5) if (substr($url[4], -5, 6) eq '.webm');

			$str = sprintf(
				"https://exs-elm.ru%s/joyproxy/%s/%s/%s/mp4/%s.mp4",
				$CONF->{api}->{prefix},
				$url[0],
				$url[1],
				$url[2],
				$fname
			);

			$str = __urlencode($str);
		} else {
			$str = '';
		}
	} else {
		$str = '';
	}

	my $msg = "<html>
<body>
<form method='get' action='$CONF->{api}->{prefix}/joyurl'>
<input type='text' name='joyurl' size=100 autofocus><br />
<input type='submit' value='Post it!'' style='font-size:115%;'' />
<br>$str
</body>
</html>
";

	return ('200', 'text/html', $msg);
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
	$#tmparray = -1; undef @tmparray;
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
