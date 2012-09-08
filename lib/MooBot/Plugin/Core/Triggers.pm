#!/usr/bin/perl

package MooBot::Triggers;
use base MooBot;
use strict; use warnings;
use Carp qw/ confess /;

sub new{
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

1;