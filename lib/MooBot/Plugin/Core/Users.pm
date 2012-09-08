#!/usr/bin/perl

package MooBot::Plugin::Core::Users;
# MooBot::Plugin::Core::Users
# --------------
# Handles user functionality
# --------------
use strict; use warnings;
use Carp qw/ confess /;
use Data::Dumper;

## ALL PLUGINS MUST HAVE THESE TWO ROUTINES:
sub plg_name { 'Core::Users' }
sub my_command_list {
    my $c;
    
    $c->{login}->{method} = "do_user_login";
    $c->{adduser}->{method} = "do_user_add";
    return $c;
}
############################################

sub new {
    my $class = shift;
    my $self = {};

    bless $self, $class;
    
    ##read users.yml
}

sub do_user_login {
    my ($self, @params) = shift;
    
    #### process..
    print Dumper @params;
    return 'I just did user login';
}

sub do_user_add {
    my ($self, @params) = shift;

    print Dumper @params;
     return 'i just did user add';
}

1;