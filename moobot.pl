#!/usr/bin/perl

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
use POE;

use Data::Dumper;

## Include MooBot/bin for specific packages:
my $lib;
BEGIN {
    my @base = ( splitdir( dirname(__FILE__) ) );
    $lib  = join '/', @base, 'lib';
    push(@INC, $lib);
}

use MooBot;
use MooBot::Utils;
use MooBot::Plugin; 

my $config = read_yml("config.yml","$lib/config");
my $bot = MooBot->new($lib, $config);
my $plugins = MooBot::Plugin->new($config->{plugins});

print Dumper $plugins->{cmds};

#POE::Session->create(
#    object_states => [
#        $self => {
#            _start     => 'irc_start',
#            irc_001    => 'irc_connect',
#            irc_join    => 'irc_user_join',
#            #irc_public => 'irc_public',
#            #irc_msg => 'irc_pvtmsg',
#        },
#    ],
#);



# Run the bot
$poe_kernel->run();

exit;