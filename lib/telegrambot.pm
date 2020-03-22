package telegrambot;

use strict;
use warnings "all";
use diagnostics;
use vars qw/$VERSION/;
use v5.10.0;
use Hailo;
use Encode;
use Data::Dumper;
use Mojo::Base 'Telegram::Bot::Brain';

use conf;

use Exporter qw(import);
our @EXPORT = qw(run_telegrambot);

$VERSION = "1.0";

my $c = loadConf();
my $hailo;

has token => $c->{telegrambot}->{token};

sub __on_msg {
	my ($self, $msg) = @_;
	my $text = encode('utf-8', $msg->text);
# sometimes shit happens?
	return unless(defined($text));
# is this a 1-on-1 ?
	if ($msg->chat->is_user) {
		$msg->reply("Я вас не знаю, идите нахуй.");

# group chat
	} else {
		my $reply;

		if ($msg->chat->new_chat_members) {
			my $usernick = '';

			if (defined($msg->chat->new_chat_members->first_name) and ($msg->chat->new_chat_members->first_name ne '')) {
				$usernick .= $msg->chat->new_chat_members->first_name;
			}

			if (defined($msg->chat->new_chat_members->last_name) and ($msg->chat->new_chat_members->last_name ne '')) {
				if ($usernick ne '') {
					$usernick .= ' ' . $msg->chat->new_chat_members->first_name;
				} else {
					$usernick .= $msg->chat->new_chat_members->first_name;
				}
			}

			$usernick = $msg->chat->new_chat_members->username if ($usernick =~ /^\s+$/);

			$reply = sprintf("Добрый вечер, %s, располагайтесь, наслаждайтесь. Мы вас внимательно алё.", $usernick);
		} elsif ($msg->chat->left_chat_member) {
			my $usernick = '';

			if (defined($msg->chat->left_chat_member->first_name) and ($msg->chat->left_chat_member->first_name ne '')) {
				$usernick .= $msg->chat->left_chat_member->first_name;
			}

			if (defined($msg->chat->left_chat_member->last_name) and ($msg->chat->left_chat_member->last_name ne '')) {
				if ($usernick ne '') {
					$usernick .= ' ' . $msg->chat->left_chat_member->first_name;
				} else {
					$usernick .= $msg->chat->left_chat_member->first_name;
				}
			}

			$usernick = $msg->chat->left_chat_member->username if ($usernick =~ /^\s+$/);

			$reply = sprintf("До свидания, уважаемый %s. Возвращайтесь ещё. Мы будем рады вас опять...", $usernick);
		} elsif ($msg->chat->pinned_message) {
			$reply = "Где мои ржавые гвозди и кувалдометр? Ща прибъём это в топик!";
		} else {
			my $qname = quotemeta($c->{telegrambot}->{name});
			my $qtname = quotemeta($c->{telegrambot}->{tname});
			my $csign = quotemeta($c->{telegrambot}->{csign});

	# simple commands
			if ($text eq "${csign}ping") {
				$msg->reply("pong.");
				return;
			} elsif (
					($text eq $qname) or
					($text eq sprintf("%s", $qtname)) or
					($text eq sprintf("@%s_bot", $qname)) or # :(
					($text eq sprintf("%s ", $qtname))
				) {
				$msg->reply("Чего?");
				return;
			}

	# phrase directed to bot
			if ((lc($text) =~ /^${qname}[\,|\:]? (.+)/) or (lc($text) =~ /^${qtname}[\,|\:]? (.+)/)){
				$reply = $hailo->learn_reply(decode('utf-8', $1));
	# bot mention by name
			} elsif ((lc($text) =~ /.+ ${qname}[\,|\!|\?|\.| ]/) or (lc($text) =~ / $qname$/)) {
				$reply = $hailo->reply(decode('utf-8', $text));
	# bot mention by teleram name
			} elsif ((lc($text) =~ /.+ ${qtname}[\,|\!|\?|\.| ]/) or (lc($text) =~ / $qtname$/)) {
				$reply = $hailo->reply(decode('utf-8', $text));
	# just message in chat
			} else {
				$hailo->learn(decode('utf-8', $text));
			}
		}

		if (defined($reply) && $reply ne '') {
			$msg->reply($reply);
		}
	}
}

# setup our bot
sub init {
	$hailo = Hailo->new(
		brain => $c->{telegrambot}->{brain},
		order => 3
	);
	my $self = shift;
	$self->add_listener(\&__on_msg);
}

sub run_telegrambot {
	while (sleep 3) {
		eval {
			telegrambot->new->think;
		}
	}
}

1;

# vim: ft=perl noet ai ts=4 sw=4 sts=4:
