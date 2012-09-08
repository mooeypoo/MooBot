#!/usr/bin/perl

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
use POE;

use Data::Dumper;

## Include MooBot/bin for specific packages:
my $lib;
BEGIN {
    my @base = ( splitdir( dirname(__FILE__) ) );
    $lib  = join '/', @base, 'lib';
    push(@INC, $lib);
}

use MooBot;
use MooBot::Utils;
use MooBot::Plugin; 

my $config = MooBot::Utils::read_yml("config.yml","$lib/config");

my $bot = MooBot->new($lib, $config);
my $plugins = MooBot::Plugin->new($config->{plugins});

$plugins->set_cmdchar($config->{settings}->{cmdprefix}) if $config->{settings}->{cmdprefix};
#print $plugins->{cmdchar};

my $cmdlist = $plugins->get_cmdlist();

POE::Session->create(
    inline_states => {
            _start     => \&irc_start,
            irc_001    => \&irc_connect,
            irc_join    => \&irc_user_join,
            irc_public => \&irc_public,
            #irc_msg => \&irc_pvtmsg,
        },
);

#####################
#### IRC METHODS ####
######################
sub irc_start{
    my ($kernel, $heap) = @_[KERNEL, HEAP];
    my $chanlist = $bot->{config}->{settings}->{channels};
    my %chans = %$chanlist;

    $bot->{irc}->plugin_add('AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => \%chans ));
    $bot->{irc}->yield(register => "all");
    
    $bot->{irc}->yield(
		connect => {
                    Nick     => $config->{settings}->{nick},
                    Username => $config->{settings}->{username},
                    Ircname  => $config->{settings}->{ircname},
                    Server   => $config->{settings}->{server},
                    Port     => $config->{settings}->{port},
                }
    );
    
    $plugins->do_auto_method('on_bot_init');

}
sub irc_connect {
    print "Connected: ".$bot->{irc}->server_name()."\n";
    $plugins->do_auto_method('on_bot_connect');
}

sub irc_user_join {
    my $kernel = $_[KERNEL];
    my ($who, $channel, $msg) = @_[ARG0 .. ARG2];

    my ($nick, $hostname) = split(/!/, $who);
    my $me = $bot->{irc}->nick_name();
    
    print "$nick JOINED $channel ($hostname)\n";

    if ($hostname eq $bot->{irc}->nick_long_form($me)) {
        $plugins->do_auto_method('on_bot_join_chan');
    } else {
        $plugins->do_auto_method('on_user_join_chan');
    }
    
}

sub irc_public {
    my ($kernel) = $_[KERNEL];
    my ($who, $where, $msg) = @_[ARG0 .. ARG2];
    my ($nick, $hostname) = split(/!/,$who);
    my $channel = $where->[0];
    
    my $params = {
            'nick' => $nick,
            'type' => 'public',
            'location' => $channel,
            'hostname' => $hostname,
            'rawmsg' => $msg,
        };

    my $result = $plugins->process_cmd($params);
#    print Dumper $result;
}





# Run the bot
$poe_kernel->run();

exit;