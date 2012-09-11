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
    my ($self, $params) = @_;
    
    print "--------\n-------\n";
    print "SPEAK SUB: \n";
    print Dumper $params;
    print "--------\n";

    my $err = 0;
    
    my @lines = @{$params->{reply}} if ($params->{reply});
    
    ##verify all details are there on the $speak_hash:
    my $type = $params->{type} ? $params->{type} : 'privmsg';
    my $loc = $params->{where} if $params->{where};
    $err=1 if (!$params->{where});
    
    unless ($err > 0) {
        foreach my $line (@lines) {
            $self->{irc}->yield($type => $loc, $line);
        }
    }
    
}

#sub speak {
#    my $self= shift;
#    my $speak_hash = shift || return;
#    
#    
#    my $err =0;
#
#    if (ref $speak_hash eq 'ARRAY') { ## MULTIPLE REPLIES
#        foreach my $line_hash (@$speak_hash) {
#            my $type = $line_hash->{type} ? $line_hash->{type} : 'privmsg';
#            $err=1 if (!$line_hash->{where}) or (!$line_hash->{text});
#            
#            my $loc = $line_hash->{where} if $line_hash->{where};
#            my $reply = $line_hash->{text} if $line_hash->{text};
#            
#            ## speak:
#            unless ($err) {
#                $self->{irc}->yield($type => $loc, $reply);
#            }
#        }
#    } elsif (ref $speak_hash eq 'HASH') { ## SINGLE REPLY
#        my $type = $speak_hash->{type} ? $speak_hash->{type} : 'privmsg';
#        $err=1 if (!$speak_hash->{where}) or (!$speak_hash->{text});
#            
#        my $loc = $speak_hash->{where} if $speak_hash->{where};
#        my $reply = $speak_hash->{text} if $speak_hash->{text};
#            
#        ## speak:
#        unless ($err) {
#            $self->{irc}->yield($type => $loc, $reply);
#        }
#    }
#
#    
#}



1;