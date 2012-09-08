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

sub on_bot_init {
    my ($self, @params) = @_;
    print "I'm the MooBot::Core::Users plugin, and I just ran 'on_bot_init'!\n";
}

sub do_user_login {
    my ($self, @params) = @_;
    
    #### process..
    #print Dumper @params;
    return "I just did user login\n";
}

sub do_user_add {
    my ($self, @params) = @_;

    print Dumper @params;
     return 'i just did user add';
}

1;