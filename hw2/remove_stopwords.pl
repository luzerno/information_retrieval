#!/usr/bin/perl -w
use FileHandle;

my $DIR = ".";
my $stoplist = "$DIR/common_words.stemmed";

my %stoplist_hash = ();

my $stoplist_fh = new FileHandle $stoplist, "r" or die "Failed $stoplist";

my $line = undef;
while (defined($line = <$stoplist_fh>)) {
    chomp $line;
    $stoplist_hash{$line} = 1;
}
my $word = undef;
while (defined($word = <STDIN>)) {
    chomp $word;
    # if (($word =~ /^[^\.]/ or $word =~ /^\.I/)and !exists $stoplist_hash{$word}) {
    if (!exists $stoplist_hash{$word}) {
        print $word, "\n";
    }
}

