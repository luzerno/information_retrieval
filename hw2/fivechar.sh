#!/usr/bin/bash
./remove_stopwords.pl < cacm.stemmed > cacm.clean
./remove_stopwords.pl < query.stemmed > query.clean
./5char.pl < cacm.clean > cacm.five
./5char.pl < query.clean > query.clean
./make_hist.prl < cacm.five > cacm.five.hist
./make_hist.prl < query.five > query.five.hist
