# Most of this data is generated during package build process and being uploaded
# to pool alongside with packages themselves. So we can easily and fast regen meta.

# Assume that whole operation takes resonable amount of time to perform it syncronously

# metadata consists of
# * CHECKSUMS.md5 or CHECKSUMS.md5.gz - checksum of each file in repo
# * ChangeLog.txt - optional, contains history of changes, this script does not
#                   handle it
# * FILELIST.TXT - whole list of files that are part of repostory data or
#                  metadata
# * PACKAGES.TXT - packages description with metainfo such as relative path in
#                  repo, compressed size and uncompressed size
# * MANIFEST.bz2 - list of files in each package

# TODO: make metadata in atomic way
# TODO: validate metadata

package metagen;

use warnings "all";
use strict;

use Fcntl;
use Compress::Raw::Bzip2 qw(BZ_RUN_OK BZ_STREAM_END);
use Compress::Raw::Zlib;
use POSIX qw(strftime);

use conf;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(metagen);

sub metagen($);
sub __pdate;        # generates current date in pretty format

sub metagen($) {
	my $dir = shift;
	my $c = loadConf();
	$dir = $c->{metagen}->{$dir};

	unless (defined($dir)) {
		return ('400', 'text/plain', "No such repository\n");
	}

	opendir(my $dh, $dir) or do {
		warn "[FATA] Unable to read $dir : $!";
		return  ('500', 'text/plain', "Unable to read $dir : $!\n");
	};

	my @list;

	while (readdir($dh)) {
		next if ($_ eq '.');
		next if ($_ eq '..');
		push @list, $_;
	}

	closedir $dh;
	@list = sort(@list);

# manifest
	my $manifest = '';
	my $bz = new Compress::Raw::Bzip2 1, 9, 0;

	unless (defined($bz)) {
		warn "[FATA] Unable to create bz object";
		return  ('500', 'text/plain', "Unable to create bz object\n");
	}

	my $output;
	my $buf;

	foreach my $str (@list) {
		if ($str =~ /\.lst/) {
			open (F, '<', "$dir/$str") or do {
				warn "[FATA] Unable to open file $dir/$str: $!";
				return  ('500', 'text/plain',  "Unable to open file $dir/$str: $!\n");
			};

			my $len = (stat("$dir/$str"))[7];
			my $readlen = read(F, $buf, $len);

			unless (defined($readlen)) {
				warn "[FATA] Unable to read $dir/$str: $!";
				return ('500', 'text/plain', "Unable to read $dir/$str: $!\n");
			}

			if ($readlen != $len) {
				warn "[FATA] Unable to read $dir/$str: amount of read bytes does not match with file size";
				return ('500', 'text/plain', "Unable to read $dir/$str\n");
			}

# we need exactly 1 \n at the end of the buffer
			while (substr($buf, -2, -1) eq "\n") {
				chop($buf);
			}
			$buf .= "\n\n\n";

# also $buffer must not begin with \n
			while (substr($buf, 0, 1) eq "\n") {
				$buf = substr($buf, 1, -1);
			}
			
			if ($bz->bzdeflate($buf, $output) != BZ_RUN_OK) {
				warn "[FATA] Unable to perofrm bzip2 compression";
				return  ('500', 'text/plain',  "Unable to perform bzip2 compression\n");
			}

			if ($bz->bzflush($output) != BZ_RUN_OK) {
				warn "[FATA] Unable to flush bz buffer";
				return  ('500', 'text/plain',  "Unable to flush bz buffer\n");
			}

			close F;
		}
	}

	if ($bz->bzclose($output) != BZ_STREAM_END) {
		warn "[FATA] Unable to flush and close bz buffer";
		return  ('500', 'text/plain',  "Unable to flush and close bz buffer\n");
	}

	$bz = '';

	sysopen(BZ, "$dir/MANIFEST.bz2", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open $dir/MANIFEST.bz2: $!";
		return ('500', 'text/plain', "Unable to open $dir/MANIFEST.bz2: $!\n");
	};

	binmode(BZ);
	my $len = length($output);
	my $written = syswrite(BZ, $output, $len);
	close BZ;

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/MANIFEST.bz2: $!";
		return ('500', 'text/plain', "Unable to write $dir/MANIFEST.bz2: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/MANIFEST.bz2: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/MANIFEST.bz2: written bytes does not match with buffer size\n");
	}

	$output = '';
	$buf = '';
