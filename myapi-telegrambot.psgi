use strict;
use warnings "all";

# my plugins
use lib qw(./lib ./vendor_perl ./vendor_perl/lib/perl5);
use conf;
use telegrambot;
use threads;

my $CONF = loadConf();

if ($CONF->{api}->{prefix} eq '/') { $CONF->{api}->{prefix} = ''; }
my $prefix = $CONF->{api}->{prefix};

threads->create('run_telegrambot')->detach;

my $app = sub {
	my $env = shift;

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} eq "$prefix/help") {
		$status = '200';
		$msg = << 'EOL';
/telegrambot/ping - pong
EOL
	} elsif ($env->{PATH_INFO} eq "$prefix/telegrambot/ping") {
		$status = '200';
		$msg = "pong\n";
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};

__END__
# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
