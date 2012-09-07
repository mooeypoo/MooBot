#!/usr/bin/perl

use File::Basename 'dirname';
use File::Spec::Functions qw(catdir splitdir);
use POE;

## Include MooBot/bin for specific packages:
my $lib;
BEGIN {
    my @base = ( splitdir( dirname(__FILE__) ) );
    $lib  = join '/', @base, 'lib';
    push(@INC, $lib);
}

use MooBot;

my $bot = MooBot->new($lib, "config.yml");

    # Run the bot until it is done.
    $poe_kernel->run();

exit;