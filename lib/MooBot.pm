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
    my $conf_object = shift;
    
    bless $self, $class;
    
    ## read config file:
    $self->{config} = $conf_object;

    $self->{irc} = POE::Component::IRC::State->spawn();

    return $self;
}


sub speak {
    my $self= shift;
    my $speak_hash = shift;
    
    my $err =0;

    if (ref $speak_hash eq 'ARRAY') { ## MULTIPLE REPLIES
        foreach my $line_hash (@$speak_hash) {
            my $type = $line_hash->{type} ? $line_hash->{type} : 'privmsg';
            $err=1 if (!$line_hash->{where}) or (!$line_hash->{text});
            
            my $loc = $line_hash->{where} if $line_hash->{where};
            my $reply = $line_hash->{text} if $line_hash->{text};
            
            ## speak:
            unless ($err) {
                $self->{irc}->yield($type => $loc, $reply);
            }
        }
    } elsif (ref $speak_hash eq 'HASH') { ## SINGLE REPLY
        my $type = $speak_hash->{type} ? $speak_hash->{type} : 'privmsg';
        $err=1 if (!$speak_hash->{where}) or (!$speak_hash->{text});
            
        my $loc = $speak_hash->{where} if $speak_hash->{where};
        my $reply = $speak_hash->{text} if $speak_hash->{text};
            
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