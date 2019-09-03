package image_dl;

use strict;
use warnings "all";
use HTTP::Tiny;
use Net::SSLeay;
use IO::Socket::SSL;
use Image::Magick;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(queue_image dl_thread);



sub queue_image (@) {
	my $url = shift;
	my $images = shift;
	push @{$images}, $url;
	return('200', 'text/plain', "Download queued\n");
}

sub __urlencode($) {
	my $url = shift;
	my $urlobj = url $url;
	$url = $urlobj->as_string;
	undef $urlobj;
	return $url;
}

sub __is_picture($) {
	my $url = shift;
	$url = __urlencode($url);
	my $r = undef;

	eval {
		my $http = HTTP::Tiny->new();
		$r = $http->request('HEAD', $url);
		undef $http;
	};

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

	undef $url;
	return $r;
}

sub __dlfunc(@) {
	my $url = shift;
	my $file = shift;
	$url = __urlencode($url);

	eval {
		my $http1 = HTTP::Tiny->new();
		$http1->mirror($url, $file);
		undef $http1;
	};

	eval {
		if ($file =~ /(png|jpe?g|gif)$/i) {
			my $im = Image::Magick->new();
			my $rename = 1;
			my (undef, undef, undef, $format) = $im->Ping($file);

			if (defined($format)) {
				$rename = 0 if (($format eq 'JPEG') and ($file =~ /jpe?g$/i));
				$rename = 0 if (($format eq 'GIF') and ($file =~ /gif$/i));
				$rename = 0 if (($format =~ /^PNG/) and ($file =~ /png$/i));
				rename $file, sprintf("%s.%s", $file, lc($format)) if ($rename == 1);
			}

			undef $im;
			undef $rename;
			undef $format;
		}
	}

	#undef $url;
	#undef $file;
	#return;
}


sub dl_thread (@) {
	my $dir = shift;
	my $sleep = shift;
	threads->detach();

	while ( 1 ) {
		if (@{main::images} > 0) {
			my @pic = @{main::images};
			@{main::images} = -1;

			foreach my $url (@pic) {
				my $extension = __is_picture($url);

				if (defined($extension)) {
					my $savepath = $dir;
					mkdir ($savepath) unless (-d $savepath);
					my $fname = $url;
					$fname =~ s/[^\w!., -#]/_/g;
					$savepath = sprintf("%s/%s.%s", $savepath, $fname, $extension);

					if ( (lc($url) =~ /\.(gif|jpe?g|png|webm|mp4)$/) and ($1 eq $extension) ) {
						$savepath = $dir . "/" . $fname;
					}

					__dlfunc($url, $savepath);
					undef $savepath;
					undef $fname;
				}

				undef $url;
				undef $extension;
			}
			@pic = -1; undef @pic;
		} else {
			sleep ($sleep);
		}
	}

	return;
}

1;
