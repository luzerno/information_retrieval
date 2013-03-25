#!/usr/bin/perl -w
use strict;
use FileHandle;

my $DIR = ".";

my $line = undef;
my @words = ();

while (defined($line = <STDIN>)) {
    chomp $line;
    if ($line =~ /^\.[IWKTA]/) {
        if (scalar @words > 0) {
            &process;
        }
        print $line, "\n";
    } else {
        push @words, $line;
    }
}

sub process {
    my $str = "_" . (join "_", @words) . "_";
    
    for (my $i = 0; $i < (length $str) - 4; $i++) {
        print (substr $str, $i, 5);
        print "\n";
    }

    @words = ();
}
