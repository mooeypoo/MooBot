#!/usr/bin/perl

package MooBot::Plugin::Core::Triggers;
use base MooBot;
use strict; use warnings;
use Carp qw/ confess /;

## ALL PLUGINS MUST HAVE THESE TWO ROUTINES:
sub plg_name { 'Core::Triggers' }
sub my_command_list {
    my $c;
    
#    $c->{login}->{method} = "do_user_login";
#    $c->{adduser}->{method} = "do_user_add";
    return $c;
}
############################################



sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return;
}

1;