use Data::Dumper;
use strict;
use warnings "all";
use JSON::PP;
use threads;
use threads::shared;

# my plugins
use lib "./lib";
use ping;
use utils;
use easter_egg;

sub loadConf();
sub saveConf($);

sub mythread();

my $main :shared = 0;

#unless ($main) { threads->create('mythread'); }

my $CONF = loadConf();
if ($CONF->{api}->{prefix} eq '/') { $CONF->{api}->{prefix} = ''; }
my $prefix = $CONF->{api}->{prefix};

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
		($status, $content, $msg) = ping::pong();
	} elsif ($env->{PATH_INFO} eq "$prefix/ip") {
		($status, $content, $msg) = utils::ip($env);
	} elsif (($env->{PATH_INFO} eq "$prefix/getaddrbyname")) {
		($status, $content, $msg) = utils::getaddrbyname($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/getnamebyaddr")) {
		($status, $content, $msg) = utils::getnamebyaddr($env->{HTTP_ADDRESS});
	} elsif (($env->{PATH_INFO} eq "$prefix/punycoder")) {
		($status, $content, $msg) = utils::punycoder($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/punydecoder")) {
		($status, $content, $msg) = utils::punydecoder($env->{HTTP_HOSTNAME});
	} elsif (($env->{PATH_INFO} eq "$prefix/time")) {
		($status, $content, $msg) = utils::mytime();
	} elsif (($env->{PATH_INFO} eq "$prefix/fortune") or
		 ($env->{PATH_INFO} eq "$prefix/quote")) {
		($status, $content, $msg) = easter_egg::quote();
	} elsif (($env->{PATH_INFO} eq "$prefix/chanserv") or
		 ($env->{PATH_INFO} eq "$prefix/chanServ") or
		 ($env->{PATH_INFO} eq "$prefix/ChanServ") or
		 ($env->{PATH_INFO} eq "$prefix/CHANSERV")) {
		($status, $content, $msg) = easter_egg::chanserv();
	} elsif (($env->{PATH_INFO} eq "$prefix/nickserv") or
		 ($env->{PATH_INFO} eq "$prefix/nickServ") or
		 ($env->{PATH_INFO} eq "$prefix/NickServ") or
		 ($env->{PATH_INFO} eq "$prefix/NICKSERV")) {
		($status, $content, $msg) = easter_egg::nickserv();
	} elsif ($env->{PATH_INFO} eq "$prefix/me") {
		($status, $content, $msg) = easter_egg::me();
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};

sub loadConf() {
	my $c = "data/myapi.json";
	my $sep = $/;
	$/ = '';
	open (C, $c) or die "No conf at $c\n";
	my $json = <C>;
	close C;
	return decode_json($json);
}

sub saveConf($) {
	my $c = shift;
	my $file = "data/myapi.json";
	my $j = JSON::PP->new->pretty->canonical->indent_length(4);
	my $json = $j->encode($c);
	# TODO: make it transactional
	open (C, ">", $file) or die "Unable to open $file\n";
	print C $json;
	close C;
}

sub mythread () {
	$main = 1;
	threads->detach();

	while (1) {
		sleep 1;
		open (F, ">>", '/tmp/myapi.txt');
		print F time() . "\n";
		close F;
	}
}



# vim: ft=perl noet ai ts=4 sw=4 sts=4:
__END__

https://toster.ru/q/75226

http://www.cbr.ru/scripts/XML_daily.asp
