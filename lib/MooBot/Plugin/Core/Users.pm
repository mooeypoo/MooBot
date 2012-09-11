#!/usr/bin/perl

package MooBot::Plugin::Core::Users;

use strict; use warnings;

# MooBot::Plugin::Core::Users
# --------------
# Handles user functionality
# --------------
use MooBot::Utils;

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
use Scalar::Util qw(looks_like_number);
use POSIX qw(strftime);

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
        $c->{login}->{syntax} = "login [user] [pass]";
        $c->{login}->{desc} = "Login to gain access to the bot.";

    $c->{adduser}->{method} = "do_user_add";
        $c->{adduser}->{syntax} = "adduser [user] [pass] ([access_level])";
        $c->{adduser}->{desc} = "Add a user to the bot. Must be a Bot Operator to do that. If 'access_level' is empty, the bot will add the user as 'USER'. Access_level must be numerical [USER=10, CONTRIBUTOR=100, BOTOP=500]";

    $c->{edituser}->{method} = "do_user_edit";
        $c->{edituser}->{syntax} = "edituser [username] [param1:value1] ([param2:value2]) ...";
        $c->{edituser}->{desc} = "Edit user details. Available params: username:newuser pass:newpassword";

    $c->{userinfo}->{method} = "do_user_info";
        $c->{userinfo}->{syntax} = "userinfo [username]";
        $c->{userinfo}->{desc} = "Retrives user info from the bot database.";
    
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
    #print Dumper $self->{users};
    
    $self->{access_levels} = {
            9999 => 'BOT ADMIN',
            500 => 'BOT OPERATOR',
            100 => 'CONTRIBUTOR',
            10 => 'USER',
        };
    
    return $self;
}

sub on_bot_init {
    my ($self, @params) = @_;
    print "I'm the MooBot::Plugin::Core::Users plugin, and I just ran 'on_bot_init'!\n";
}

sub do_user_login {
    my ($self, $sysparams) = @_;
    my @syntax = qw/username pass/;
    my @required = qw/username pass/;
    my ($params, $r, @reply);

    #print Dumper @fullparams;
    my @fullparams = @{$sysparams->{params}};

#    my $sysparams = shift @fullparams;

    unless ($sysparams->{location}) { ## if there's no $channel, it's a pvt chat
        
        $r = {
            'where' => $sysparams->{nick},
            'type' => $sysparams->{type},
        };

        for my $synt (@syntax) {
            $params->{$synt} = shift @fullparams;
        }

        print Dumper $params;
        for my $req (@required) {
            unless (defined $params->{$req}) {
                push @reply, "Missing parameter: $req.";
                return pushreply($r, @reply);
            }
        }
        ### Check if username is already logged in from this hostname:
        if ($self->{loggedin}->{$sysparams->{'hostname'}}) {
            push @reply, "You're already logged in.";
            return pushreply($r, @reply);
        }
        ##check if username exists:
        unless ($self->{users}->{$params->{'username'}}) {
            push @reply, "Username not found.";
            return pushreply($r, @reply);
        }
        ##check if pass is right:
        unless (pwd_compare($params->{'pass'},$self->{users}->{$params->{'username'}}->{pass})) {
            push @reply, "Wrong password.";
            return pushreply($r, @reply);
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
        
        push @reply, "Login successful.";
        return pushreply($r, @reply);
    } else {
    
        push @reply, "Don't do this in public!";
        return pushreply($r, @reply);
    }
}

sub do_user_add {
    my ($self, $sysparams) = @_;
    my @syntax = qw/username pass access_level email/;
    my @required = qw/username pass/;
    my ($params, $r, @reply);

    my @fullparams = @{$sysparams->{params}};
    #my $sysparams = shift @fullparams;
    
    $r = {
          'type' => $sysparams->{type},
          'where' => $sysparams->{nick},
         };
    
    $r->{'where'} = $sysparams->{location} if $sysparams->{location};

        for my $synt (@syntax) {
            $params->{$synt} = shift @fullparams;
        }
        for my $req (@required) {
            unless ($params->{$req}) {
                push @reply, "Missing parameter: $req.";
                return pushreply($r, @reply);
            }
        }
        ### Check if username has sufficient auth:
        unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP)) {
            ## already logged in
            push @reply, "Unauthorized.";
            return pushreply($r, @reply);
        }
        
        
        my $newuser;
        
        
        if (looks_like_number($params->{access_level}) and $self->check_auth($sysparams->{'hostname'}, $params->{'access_level'}+10)) {
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
            $self->{users} = {$params->{'username'} => $newuser};
        }
        
        ##resave the yml file:
        save_yml($self->{users},'users.yml',$self->{my_path});

        push @reply, "User '".$params->{username}."' added with access level ".$newuser->{access_level};
        return pushreply($r, @reply);
}


