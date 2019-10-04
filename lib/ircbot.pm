package ircbot;

use strict;
use warnings "all";
use diagnostics;
use vars qw/$VERSION/;
use Net::IRC;
use v5.10.0;
use Moose;
use Hailo;
use Encode;
use Data::Dumper;

#use lib qw(./lib ./vendor_perl);
use conf;

use Exporter qw(import);
our @EXPORT = qw(run_ircbot);

$VERSION = "1.0";

my $c = loadConf();
my @hailo;
my $hailo;

sub on_connect {
	my $conn = shift;
	$conn->join($conn->{channel});
	sleep 1;
#	$conn->privmsg($conn->{channel}, 'Hello everyone!');
	$conn->{connected} = 1;
}

sub on_msg {
	my ($conn, $event) = @_;
	$conn->privmsg($event->{nick}, "Get lost.");
}

sub on_public {
	my ($conn, $event) = @_;
	my $text = decode('utf-8', $event->{args}[0]);
	my $instance = 'bot1';
	say Dumper($conn);
	say Dumper($event);

	if ($text =~ /^\!$conn->{_nick} (.+)/) {
		# if so, pass the text and the nick off to the weather method
		my $answer = $hailo->learn_reply($1);
		$answer = encode('utf-8', $answer);
		my @texts = split("\n", $answer);

		foreach (@texts) {
			$conn->privmsg($event->{to}[0], $_);
		}
	} else {
		$hailo->learn($text);
	}
}


sub __run_ircbot_istance($) {
	my $instance = shift;

	$hailo = Hailo->new(
		brain => $c->{ircbot}->{$instance}->{brain},
		order => 3
	);

	my $irc = new Net::IRC;
	my $conn = $irc->newconn(
		Nick    => $c->{ircbot}->{$instance}->{name},
		Server  => $c->{ircbot}->{$instance}->{host},
		Port    => $c->{ircbot}->{$instance}->{port},
		Ircname => 'myapi irc module'
	);

	$conn->{channel} = $c->{ircbot}->{$instance}->{channel};
	$conn->add_handler('376', \&on_connect);
	$conn->add_handler('msg', \&on_msg);
	$conn->add_handler('public', \&on_public);
	$irc->start();
}

sub run_ircbot {
	__run_ircbot_istance('bot1');
}

1;
