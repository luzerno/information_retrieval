#!/usr/bin/perl -w
use FileHandle;

my $DIR = ".";
my $stoplist = "$DIR/common_words.stemmed";
my $query = "$DIR/query.stemmed";

my %stoplist_hash = ();

my $stoplist_fh = new FileHandle $stoplist, "r" or die "Failed $stoplist";
my $query_fh = new FileHandle $query, "r" or die "Failed $query";

my $line = undef;
while (defined($line = <$stoplist_fh>)) {
    chomp $line;
    $stoplist_hash{$line} = 1;
}
my $word = undef;

while (defined($word = <$query_fh>)) {
    chomp $word;
    if ($word =~ /^[^\.]/ and !exists $stoplist_hash{$word}) {
        print $word, "\n";
    }
}
