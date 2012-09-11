#!/usr/bin/perl

package MooBot::Plugin::Core::Triggers;
# MooBot::Plugin::Core::Triggers
# --------------
# Handles 'autoreplies' with randomness built-in.
# --------------
use MooBot::Utils;

use strict; use warnings;
use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
use Carp qw/ confess /;
use YAML::XS;
use File::Slurp;

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
    
    ## read autoreply file:
    my @base = ( splitdir( dirname(__FILE__) ) );
    $self->{my_path}  = './'.join ('/', @base);
    $self->{autoreplies} = read_yml("autoreplies.yml",$self->{my_path});

    for my $key (keys %{ $self->{autoreplies} }) {
        push(@{$self->{triggers}}, $key);
    }

    return $self;
}

sub on_bot_public {
    my ($self, $params) = @_;

    my @reply;

    my $msg = $params->{rawmsg} if $params->{rawmsg};

    my @trig = grep { $msg =~ /(?i)$_/ } @{ $self->{triggers} };
    if (@trig) {
        
        my $num = rand(@{$self->{autoreplies}->{$trig[0]}}); 
        my $reply = $self->{autoreplies}->{$trig[0]}->[$num];

        my $nick = $params->{nick};
        my $channel = $params->{location};
        
        $reply =~ s/%nick%/$nick/ if ($reply);
        $reply =~ s/%chan%/$channel/ if ($reply);

        my $r = {
              'type' => $params->{type},
              'where' => $params->{location},
             };
        
        if ($reply =~ /^\/me/) {
            $reply =~ s/^\/me //;
            $reply = "ACTION ".$reply;
            $r->{'type'} = "ctcp";
        }

        push @reply, $reply;
        return pushreply($r, @reply);
    }
}



sub read_autoreplies {
    my $self = shift;
    $self->{autoreplies} = read_yml("autoreplies.yml",$self->{my_path});
}

sub resave_autoreplies {
    my $self = shift;
    save_yml($self->{autoreplies},'users.yml',$self->{my_path});

}

1;