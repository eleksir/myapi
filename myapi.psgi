use strict;
use warnings "all";
use diagnostics;

# my plugins
use lib qw(./lib ./vendor_perl ./vendor_perl/lib/perl5);
use conf;
use ping;
use utils;
use easter_egg;
use image_dl;
use threads;

my $CONF = loadConf();

if ($CONF->{api}->{prefix} eq '/') { $CONF->{api}->{prefix} = ''; }
my $prefix = $CONF->{api}->{prefix};

threads->create('image_dl_thread')->detach;

my $app = sub {
	my $env = shift;

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} eq "$prefix/help") {
		$status = '200';
		$msg = << 'EOL';
/ping - pong
/ip - your ip
/getaddrbyname - header hostname must be set
/getnameaaddr - header adderess must be set
/punycoder - header hostname must be set
/punydecoder - header hostname must be set
/time - current time
/quote - famous or not famous quotes
/fortune - synonym for quote
EOL
	} elsif ($env->{PATH_INFO} eq "$prefix/d") {
		$status = '200';
		$msg = Dumper($env);
	} elsif ($env->{PATH_INFO} eq "$prefix/ping") {
		($status, $content, $msg) = pong();
	} elsif ($env->{PATH_INFO} eq "$prefix/ip") {
		($status, $content, $msg) = ip($env);
	} elsif (($env->{PATH_INFO} eq "$prefix/getaddrbyname")) {
		($status, $content, $msg) = getaddrbyname($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/getnamebyaddr")) {
		($status, $content, $msg) = getnamebyaddr($env->{HTTP_ADDRESS});
	} elsif (($env->{PATH_INFO} eq "$prefix/punycoder")) {
		($status, $content, $msg) = punycoder($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/punydecoder")) {
		($status, $content, $msg) = punydecoder($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/time")) {
		($status, $content, $msg) = mytime();
	} elsif (($env->{PATH_INFO} eq "$prefix/fortune") or
		 ($env->{PATH_INFO} eq "$prefix/quote")) {
		($status, $content, $msg) = quote();
	} elsif (($env->{PATH_INFO} eq "$prefix/chanserv") or
		 ($env->{PATH_INFO} eq "$prefix/chanServ") or
		 ($env->{PATH_INFO} eq "$prefix/ChanServ") or
		 ($env->{PATH_INFO} eq "$prefix/CHANSERV")) {
		($status, $content, $msg) = chanserv();
	} elsif (($env->{PATH_INFO} eq "$prefix/nickserv") or
		 ($env->{PATH_INFO} eq "$prefix/nickServ") or
		 ($env->{PATH_INFO} eq "$prefix/NickServ") or
		 ($env->{PATH_INFO} eq "$prefix/NICKSERV")) {
		($status, $content, $msg) = nickserv();
	} elsif ($env->{PATH_INFO} eq "$prefix/me") {
		($status, $content, $msg) = me();
	} elsif ($env->{PATH_INFO} eq "$prefix/image_dl") {
		($status, $content, $msg) = image_dl_queue($env->{HTTP_URL});
	}


	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};


__END__

https://toster.ru/q/75226

http://www.cbr.ru/scripts/XML_daily.asp



# vim: ft=perl noet ai ts=4 sw=4 sts=4:
