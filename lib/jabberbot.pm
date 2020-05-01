# note http://www.gentoo.ru/node/21449
# необходимо закомменировать строку $response{authzid} = $authzid;
# в vendor_perl/5.24.3/Authen/SASL/Perl/DIGEST_MD5.pm
package jabberbot;

use strict;
use warnings "all";

use conf;
use utf8;
use Encode;
use Net::Jabber::Bot;
use v5.10;
use Hailo;

use Exporter qw(import);
use vars qw/$VERSION/;
$VERSION = "1.0";
our @EXPORT = qw(run_jabberbot);

my $c = loadConf();
my $hailo;

sub __background_checks {
	my $bot = shift;
	$bot->ChangeStatus('Chat', 'I\'m here');
	return;
}

sub __new_bot_message {
	my %hash = @_;
	my $bot = $hash{bot_object};
	my $text = encode('utf-8', $hash{body});

	if ($hash{'type'} eq "groupchat") {
		# ignore self messages
		return if ($hash{'from_full'} eq $bot->{'from_full'});
		# parse messages
		my $qname = quotemeta($c->{jabberbot}->{aleesa}->{mucname});
		if ($text =~ /^$qname$/) {
			$bot->SendGroupMessage($hash{'reply_to'}, "Чего тебе?");
		}elsif ($text =~ /^$qname[\,|\:]? (.+)/) {
			$bot->SendGroupMessage($hash{'reply_to'}, $hailo->learn_reply(decode('utf-8', $1)));
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}пинг") {
			$bot->SendGroupMessage($hash{'reply_to'}, "Понг.");
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}ping") {
			$bot->SendGroupMessage($hash{'reply_to'}, "Pong.");
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}rum") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me притаскивает на подносе стопку рома для ". (split(/\//,$hash{from_full}))[1] . ", края стопки искрятся кристаллами соли."
				);
			};
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}vodka") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me подаёт водку с маринованным огурчиком для " . (split(/\//,$hash{from_full}))[1]
				);
			};
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}beer") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me бахает об стол перед " . (split(/\//,$hash{from_full}))[1] . " кружкой холодного пива, часть пенной шапки сползает по запотевшей спенке кружки."
				);
			};
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}tequila") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me ставит рядом с " . (split(/\//,$hash{from_full}))[1] . " шот текилы, аккуратно на ребро стопки насаживает дольку лайма и ставит кофейное блюдце с горочкой соли."
				);
			};
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}whisky") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me демонстративно достаёт из морозилки пару кубических камушков, бросает их в толстодонный стакан и аккуратно наливает Jack Daniels. Запускает стакан вдоль барной стойки, он останавливается около " . (split(/\//,$hash{from_full}))[1] . "."
				);
			};
		} elsif ($text eq "$c->{jabberbot}->{aleesa}->{csign}absinthe") {
			eval {
				$bot->SendGroupMessage(
					$hash{'reply_to'},
					"/me наливает абсент в стопку. Смочив кубик сахара в абсенте кладёт его на дырявую ложечку и пожигает. Как только пламя потухнет, $c->{jabberbot}->{aleesa}->{mucname} размешивает оплавившийся кубик в абсенте и подносит стопку " .(split(/\//,$hash{from_full}))[1] . "."
				);
			};
		} else {
			#$hailo->learn($text);
			return;
		}
	} elsif ($hash{'type'} eq "chat") {
		$bot->SendPersonalMessage($hash{'reply_to'}, "Я вас не знаю, идите нахуй.");
		return;
	}

	return;
}


sub run_jabberbot {
	$hailo = Hailo->new(
		brain => $c->{jabberbot}->{aleesa}->{brain},
		order => 3
	);

	my %conflist = ();
	$conflist{$c->{jabberbot}->{aleesa}->{room}} = [];
	my $qname = quotemeta($c->{jabberbot}->{aleesa}->{mucname});

	my $bot = Net::Jabber::Bot->new(
		server => $c->{jabberbot}->{aleesa}->{host},
		server_host => $c->{jabberbot}->{aleesa}->{host},
		conference_server => $c->{jabberbot}->{aleesa}->{confsrv},
		tls => 0,
		username => $c->{jabberbot}->{aleesa}->{authname},
# threre is some nasty bug in module, so we have to set from_full explicitly
		from_full => sprintf(
			"%s@%s/%s",
			$c->{jabberbot}->{aleesa}->{room},
			$c->{jabberbot}->{aleesa}->{confsrv},
			$c->{jabberbot}->{aleesa}->{authname}
		),
		password => $c->{jabberbot}->{aleesa}->{password},
		alias => $c->{jabberbot}->{aleesa}->{mucname}, # name on confs
		resource => 'bot',
		safety_mode => 1,
		message_function => \&__new_bot_message,
		background_function => \&__background_checks,
		loop_sleep_time => 60,
		forums_and_responses => \%conflist,
	);

	while (sleep 3) {
		eval {
			$bot->Start();
		};
	}
}

1;

# vim: set ft=perl noet ai ts=4 sw=4 sts=4:
