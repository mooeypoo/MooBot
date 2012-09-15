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
    my $self = shift;
    my $fparams = shift;
    
    print "--------\n-------\n";
    print "SPEAK SUB: \n";
    print Dumper $fparams;
    print "--------\n";

    my $params;
    if (ref $fparams eq 'ARRAY') {
        $params = @$fparams[0];
    } else {
        $params = $fparams;
    }

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




1;