# checksums
	my $buffer = 'These are the MD5 message digests for the files in this directory.
If you want to test your files, use \'md5sum\' and compare the values to
the ones listed here.

To test all these files, use this command:

tail +13 CHECKSUMS.md5 | md5sum --check | less

\'md5sum\' can be found in the GNU coreutils package on ftp.gnu.org in
/pub/gnu, or at any GNU mirror site.

MD5 message digest                Filename
';

	foreach my $str (@list) {
		next if ($str =~ /CHECKSUMS\.md5$/);
		next if ($str =~ /CHECKSUMS.md5.gz$/);

		if ($str =~ /\.md5/) {
			sysopen (F, "$dir/$str", O_RDONLY) or do {
				warn "[FATA] Unable to open file $dir/$str: $!";
				return  ('500', 'text/plain',  "Unable to open file $dir/$str: $!\n");
			};

			$buffer .= <F>;
			close F;
		}
	}

	sysopen (CS, "$dir/CHECKSUMS.md5", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open file $dir/CHECKSUMS.md5: $!";
		return ('500', 'text/plain', "Unable to open file $dir/CHECKSUMS.md5: $!\n");
	};

	use bytes;
	$len = length($buffer);
	no bytes;
	$written = syswrite(CS, $buffer, $len);
	close CS;

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/CHECKSUMS.md5: $!";
		return ('500', 'text/plain', "Unable to write $dir/CHECKSUMS.md5: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/CHECKSUMS.md5: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/CHECKSUMS.md5: written bytes does not match with buffer size\n");
	}

	my $gz = new Compress::Raw::Zlib::Deflate (
		-Level => Z_BEST_COMPRESSION,
		-CRC32 => 1,
		-ADLER32=> 1,
		-WindowBits => WANT_GZIP
	);

	unless (defined($gz)) {
		warn "[FATA] Unable to create gz object";
		return  ('500', 'text/plain',  "Unable to create gz object\n");
	}

	if ($gz->deflate($buffer, $output) != Z_OK) {
		warn "[FATA] Unable to deflate";
		return  ('500', 'text/plain',  "Unable to deflate\n");
	}

	if ($gz->flush($output) != Z_OK) {
		warn "[FATA] Unable to flush gz object";
		return  ('500', 'text/plain',  "Unable to flush gz object\n");
	}

	$gz = '';
	$buffer = '';

	sysopen (F, "$dir/CHECKSUMS.md5.gz", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open file $dir/CHECKSUMS.md5.gz: $!";
		return  ('500', 'text/plain',  "Unable to open file $dir/CHECKSUMS.md5.gz: $!\n");
	};

	binmode F;
	$len = length($output);
	$written = syswrite(F, $output, $len);
	close F;

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/CHECKSUMS.md5.gz: $!";
		return ('500', 'text/plain', "Unable to write $dir/CHECKSUMS.md5.gz: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/CHECKSUMS.md5.gz: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/CHECKSUMS.md5.gz: written bytes does not match with buffer size\n");
	}

	$output = '';

