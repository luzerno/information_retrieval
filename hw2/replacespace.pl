#!/usr/bin/perl -w

my $line = undef;
my $newline = undef;

while ($line = <STDIN>) {
    chomp $line;
    $line =~ s/\s/\+/g;
    print $line, "\n";
}
