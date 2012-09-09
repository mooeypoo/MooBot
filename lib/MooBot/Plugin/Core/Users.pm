#!/usr/bin/perl

package MooBot::Plugin::Core::Users;
use base MooBot::Plugin;


use strict; use warnings;

# MooBot::Plugin::Core::Users
# --------------
# Handles user functionality
# --------------
use MooBot::Utils;

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);

use Carp qw/ confess /;
use Data::Dumper;
use YAML::XS;
use File::Slurp;
#use File::Open qw(fopen fopen_nothrow fsysopen fsysopen_nothrow);


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
    #my @args = shift;
    my $self = {};

    bless $self, $class;
    
    my @base = ( splitdir( dirname(__FILE__) ) );
    $self->{my_path}  = './'.join ('/', @base);
    $self->{users} = read_yml("users.yml",$self->{my_path});
    print Dumper $self->{users};
    
    return $self;
}

sub on_bot_init {
    my ($self, @params) = @_;
    print "I'm the MooBot::Plugin::Core::Users plugin, and I just ran 'on_bot_init'!\n";
}

sub do_user_login {
    my ($self, @fullparams) = @_;
    my @syntax = qw/username pass/;
    my @required = qw/username pass/;

    #print Dumper @fullparams;

    my ($params, $r);
    my $sysparams = shift @fullparams;
            #'nick' => $nick,
            #'type' => 'privmsg'/'ctcp',
            #'location' => $channel/none,
            #'hostname' => $hostname,

    unless ($sysparams->{location}) { ## if there's no $channel, it's a pvt chat
        
        $r = {
            'where' => $sysparams->{nick},
            'type' => $sysparams->{type},
        };

        for my $synt (@syntax) {
            $params->{$synt} = shift @fullparams;
        }
        for my $req (@required) {
            unless ($params->{$req}) {
                #return output("Missing parameter: $req.","privmsg","user");
                $r->{text} = "Missing parameter: $req.";
                return $r;
            }
        }

        print "Params:\n";
        print Dumper $params;
        print "---\nSysparams:\n";
        print Dumper $sysparams;

        ### Check if username is already logged in from this hostname:
        if ($self->{loggedin}->{$sysparams->{'hostname'}}) {
            ## already logged in
            $r->{text} = "You're already logged in.";
            return $r;
        }
        ##check if username exists:
        unless ($self->{users}->{$params->{username}}) {
            $r->{text} = "Couldn't find the user.";
            return $r;
        }
        ##check if pass is right:
        unless (pwd_compare($params->{pass},$self->{users}->{$params->{username}}->{pass})) {
            $r->{text} = "Couldn't find the user.";
            return $r;
        }
        ## all good, add to hash:
        $self->{loggedin}->{$sysparams->{hostname}} = {
                'access_level' => $self->{users}->{$params->{username}}->{access_level},
                'hostname' => $sysparams->{hostname},
                'nick' => $sysparams->{nick},
                'username' => $params->{username},
            };

        ##update users:
        $self->{users}->{$params->{username}}->{last_login} = time();
        $self->{users}->{$params->{username}}->{last_nick} = $sysparams->{nick};
        save_yml($self->{users},'users.yml',$self->{my_path});
        
        $r->{text} = "Login successful.";
        #print Dumper $self->{loggedin};
        return $r;
    }
    
    #### process..
    #print Dumper @params;
    $r->{text} = "Some unknown error occured.";
}

sub do_user_add {
    my ($self, @params) = @_;

    print Dumper @params;
     return 'i just did user add';
}

sub _logged_users {
    
}

1;