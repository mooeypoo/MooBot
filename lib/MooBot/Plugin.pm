#!/usr/bin/perl

package MooBot::Plugin;
# MooBot::Plugin
# --------------
# Sets up basic functionality and hierarchy of MooBot plugins
# --------------
use strict; use warnings;
use Carp qw/ confess /;
use Data::Dumper;

## ALL PLUGINS MUST HAVE THESE TWO ROUTINES:
sub plg_name { 'Plugin' }
sub my_command_list {
    ##output a hash:
    ## $result->{trigger}->{method}
}
############################################

sub new {
    my $class = shift;
    my $plugin_list = shift;
    my $self = {};

    bless $self, $class;
    
    ## insert the core plugins:
    unshift(@$plugin_list,"Core::Triggers");
    unshift(@$plugin_list,"Core::Users");
    
    print Dumper $plugin_list;
    ## get plugin list:
    if (@$plugin_list) {
        foreach my $plg (@$plugin_list) {
            $plg = "MooBot::Plugin::$plg";
            print "plg: $plg\n";
            eval "require $plg";
            if ($@) {
                warn "Could not load $plg because: $@";
            } else {
                my $plg_cmd_list = $plg->my_command_list;
              
                ## Try to instance the object
                ## (A proper constructor should die() on failure)
                my $plg_obj = $plg->new();
                my $name = $plg_obj->plg_name || ref $plg_obj;
                if ($plg_obj) {
                    foreach my $trig (keys $plg_cmd_list) {
                        print "\n";
                        print Dumper $trig;
                        print "\n";
                        my $routine = $trig->{method} if $trig->{method};
                        ## Now we know about this obj.
                        $self->{cmds}->{$trig}->{'plugin'} = $name;
                        $self->{cmds}->{$trig}->{'routine'} = $routine;
                    }
                }
            }
        }
    }

    print Dumper $self->{cmds};
    ## get the core plugins:
    
}

sub process_cmd {
    my ($self, @params) = @_;
    
    my $cmd = shift @params;
    
    if ($self->{cmds}->{$cmd}) {
        ## command exists. check if object exists:
        my $plgname = $self->{cmds}->{$cmd}->{plugin};
        my $routinename = $self->{cmds}->{$cmd}->{routine};
        my $result = $plgname->$routinename(@params) if $plgname->can($routinename);
        return $result;
    }
}

1;