#!/usr/bin/perl -w
use FileHandle;

my $DIR = ".";
my $stoplist = "$DIR/common_words.stemmed";
my $corps = "$DIR/cacm.stemmed";

my %stoplist_hash = ();

my $stoplist_fh = new FileHandle $stoplist, "r" or die "Failed $stoplist";
my $corps_fh = new FileHandle $corps, "r" or die "Failed $corps";

my $line = undef;
while (defined($line = <$stoplist_fh>)) {
    chomp $line;
    $stoplist_hash{$line} = 1;
}
my $word = undef;
while (defined($word = <$corps_fh>)) {
    chomp $word;
    if ($word =~ /^[^\.]/ and !exists $stoplist_hash{$word}) {
        print $word, "\n";
    }
}