sub do_user_edit {
    my ($self, $sysparams) = @_;
    my ($params, $r, @reply);

    #my $sysparams = shift @fullparams;
    my @fullparams = @{$sysparams->{params}};

    $r = {
          'type' => $sysparams->{type},
          'where' => $sysparams->{nick},
         };
    $r->{'where'} = $sysparams->{location} if $sysparams->{location};

    unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP)) {
        push @reply, "Log in first.";
        return pushreply($r, @reply);
    }

    ## break apart params:
    $params->{username} = shift @fullparams;
    unless (@fullparams) {
        push @reply, "Expecting parameters [param:value] to edit.";
        return pushreply($r, @reply);
    }

    foreach my $p (@fullparams) {
        ## expect 'param:value'
        my @pair = split(':',$p);
        unless ($pair[0] eq 'username' or $pair[0] eq 'user') {
            $pair[0] = 'pass' if $pair[0] eq 'password';
            $pair[0] = 'access_level' if $pair[0] eq 'level';
            $params->{$pair[0]} = $pair[1];
        }
    }
    ## check if user exists:
    my $ruser;
    $ruser = get_user($params->{username});
    unless ($ruser) {
        push @reply, "Couldn't find user '".$params->{username}."'";
        return pushreply($r, @reply);
    }
    
    my $chself =0;
    ### Check if username can edit the requested user:
    unless ($self->check_auth($sysparams->{'hostname'},AUTH_BOTOP) and $self->check_auth($sysparams->{'hostname'},$ruser->{access_level}+100)) {
        ## if the user is trying to edit themselves:
        if ($self->{loggedin}->{$sysparams->{'hostname'}} eq $ruser->{'hostname'} ) {
            $chself = 1;
        } else {
            ##otherwise, unauthorized:
            push @reply, "Unauthorized.";
            return pushreply($r, @reply);
        }
    }
    
    ## go over params to change:
    $ruser->{pass} = pwd_encrypt($params->{'pass'}) if ($params->{'pass'});
    if (looks_like_number($params->{'access_level'})) {
        $ruser->{access_level} = $params->{'access_level'} unless ($chself);
    }
    ## save to $self->{users} hash:
    $self->{users}->{$params->{username}} = $ruser;
    
    ##re-save yml:
    save_yml($self->{users},'users.yml',$self->{my_path});

    push @reply, "User".$params->{username}." changed successfully.";
    return pushreply($r, @reply);

}

sub do_user_info {
    my $self = shift;
    my $sysparams = shift;
    my ($r, $rusername, @reply);

    my @params = @{$sysparams->{params}};
    
    my $swhere = $sysparams->{nick};
    $swhere = $sysparams->{location} if $sysparams->{location};
    $r = {
          'type' => $sysparams->{type},
          'where' => $swhere,
         };
    

    $rusername = $self->get_user($params[0]);
    
    unless ($rusername) {
        push @reply, "Username '".$params[0]."' not recognized.";
        return pushreply($r, @reply);
    }
    
#    my (@responses);
#    my %r1 = %r; my %r2 = %r; my %r3 = %r; my %r4 = %r;
#    $r1{'text'} = "Username: ".$rusername->{username};
    push @reply, "Username: ".$rusername->{username};
    
    my $alevel = "UNKNOWN";
    $alevel = $self->{access_levels}->{$rusername->{access_level}} if $self->{access_levels}->{$rusername->{access_level}};

    push @reply, "Access level: ".$alevel;
    push(@reply, "Last login: ".strftime("%Y-%m-%d %H:%M:%S",localtime($rusername->{last_login}))) if $rusername->{last_login};
    push(@reply, "Last known nickname: ".$rusername->{last_nick}) if $rusername->{last_nick};

    return pushreply($r, @reply);
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
    
    return $self->{users}->{$username} if ($self->{users}->{$username}); 
}

sub get_logged_users {
    my $self = shift;
    return $self->{loggedin};
}

1;