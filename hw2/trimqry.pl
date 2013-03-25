#!/usr/bin/perl -w

my $line = undef;
while ($line = <STDIN>) {
    chomp $line;
    if (not $line =~ /.+\.[IA]/) {
        if ($line =~ /^\.I/) {
            print ".I\n";
        } elsif ($line =~ /^\.W/) {
            print ".W\n";
        } elsif ($line =~ /^\.T/) {
            print ".T\n";
        } elsif ($line =~ /^\.A/) {
            print ".A\n";
        } else {
            print $line, "\n";
        }
    }

}
