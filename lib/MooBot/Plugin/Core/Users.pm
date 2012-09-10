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
use Scalar::Util qw(looks_like_number);

use Carp qw/ confess /;
use Data::Dumper;
use YAML::XS;
use File::Slurp;

## Defining constants:
use constant {
    AUTH_ADMIN => 9999,
    AUTH_BOTOP => 500,
    AUTH_CONTRIBUTOR => 100,
    AUTH_USER => 10,
};


## ALL PLUGINS MUST HAVE THESE TWO ROUTINES:
sub plg_name { 'Core::Users' }
sub my_command_list {
    my $c;
    
    $c->{login}->{method} = "do_user_login";
    $c->{adduser}->{method} = "do_user_add";
    $c->{edituser}->{method} = "do_user_edit";
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
        ### Check if username is already logged in from this hostname:
        if ($self->{loggedin}->{$sysparams->{'hostname'}}) {
            ## already logged in
            $r->{text} = "You're already logged in.";
            return $r;
        }
        ##check if username exists:
        unless ($self->{users}->{$params->{'username'}}) {
            $r->{text} = "Couldn't find the user.";
            return $r;
        }
        ##check if pass is right:
        unless (pwd_compare($params->{'pass'},$self->{users}->{$params->{'username'}}->{pass})) {
            $r->{text} = "Couldn't find the user.";
            return $r;
        }
        ## all good, add to hash:
        $self->{loggedin}->{$sysparams->{'hostname'}} = {
                'access_level' => $self->{users}->{$params->{'username'}}->{access_level},
                'hostname' => $sysparams->{'hostname'},
                'nick' => $sysparams->{'nick'},
                'username' => $params->{'username'},
            };

        ##update users:
        $self->{users}->{$params->{'username'}}->{last_login} = time();
        $self->{users}->{$params->{'username'}}->{last_nick} = $sysparams->{nick};
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
    my ($self, @fullparams) = @_;
    my @syntax = qw/username pass access_level email/;
    my @required = qw/username pass/;
    my ($params, $r);

    my $sysparams = shift @fullparams;
    
    $r->{'type'} = $sysparams->{type};
    $r->{'where'} = $sysparams->{nick};
    $r->{'where'} = $sysparams->{location} if $sysparams->{location};

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
        ### Check if username has sufficient auth:
        unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP)) {
            ## already logged in
            $r->{text} = "You're not authorized to do this.";
            return $r;
        }
        
        
        my $newuser;
        if (looks_like_number($params->{'access_level'}) and $self->check_auth($sysparams->{'hostname'}, $params->{'access_level'}+10)) {
            $newuser->{access_level} = $params->{access_level};
        } else {
            $newuser->{access_level} = 10;
        }
        $newuser->{username} = $params->{'username'} if $params->{'username'};
        $newuser->{pass} = pwd_encrypt($params->{'pass'});

        ## Add to users:
        if ($self->{users}) {
            $self->{users}->{$params->{'username'}} = $newuser;
        } else {
            $self->{users} = ($params->{username} => $newuser);
        }
        
        print "self users\n";
        print Dumper $self->{users};
        
#        $self->{users}->{$newuser->{username}} = $newuser;
        
        ##resave the yml file:
        save_yml($self->{users},'users.yml',$self->{my_path});

        $r->{text} = "User '".$params->{username}."' added with access level ".$newuser->{access_level};
        return $r;
}


sub do_user_edit {
    my ($self, @fullparams) = @_;
    my ($params, $r);

    my $sysparams = shift @fullparams;
    
    $r->{'type'} = $sysparams->{type};
    $r->{'where'} = $sysparams->{nick};
    $r->{'where'} = $sysparams->{location} if $sysparams->{location};

    unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP)) {
        ## already logged in
        $r->{text} = "You're not authorized to do this.";
        return $r;
    }

    ## break apart params:
    $params->{username} = shift @fullparams;
    unless (@fullparams) {
        $r->{text} = "Expecting parameters [param:value] to edit.";
        return $r;
    }

    foreach my $p (@fullparams) {
        ## expect 'param:value'
        my @pair = split(':',$p);
        $pair[0] = 'username' if $pair[0] eq 'user';
        $pair[0] = 'pass' if $pair[0] eq 'password';
        $pair[0] = 'access_level' if $pair[0] eq 'level';
        $params->{$pair[0]} = $pair[1];
    }
    ## check if user exists:
    $ruser = get_user($params->{username});
    unless ($ruser) {
        $r->{text} = "Couldn't find user '".$params->{username}."'";
        return $r;
    }
    
    $chself =0;
    ### Check if username can edit the requested user:
    unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP) and $self->check_auth($sysparams->{'hostname'},$ruser->{}->{access_level}+100) {
        ## if the user is trying to edit themselves:
        if ($self->{loggedin}->{$sysparams->{'hostname'} eq $ruser->{'hostname'} ) {
            $chself = 1;
        } else {
            ##otherwise, unauthorized:
            $r->{text} = "You're not authorized to do this.";
            return $r;
        }
    }
    
    ## go over params to change:
    $ruser->{pass} = pwd_encrypt($params->{'pass'}) if ($params->{'pass'});
    if (looks_like_number($params->{'access_level'}) {
        $ruser->{access_level} = $params->{'access_level'} unless ($chself);
    }
    

}

sub check_auth {
    my $self = shift;
    my $hostname = shift || return;
    my $req_access = shift;
    
    return 1 if (defined $self->{loggedin}->{$hostname}) and ($self->{loggedin}->{$hostname}->{access_level} >= $req_access);

    return;
}

sub get_user {
    my $self = shift;
    my $username = shift;
    
    return $self->{users}->{$username} if $self->{users}->{$username}; 
}

sub get_logged_users {
    my $self = shift;
    return $self->{loggedin};
}

1;