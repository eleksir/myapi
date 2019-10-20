package upload;

our $VERSION = "1.0";
use vars qw/$VERSION @EXPORT @ISA/;
require Exporter;
@EXPORT = qw (upload);
@ISA = "Exporter";

use strict;
use warnings "all";
use diagnostics;
use Fcntl;
use conf;

my $c = loadConf();

sub upload {
	my $input = shift;        # file descriptor with data being uploaded
	my $len = shift;          # expected data length (from client)
	my $name = shift;         # upload "dir" and filename
	my ($status, $content, $msg) = ('400', 'text/plain', "Bad Request?\n");

	return ($status, $content, "No Content-Length supplied.\n") unless (defined($len));
	return ($status, $content, "No name supplied.\n") unless (defined($name));

	my $d;
	($d, $name) = split(/\//, $name, 2);

	return ($status, $content, "Name does not match pattern.\n") unless ($name =~ /^[A-Z|a-z|0-9|_|\-|\+]+$/);

	my $match;

	foreach (keys(%{$c->{upload}->{dir}})) {
		if ($d eq $_) {
			$match = 1;
			last;
		}
	}

	return ($status, $content, "Incorrect destination dir.\n") unless($match); # incorrect destination in url

	$name = sprintf("%s/%s", $c->{upload}->{dir}->{$d}, $name);

	if ($len > 0) {
		if (sysopen (F, $name, O_CREAT|O_TRUNC|O_WRONLY)) {
			my $buf;
			my $readlen = 0;
			my $totalread = 0;
			my $buflen = 524288; # 512 kbytes, looks sane enough

			if ($len < $buflen) {
				$buflen = $len;
			}

			do {
				$readlen = $input->read($buf, $buflen);

				unless (defined(syswrite F, $buf, $readlen)) { # out of space?
					close F;
					unlink $name;
					return ('500', $content, "An error has occured during upload: $!\n");
				}

				$totalread += $readlen;
			} while ($readlen == $buflen);

			close F;

			if ($totalread != $len) {
				($status, $content, $msg) = ('400', $content, "Content-Length does not match amount of recieved bytes.\n");
			} else {
				($status, $content, $msg) = ('201', $content, "Uploaded.\n");
			}
		} else {
			($status, $content, $msg) = ('500', $content, "Unable to write: $!\n");
		}
	} else {
		$msg = "Incorrect Content-Length\n";
	}

	return ($status, $content, $msg);
}

1;
