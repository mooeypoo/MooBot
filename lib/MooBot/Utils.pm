#!/usr/bin/perl
package MooBot::Utils;

use strict;
use warnings;
use Carp;

use Crypt::Eksblowfish::Bcrypt ;
use YAML::XS;
use File::Slurp;
use File::Open qw(fopen fopen_nothrow fsysopen fsysopen_nothrow);
use Term::ANSIColor qw(:constants);
use DateTime;
use Data::Dumper;

use Exporter;

our @ISA = qw( Exporter );
our @EXPORT_OK = qw/
    save_yml
    read_yml
    pwd_encrypt
    pwd_compare
    pushreply
/;
our @EXPORT = @EXPORT_OK;

sub save_yml{
	my $ymlhash = shift || return;
	my $ymlfilename = shift || return;
        my $ymlfolder = shift || '';
	
	my $yaml = ();
	
	$yaml = Dump $ymlhash;  ## YAML
	
        my $fullpath;
        
        if ($ymlfolder) {
            $fullpath = $ymlfolder."/".$ymlfilename ;
        } else {
            $fullpath = $ymlfilename;
        }
        
	write_file($fullpath, $yaml) if $yaml;
    
}
sub read_yml {
    my $filename = shift || return;
    my $folder = shift || '';

    $filename = $folder."/".$filename if $folder;
    
    my $ymlfile = read_file($filename) if (-e $filename);
    print "\n$filename\n";
    my $ymlvar = Load $ymlfile if ($ymlfile);
    
    return $ymlvar if $ymlvar;
    
    return 0;
}





sub pwd_encrypt {
    my $plainpass = shift || return;

    my $salt = Crypt::Eksblowfish::Bcrypt::en_base64( join '', map { chr int rand 256 } 1 .. 16 );
    my $cost = '08';
    my $bsettings = join '', '$2a$', $cost, '$', $salt;

    return Crypt::Eksblowfish::Bcrypt::bcrypt($plainpass, $bsettings);
}

sub pwd_compare {
    my $plainpass = shift || return;
    my $hashedpass = shift || return;
    
    return 1 if $hashedpass eq Crypt::Eksblowfish::Bcrypt::bcrypt($plainpass, $hashedpass);
    
    return 0; ## FALSE
}

sub pushreply {
    my $hashref = shift;
    my @replies = @_;
    
    print "---\n---\n pushreply\n";
    print Dumper @replies;
    print "---\n---\n\n\n";

    $hashref->{reply} = \@replies;
    
    return $hashref;
}
