#!/usr/bin/perl
package MooBot;
use strict; use warnings;

use Data::Dumper;
## IRC STUFFS:
use POE;
use POE::Component::IRC::State;
use POE::Component::IRC::Plugin::AutoJoin;
use IRC::Utils;


use Carp qw/ confess /;


sub new {
    my $class = shift;
    my $self = {};
    my $lib_path = shift;
    my $conf_file = shift || "config.yml";
    
    bless $self, $class;
    
    ## read config file:
    $self->{config} = $conf_file;

    $self->{irc} = POE::Component::IRC::State->spawn();

    #POE::Session->create(
    #        object_states => [
    #            $self => {
    #                _start     => 'irc_start',
    #                irc_001    => 'irc_connect',
    #                irc_join    => 'irc_user_join',
    #                #irc_public => 'irc_public',
    #                #irc_msg => 'irc_pvtmsg',
    #            },
    #  ],
    #);
    
    # Run the bot until it is done.
#    $poe_kernel->run();
    
    return $self;
}


sub speak {
    my $self= shift;
    my $speak_hash = shift;
    ## EXPECTS HASH:

    # $speak_hash->{0}->{type}
    # $speak_hash->{0}->{where}
    # $speak_hash->{0}->{text}

    # $speak_hash->{1}->{type}
    # $speak_hash->{1}->{where}
    # $speak_hash->{1}->{text}
    # etc
    
    my $err=0;
        
    foreach my $sp (keys %$speak_hash) {
        my $type = $speak_hash->{$sp}->{type} ? $speak_hash->{$sp}->{type} : 'privmsg';
        $err=1 if (!$speak_hash->{$sp}->{loc}) or (!$speak_hash->{$sp}->{reply});
        
        my $loc = $speak_hash->{$sp}->{where} if $speak_hash->{$sp}->{where};
        my $reply = $speak_hash->{$sp}->{text} if $speak_hash->{$sp}->{text};
        
        ## speak:
        unless ($err) {
            $self->{irc}->yield($type => $loc, $reply);
        }
    }
    
}

#####################
#### IRC METHODS ####
######################
#sub irc_start{
#    my $self = shift;
#    my ($kernel, $heap) = @_[KERNEL, HEAP];
#    my $chanlist = $self->{config}->{settings}->{channels};
#    my %chans = %$chanlist;
#
#    $self->{irc}->plugin_add('AutoJoin', POE::Component::IRC::Plugin::AutoJoin->new( Channels => \%chans ));
#    $self->{irc}->yield(register => "all");
#    
#    $self->{irc}->yield(
#		connect => {
#                    Nick     => $self->{config}->{settings}->{nick},
#                    Username => $self->{config}->{settings}->{username},
#                    Ircname  => $self->{config}->{settings}->{ircname},
#                    Server   => $self->{config}->{settings}->{server},
#                    Port     => $self->{config}->{settings}->{port},
#                }
#    );
#
#}
#sub irc_connect {
#    my $self = shift;
#    print "Connected: ".$self->{irc}->server_name()."\n";
#}
#
#sub irc_user_join {
#    my ($self, $kernel) = @_[OBJECT, KERNEL];
#    my ($who, $channel, $msg) = @_[ARG0 .. ARG2];
#
#    my ($nick, $hostname) = split(/!/, $who);
#    
#    print "$nick JOINED $channel ($hostname)\n";
#    
#}
#
#sub irc_public {
#    my ($self, $kernel) = @_[OBJECT, KERNEL];
#    my ($who, $where, $msg) = @_[ARG0 .. ARG2];
#    my ($nick, $hostname) = split(/!/,$who);
#    my $channel = $where->[0];
#    
#    
#}
##########################
#### HELPER FUNCTIONS ####
##########################
#sub _check_triggers{
#    my $self = shift;
#    my $msg = shift; ## the IRC message string
#    
#    # Check if there are any autoreply-worthy words in there:
#    #my @trig = grep { $msg =~ /(?i)$_/ } @{ $triggers };
#    
#    
#}
#
#sub _check_cmd {
#    my $self = shift;
#    my $msg = shift; ## the IRC message string
#    
#}

#sub _read_yml{
#    my $self = shift;
#    my $filename = shift || return;
#    my $folder = shift || '';
#
#    $folder = $folder."/" if $folder;
#    
#    $filename = $self->{_lib}."/".$folder.$filename;
#    
#    my $ymlfile = read_file($filename) if (-e $filename);
#    
#    my $ymlvar = Load $ymlfile if ($ymlfile);
#    
#    return $ymlvar if $ymlvar;
#    
#    return 0;
#}
#


#sub _set_lib_path {
#    my $self = shift;
#    my $libpath = shift;
#    $self->{_lib} = $libpath;
#    return $self->{_lib};
#}
#
#sub _get_lib_path {
#    my $self = shift;
#
#    return $self->{_lib};
#}
#


1;