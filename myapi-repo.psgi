use strict;
use warnings "all";

# my plugins
use lib qw(./lib ./vendor_perl ./vendor_perl/lib/perl5);
use conf;
use upload;
use metagen;

my $CONF = loadConf();

if ($CONF->{api}->{prefix} eq '/') { $CONF->{api}->{prefix} = ''; }
my $prefix = $CONF->{api}->{prefix};

my $app = sub {
	my $env = shift;

	my $msg = "Your Opinion is very important for us, please stand by.\n";
	my $status = '404';
	my $content = 'text/plain';

	if ($env->{PATH_INFO} =~ /$prefix\/upload\/(.+)/) {
		my $upload = $1;
		($status, $content, $msg) = ('400', $content, "Bad Request?\n");

		if (defined($env->{HTTP_AUTH}) && ($env->{HTTP_AUTH} eq $CONF->{upload}->{auth})) {
			if (($upload !~ /\.\./) and ($upload =~ /^[A-Z|a-z|0-9|_|\-|\+|\/|\.]+$/)) {
				if (defined($env->{CONTENT_LENGTH}) && ($env->{CONTENT_LENGTH} > 0)) {
					($status, $content, $msg) = upload($env->{'psgi.input'}, $env->{CONTENT_LENGTH}, $upload);
				}
			} else {
				$msg = "Something wrong with upload path.\n";
			}
		} else {
			($status, $content, $msg) = ('403', $content, "You're not allowed here. Fuck off.\n");
		}
	} elsif ($env->{PATH_INFO} eq "$prefix/metagen") {
		if (defined($env->{HTTP_REPO})) {
			($status, $content, $msg) = metagen($env->{HTTP_REPO});
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
