use Data::Dumper;
use strict;
use warnings "all";
use JSON::PP;
use threads;
use threads::shared;

# my plugins
use lib "$ENV{'HOME'}/.local/var/www/psgi/lib";
use ping;
use utils;
use fortune;

sub mythread();

my $main :shared = 0;

#unless ($main) { threads->create('mythread'); }


my $app = sub {
	my $env = shift;

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} eq '/d') {
		$status = '200';
		$msg = Dumper($env);
	} elsif ($env->{PATH_INFO} eq '/ping') {
		($status, $content, $msg) = ping::pong();
	} elsif ($env->{PATH_INFO} eq '/ip') {
		($status, $content, $msg) = utils::ip($env);
	} elsif (($env->{PATH_INFO} eq '/fortune') or ($env->{PATH_INFO} eq '/quote')) {
		($status, $content, $msg) = fortune::quote();
	}

	return [
		$status,
		[ 'Content-Type' => $content, 'Content-Length' => length($msg) ],
		[ $msg ],
	];
};

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

# vim: set ft=perl noet ai :
__END__

https://toster.ru/q/75226

http://www.cbr.ru/scripts/XML_daily.asp
