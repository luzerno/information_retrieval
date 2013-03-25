#!/usr/bin/bash
./remove_stopwords.pl < cacm.stemmed > cacm.clean
tail -n +2 cacm.clean | paste cacm.clean - > cacm.bigram.t
./trimcorp.pl < cacm.bigram.t > cacm.bigram.tt
# rm cacm.bigram.t
./replacespace.pl < cacm.bigram.tt > cacm.bigram
# rm cacm.bigram.tt
./make_hist.prl < cacm.bigram > cacm.bigram.hist


