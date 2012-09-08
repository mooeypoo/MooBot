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
    
    #print Dumper $plugin_list;
    ## get plugin list:
    if (@$plugin_list) {
        foreach my $plg (@$plugin_list) {
            $plg = "MooBot::Plugin::$plg";
            #print "plg: $plg\n";
            eval "require $plg";
            if ($@) {
                warn "Could not load $plg because: $@";
            } else {
                my $plg_cmd_list = $plg->my_command_list if $plg->can("my_command_list");;

                ## Try to instance the object
                ## (A proper constructor should die() on failure)
                my $plg_obj = $plg->new();
                if ($plg_obj) {
                    my $name = $plg_obj->plg_name || ref $plg_obj;
                    if ($plg_obj) {
                        foreach my $trig (keys $plg_cmd_list) {
                            my $routine = $plg_cmd_list->{$trig}->{method} if $plg_cmd_list->{$trig}->{method} ;
                            ## Now we know about this obj.
                            $self->{plugins}->{$name} = $plg_obj; ## $name;
                            $self->{cmds}->{$trig}->{plugin} = $name;
                            $self->{cmds}->{$trig}->{routine} = $routine;
                        }
                    }
                }
            }
        }
    }
    
    return $self;

    #print Dumper $self->{cmds};
    #print Dumper $self->{plugins};
    
}

sub is_cmd {
    my $self = shift;
    my $txt = shift || return;
    #my $cmdchar = shift || '!';
    
    return $txt if !$self->{cmdchar};
    
    if (index($txt, $self->{cmdchar}) == 0) {
        my $ncmd = substr($txt, 1, length($txt)-1);
        return $ncmd; ##return cmd+params
    }
    return;
}


sub process_cmd {
    my ($self, $phash) = @_;
    
    my @params = split(' ',$phash->{rawmsg});
    my $cmd = shift @params;
    $cmd = $self->is_cmd($cmd);
    if ($cmd) {
#        print "GOT COMMAND TO PROCESS: $cmd\n";
        
        if ($self->{cmds}->{$cmd}) {
            ##insert the general parameters into the params array:
            delete $phash->{rawmsg};
            unshift(@params, $phash);

            my $plg = $self->{plugins}->{$self->{cmds}->{$cmd}->{plugin}};
            my $routinename = $self->{cmds}->{$cmd}->{routine};
            ## check if the routine exists and can be called:
            my $result = $plg->$routinename(@params) if $plg->can($routinename);
            ## if there's any result, return it for later processing:
            return $result;
        }
    }
}

sub set_cmdchar {
    my $self = shift;
    my $cmdchar = shift || return;
    
    $self->{cmdchar} = $cmdchar;
}

sub get_cmdlist {
    my ($self) = shift;
    return $self->{cmds} if $self->{cmds};
}

1;