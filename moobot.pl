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

my $confpath = "$lib/config";

my $config = read_yml("config.yml",$confpath);
if ((!defined $config->{settings}->{fullpath}) or ($config->{settings}->{fullpath} ne $lib)) {
    $config->{settings}->{fullpath} = $lib;
    save_yml($config,"config.yml",$confpath);
}

print Dumper $config;

my $bot = MooBot->new($config);
my $plugins = MooBot::Plugin->new($confpath, $config->{plugins});



$plugins->set_cmdchar($config->{settings}->{cmdprefix}) if $config->{settings}->{cmdprefix};

my $cmdlist = $plugins->get_cmdlist();

POE::Session->create(
    inline_states => {
            _start     => \&irc_start,
            irc_001    => \&irc_connect,
            irc_join    => \&irc_user_join,
            irc_public => \&irc_public,
            irc_msg => \&irc_privmsg,
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

    $plugins->do_auto_method('on_bot_connect'); ##,$params);
    
}

sub irc_user_join {
    my $kernel = $_[KERNEL];
    my ($who, $channel, $msg) = @_[ARG0 .. ARG2];

    my ($nick, $hostname) = split(/!/, $who);
    my $me = $bot->{irc}->nick_name();
    
    print "$nick JOINED $channel ($hostname)\n";

    my $params = {
            'nick' => $nick,
            'type' => 'privmsg',
            'location' => $channel,
            'hostname' => $hostname,
        };


    if ($hostname eq $bot->{irc}->nick_long_form($me)) {
        my @reply = $plugins->do_auto_method('on_bot_join_chan',$params);
    } else {
        my @reply = $plugins->do_auto_method('on_user_join_chan',$params);
    }
    $bot->speak(@reply) if @reply;
   
}

sub irc_public {
    my ($kernel) = $_[KERNEL];
    my ($who, $where, $msg) = @_[ARG0 .. ARG2];
    my ($nick, $hostname) = split(/!/,$who);
    my $channel = $where->[0];
    
    my $params = {
            'nick' => $nick,
            'type' => 'privmsg',
            'location' => $channel,
            'hostname' => $hostname,
            'rawmsg' => $msg,
        };
    
    my @result = $plugins->process_cmd($params);
    $bot->speak(@result) if @result;

    my @reply = $plugins->do_auto_method('on_bot_public',$params);
    $bot->speak(@reply) if @reply;


}

sub irc_privmsg {
    my ($kernel) = $_[KERNEL];
    my ($hostmask, $where, $msg) = @_[ARG0 .. ARG2];
    my ($nick, $hostname) = split(/!/,$hostmask);
    my $channel = $where->[0];
    
    my $params = {
            'nick' => $nick,
            'type' => 'privmsg',
            #'location' => $channel, SEND NO LOCATION. PRIVATE CHAT.
            'hostname' => $hostname,
            'rawmsg' => $msg,
        };

    my @reply = $plugins->do_auto_method('on_bot_privmsg',$params);
    $bot->speak(@reply) if (@reply);

    my @result = $plugins->process_cmd($params);
    $bot->speak(@result) if @result;

}





# Run the bot
$poe_kernel->run();

exit;