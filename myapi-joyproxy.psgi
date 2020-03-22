use strict;
use warnings "all";

# my plugins
use lib qw(./lib ./vendor_perl ./vendor_perl/lib/perl5);
use conf;
use joyproxy;

my $CONF = loadConf();

if ($CONF->{api}->{prefix} eq '/') { $CONF->{api}->{prefix} = ''; }
my $prefix = $CONF->{api}->{prefix};

my $app = sub {
	my $env = shift;

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} =~ /$prefix\/joyproxy\/(.+)/) {
		my $joyproxyurl = $1;
		($status, $content, $msg) = ('400', $content, "Bad Request?\n");

		if (($joyproxyurl =~ /\.mp4/i) or ($joyproxyurl =~ /\.webm/i)) {
			($status, $content, $msg) = joyproxy($joyproxyurl);
		}
	}



	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};


__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
