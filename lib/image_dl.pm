package image_dl;

use strict;
use warnings "all";
use lib qw(./lib ./vendor_perl);
use Fcntl qw(O_RDONLY O_WRONLY);
use HTTP::Tiny;
use Image::Magick;
use POSIX qw(mkfifo);
use URI::URL;
use threads;
use threads::shared;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(image_dl_queue image_dl_thread);

use conf;

my $c = loadConf();
my @urls :shared;
my $ready :shared = 0;

unless (-p $c->{image_dl}->{fifo}) {
	unless (mkfifo($c->{image_dl}->{fifo}, 0600)) {
		die "Unable to create fifo $c->{image_dl}->{fifo} $!\n";
	}
}

sub image_dl_queue ($) {
	my $str = shift;
	chomp($str);
	$str .= "\n";

	sysopen (my $h, $c->{image_dl}->{fifo}, O_WRONLY) or do {
		warn "Unable to open $c->{image_dl}->{fifo}: $!";
		return ('500', 'text/plain', "Unable to write url to queue: $!\n");
	};

	use bytes;
	my $len = length($str);
	no bytes;

	my $res = syswrite($h, $str, $len) or do {
		warn "Unable to put download to queue: $!";
		return('500', 'text/plain', "Unable to put download to queue\n");
	};

	if ($res != $len) {
		close $h;
		warn "Incorrect amount of bytes written to queue: $!";
		return('500', 'text/plain', "Incorrect amount of bytes written to to queue\n");
	}

	close $h;
	return('200', 'text/plain', "Download queued\n");
}

sub __urlencode($) {
	my $str = shift;
	my $urlobj = url $str;
	$str = $urlobj->as_string;
	$urlobj = undef; undef $urlobj;
	return $str;
}

sub __is_picture($) {
	my $url = shift;
	$url = __urlencode($url);
	my $r = undef;

	eval {
		my $http = HTTP::Tiny->new();
		$r = $http->request('HEAD', $url);
		$http = undef; undef $http;
	};

	return undef if (defined($@) && $@ ne ''); # means eval with error

	if ($r->{'success'} and defined($r->{'headers'}->{'content-type'})) {
		if    ($r->{'headers'}->{'content-type'} =~ /^image\/gif/)  { $r = 'gif'; }
		elsif ($r->{'headers'}->{'content-type'} =~ /^image\/jpe?g/){ $r = 'jpeg';}
		elsif ($r->{'headers'}->{'content-type'} =~ /^image\/png/)  { $r = 'png'; }
		elsif ($r->{'headers'}->{'content-type'} =~ /^video\/webm/) { $r = 'webm';}
		elsif ($r->{'headers'}->{'content-type'} =~ /^video\/mp4/)  { $r = 'mp4'; }
		else  { $r = undef; }
	} else {
		$r = undef;
	}

	return $r;
}


sub __dlfunc(@) {
	my $url = shift;
	my $file = shift;
	$url = __urlencode($url);

# it may timeout
	eval {
		my $http1 = HTTP::Tiny->new();
		$http1->mirror($url, $file);
		$http1 = undef; undef $http1;
	};
}

sub __image_dl_subthread {
	$ready = 1;
	threads::yield;

	while (sleep 3) {
		while ( @urls > 0) {
			my $str;
# lock will be removed when it goes out of scope, so make atifical scope just for shifting @urls
			if (int(@urls) > 0) {
				lock(@urls); # wait 'till it will be safe to grab lock on @urls
				$str = shift(@urls);
			}

			next unless(defined($str));
			my $extension = __is_picture($str);

			if ($extension) {
				my $savepath = $c->{image_dl}->{dir};

				unless (-d $savepath) {
					mkdir ($savepath) or do {
						warn "[FATA] Unable to create $savepath: $!";
						next;
					}
				}

				my $fname = $str;
				$fname =~ s/[^\w!., -#]/_/g;
				$savepath = sprintf("%s/%s.%s", $savepath, $fname, $extension);

				if ( (lc($str) =~ /\.(gif|jpe?g|png|webm|mp4)$/) and ($1 eq $extension) ) {
					$savepath = $c->{image_dl}->{dir} . "/" . $fname;
				}

				unless (-f $savepath) {
					__dlfunc($str, $savepath);
				}

				undef $savepath;
				undef $fname;
			}
		}
	}

	return;
}

sub image_dl_thread {
	open (my $h, "<", $c->{image_dl}->{fifo}) or die "[FATA] Unable to open queue: $!\n";
	threads->create('__image_dl_subthread')->detach();
	do {} while (! $ready);
	threads::yield;

	while (1) {
		my $str = readline($h);

		if ((! defined($str)) || ($str eq "\n")) {
			close $h;
			open ($h, "<", $c->{image_dl}->{fifo}) or die "[FATA] Unable to open queue $c->{image_dl}->{fifo}: $!";
			next;
		}

# readline or <> from pipe can be funky: intead of 1 line, it _can_ return multiple lines
		my @lines = split("\n", $str);

		while (@lines > 0) {
			$str = pop(@lines);
			next unless(defined($str));

			if (substr($str, 0, 7) ne 'http://') {
				if (substr($str, 0, 8) ne 'https://') {
					next;
				}
			}

			chomp($str);
# wait 'till it will be safe to grab lock on @urls
			lock(@urls);
			push @urls, $str;
		}

		close $h;
		open ($h, "<", $c->{image_dl}->{fifo}) or die "[FATA] Unable to open queue $c->{image_dl}->{fifo}: $!\n";
	}

	close $h;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
