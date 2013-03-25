#!/usr/bin/bash
./remove_stopwords.pl < query.stemmed > query.clean
tail -n +2 query.clean | paste query.clean - > query.bigram.t
./trimqry.pl < query.bigram.t > query.bigram.tt
# rm query.bigram.t
./replacespace.pl < query.bigram.tt > query.bigram
# rm query.bigram.tt
./make_hist.prl < query.bigram > query.bigram.hist
