package telegrambot;

use strict;
use warnings "all";
use vars qw/$VERSION/;
use v5.10.0;
use File::Path qw( mkpath );
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

sub __cron {
	my $self = shift;
# noop
	return;
}

sub __on_msg {
	my ($self, $msg) = @_;
#	warn Dumper($msg); # debug
# lazy init chat-bot brains
	unless (defined($hailo->{$msg->chat->id})) {
		$hailo->{$msg->chat->id} = Hailo->new(
# we'll got file like this: data/telegrambot-brains/-1001332512695.brain.sqlite
			brain => sprintf("%s/%s.brain.sqlite", $c->{telegrambot}->{braindir}, $msg->chat->id),
			order => 3
		);
	}

# is this a 1-on-1 ?
	if ($msg->chat->type eq 'private') {
		my $text = encode('utf-8', $msg->text);
		my $reply = $hailo->{$msg->chat->id}->learn_reply(decode('utf-8', $text));

		if (defined($reply) && $reply ne '') {
			$msg->reply($reply);
		} else {
# if we have no answer, say something default in private chat
			$msg->reply("Общайтесь в чате \@slackware_ru");
		}
# group chat
	} elsif (($msg->chat->type eq 'supergroup') or ($msg->chat->type eq 'group')) {
		my $reply;

		if ($msg->chat->can('new_chat_members')) {
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

		} elsif ($msg->chat->can('left_chat_member')) {
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
		} else {
			return unless(defined($msg->text));
			my $text = encode('utf-8', $msg->text);
# sometimes shit happens?
			return unless(defined($text));

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
				$reply = $hailo->{$msg->chat->id}->learn_reply(decode('utf-8', $1));
# bot mention by name
			} elsif ((lc($text) =~ /.+ ${qname}[\,|\!|\?|\.| ]/) or (lc($text) =~ / $qname$/)) {
				$reply = $hailo->{$msg->chat->id}->reply(decode('utf-8', $text));
# bot mention by teleram name
			} elsif ((lc($text) =~ /.+ ${qtname}[\,|\!|\?|\.| ]/) or (lc($text) =~ / $qtname$/)) {
				$reply = $hailo->{$msg->chat->id}->reply(decode('utf-8', $text));
# just message in chat
			} else {
				$hailo->{$msg->chat->id}->learn(decode('utf-8', $text));
			}
		}

		if (defined($reply) && $reply ne '') {
			$msg->reply($reply);
		}
# should be channel, so we can't talk
	} else {
		return;
	}

	return;
}

# setup our bot
sub init {
	unless (-d $c->{telegrambot}->{braindir}) {
		mkpath ($c->{telegrambot}->{braindir}, 0, 0755);
	}

	my $self = shift;
	$self->add_listener(\&__on_msg);
#	$self->add_repeating_task(900, \&__cron);
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