# packages
	my $date = __pdate;
	$buffer = "PACKAGES.TXT;  $date\n\n";

	foreach my $str (@list) {
		if ($str =~ /\.meta/) {
			open (F, '<', "$dir/$str") or do {
				warn "[FATA] Unable to open file $dir/$str: $!";
				return  ('500', 'text/plain',  "Unable to open file $dir/$str: $!\n");
			};

			my $buf;
			my $len = (stat("$dir/$str"))[7];
			my $readlen = read(F, $buf, $len);

			unless (defined($readlen)) {
				warn "[FATA] Unable to read $dir/$str: $!";
				return ('500', 'text/plain', "Unable to read $dir/$str: $!\n");
			}

			if ($readlen != $len) {
				warn "[FATA] Unable to read $dir/$str: amount of read bytes doed not match with file size";
				return ('500', 'text/plain', "Unable to read $dir/$str\n");
			}

			close F;
			$buffer .= $buf;

# we need exactly 1 \n at the end of the buffer
			while (substr($buffer, -2, -1) eq "\n") {
				chop($buffer);
			}

			$buffer .= "\n\n";

# also $buffer must not begin with \n
			while (substr($buffer, 0, 1) eq "\n") {
				$buffer = substr($buffer, 1, -1);
			}
		}
	}

	sysopen (F, "$dir/PACKAGES.TXT", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open file $dir/PACKAGES.TXT: $!";
		return  ('500', 'text/plain',  "Unable to open file $dir/PACKAGES.TXT: $!\n");
	};

	binmode F;
	use bytes;
	$len = length($buffer);
	$written = syswrite(F, $buffer, $len);
	close F;

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/PACKAGES.TXT: $!";
		return ('500', 'text/plain', "Unable to write $dir/PACKAGES.TXT: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/PACKAGES.TXT: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/PACKAGES.TXT: written bytes does not match with buffer size\n");
	}

	close F;

	$gz = new Compress::Raw::Zlib::Deflate (
		-Level => Z_BEST_COMPRESSION,
		-CRC32 => 1,
		-ADLER32=> 1,
		-WindowBits => WANT_GZIP
	);

	unless (defined($gz)) {
		warn "[FATA] Unable to create gz object";
		return  ('500', 'text/plain',  "Unable to create gz object\n");
	}

	if ($gz->deflate($buffer, $output) != Z_OK) {
		warn "[FATA] Unable to deflate";
		return  ('500', 'text/plain',  "Unable to deflate\n");
	}

	if ($gz->flush($output) != Z_OK) {
		warn "[FATA] Unable to flush gz object";
		return  ('500', 'text/plain',  "Unable to flush gz object\n");
	}

	$gz = '';
	$buffer = '';

	sysopen (F, "$dir/PACKAGES.TXT.gz", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open file $dir/PACKAGES.TXT.gz: $!";
		return  ('500', 'text/plain',  "Unable to open file $dir/PACKAGES.TXT.gz: $!\n");
	};

	binmode F;
	$len = length($output);
	$written = syswrite(F, $output, $len);

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/PACKAGES.TXT.gz: $!";
		return ('500', 'text/plain', "Unable to write $dir/PACKAGES.TXT.gz: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/PACKAGES.TXT.gz: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/PACKAGES.TXT.gz: written bytes does not match with buffer size\n");
	}

	close F;
	$output = '';

	@list = -1;
	@list = split(/\n/, `ls -lAn --time-style=long-iso "$dir"`);

	@list = map {
		my $str = $_;

		if (length($str) > 45) {
			substr($str, 44, 0, './');
			$str = $str . "\n";
		} else {
			my $date = __pdate;
			$str = "$date

Here is the file list for this directory ,
maintained by Eric Hameleers <alien\@slackware.com> .
If you are using a mirror site and find missing or extra files
in the subdirectories, please have the archive administrator
refresh the mirror.

";
		}

		$str;
	} @list;

	sysopen(F, "$dir/FILELIST.TXT", O_WRONLY|O_TRUNC|O_CREAT) or do {
		warn "[FATA] Unable to open $dir/FILELIST.TXT: $!";
		return  ('500', 'text/plain', "Unable to open $dir/FILELIST.TXT: $!\n");
	};

	binmode F;
	$buffer = join('', @list);
	@list = -1; undef @list;
	use bytes;
	$len = length($buffer);
	no bytes;
	$written = syswrite F, $buffer, $len;

	unless (defined($written)) {
		warn "[FATA] Unable to write $dir/FILELIST.TXT: $!";
		return ('500', 'text/plain', "Unable to write $dir/FILELIST.TXT: $!\n");
	}

	if ($len != $written) {
		warn "[FATA] Unable to write $dir/FILELIST.TXT: written bytes does not match with buffer size";
		return ('500', 'text/plain', "Unable to write $dir/FILELIST.TXT: written bytes does not match with buffer size\n");
	}

	close F;
	$buffer = '';
	return  ('200', 'text/plain', "Done\n");
}

sub __pdate {
	my @time = gmtime(time);
	my @DAYOFWEEK = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
	my @MONTH = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Nov', 'Dec');
	return strftime "$DAYOFWEEK[$time[6]] $MONTH[$time[4] - 1] %e %T UTC %Y", @time;
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4 :
