#!/usr/bin/perl -w

my $line = undef;
while ($line = <STDIN>) {
    chomp $line;
    if (not $line =~ /.+\.I/) {
        if ($line =~ /^\.I/) {
            print ".I\n";
        } else {
            print $line, "\n";
        }
    }

}
