#!/usr/bin/perl -w

use strict;

use Carp;
use FileHandle;

##########################################################
##  VECTOR1
##
##  Usage:   vector1     (no command line arguments)
##
##  The function &main_loop below gives the menu for the system.
##
##  This is an example program that shows how the core
##  of a vector-based IR engine may be implemented in Perl.
##
##  Some of the functions below are unimplemented, and some
##  are only partially implemented. Suggestions for additions
##  are given below and in the assignment handout.
##
##  You should feel free to modify this program directly,
##  and probably use this as a base for your implemented
##  extensions.  As with all assignments, the range of
##  possible enhancements is open ended and creativity
##  is strongly encouraged.
##########################################################


############################################################
## Program Defaults and Global Variables
############################################################

my $DIR  = ".";
my $HOME = ".";

# my $token_docs = "$DIR/cacm";           # tokenized cacm journals
# my $corps_freq = "$DIR/cacm";           # frequency of each token in the journ.
# my $stoplist   = "$DIR/common_words";   # common uninteresting words
# my $titles     = "$DIR/titles.short";   # titles of each article in cacm 
# my $token_qrys = "$DIR/query";          # tokenized canned querys
# my $query_freq = "$DIR/query";          # frequency of each token in the querys
# my $query_relv = "$DIR/query\.rels";    # relevance of a journal entry to a
#                                         #  given query
# 
# # these files are created in your $HOME directory
# 
# my $token_intr = "$HOME/interactive";    # file created for interactive queries
# my $inter_freq = "$HOME/interactive";    # frequency of each token in above


my $token_docs = "";           # tokenized cacm journals
my $corps_freq = "";           # frequency of each token in the journ.
my $stoplist   = "";   # common uninteresting words
my $titles     = "";   # titles of each article in cacm 
my $token_qrys = "";          # tokenized canned querys
my $query_freq = "";          # frequency of each token in the querys
my $query_relv = "";    # relevance of a journal entry to a
#  given query

# these files are created in your $HOME directory

my $token_intr = "";    # file created for interactive queries
my $inter_freq = "";    # frequency of each token in above

# @doc_vector
#
#   An array of hashes, each array index indicating a particular document's
#   weight "vector". 

my @doc_vector = ( );

# @qry_vector
#
#   An array of hashes, each array index indicating a particular query's
#   weight "vector".

my @qry_vector = ( );

# %docs_freq_hash
#
# associative array which holds <token, frequency> pairs where
#
#   token     = a particular word or tag found in the cacm corpus
#   frequency = the total number of times the token appears in
#               the corpus.

my %docs_freq_hash = ( );    

# %corp_freq_hash
#
# associative array which holds <token, frequency> pairs where
#
#   token     = a particular word or tag found in the corpus
#   frequency = the total number of times the token appears per
#               document-- that is a token is counted only once
#               per document if it is present (even if it appears 
#               several times within that document).

my %corp_freq_hash = ( );

# %stoplist_hash
#
# common list of uninteresting words which are likely irrelvant
# to any query.
#
#   Note: this is an associative array to provide fast lookups
#         of these boring words

my %stoplist_hash  = ( );

# @titles_vector
#
# vector of the cacm journal titles. Indexed in order of apperance
# within the corpus.

my @titles_vector  = ( );

# %relevance_hash
#
# a hash of hashes where each <key, value> pair consists of
#
#   key   = a query number
#   value = a hash consisting of document number keys with associated
#           numeric values indicating the degree of relevance the 
#           document has to the particular query.

my %relevance_hash = ( );

# @doc_simula
#
# array used for storing query to document or document to document
# similarity calculations (determined by cosine_similarity, etc. )

my @doc_simula = ( );

# @res_vector
#
# array used for storing the document numbers of the most relevant
# documents in a query to document or document to document calculation.

my @res_vector = ( );

my @correct_sense = ( );
my @sense1_docs = ();
my @sense2_docs = ();
my %centroid1 = ();
my %centroid2 = ();
my @senses = ();
my @doc_sim1 = ();
my @doc_sim2 = ();
my @cur_words = ();
my @cur_weights = ();
my $ambiguous_word = "";
my $ambiguous_word_ind = 0;
my $weighting_method = "";
# start program

&main;
# &main_loop;

##########################################################
##  INIT_FILES
##
##  This function specifies the names and locations of
##  input files used by the program. 
##
##  Parameter:  $filename ("plant", "tank" or "perplace" $type   ("stemmed" or "unstemmed")
##
##  If $type == "stemmed", the filenames are initialized
##  to the versions stemmed with the Porter stemmer, while
##  in the default ("unstemmed") case initializes to files
##  containing raw, unstemmed tokens.
##########################################################

sub init_files {
    my $filename = shift;
    $token_docs = $DIR . "\/$filename";
    $corps_freq = $DIR ."\/$filename";
    $stoplist = $DIR . "\/common_words";
    $titles = $DIR . "\/$filename\.titles";
    if ("stemmed" eq (shift || "")) {

        $token_docs .= "\.stemmed";
        $corps_freq .= "\.stemmed\.hist";
        $stoplist   .= "\.stemmed";
    }
    else {

        $token_docs .= "\.tokenized";
        $corps_freq .= "\.tokenized\.hist";
    }
}
sub init_stoplist {
    my $stoplist_fh = new FileHandle $stoplist, "r"
        or croak "Failed $stoplist";
    my $line = undef;
    while (defined( $line = <$stoplist_fh> )) {

        chomp $line;
        $stoplist_hash{ $line } = 1;
    }
}
##########################################################
##  INIT_CORP_FREQ 
##
##  This function reads in corpus and document frequencies from
##  the provided histogram file for both the document set
##  and the query set. This information will be used in
##  term weighting.
##
##  It also initializes the arrays representing the stoplist,
##  title list and relevance of document given query.
##########################################################

sub init_corp_freq {

    my $corps_freq_fh = new FileHandle $corps_freq, "r" 
        or croak "Failed $corps_freq";


    my $line = undef;

    while (defined( $line = <$corps_freq_fh> )) {

        # so on my computer split will return a first element of undef 
        # if the leading characters are white space, so I eat the white
        # space to insure that the split works right.

        my ($str) = ($line =~ /^\s*(\S.*)/);

        my ($doc_freq,
            $cor_freq, 
            $term    ) = split /\s+/, $str;

        $docs_freq_hash{ $term } = $doc_freq;
        $corp_freq_hash{ $term } = $cor_freq;
    }

    my $titles_fh = new FileHandle $titles, "r" 
        or croak "Failed $titles";
    push @titles_vector, "";       # push one empty value onto @titles_vector
    # so that indices correspond with title
    # numbers.

    while (defined( $line = <$titles_fh> )) {

        chomp $line;
        push @titles_vector, $line;
    }


}


##########################################################
##  INIT_DOC_VECTORS
##
##  This function reads in tokens from the document file.
##  When a .I token is encountered, indicating a document
##  break, a new vector is begun. When individual terms
##  are encountered, they are added to a running sum of
##  term frequencies. To save time and space, it is possible
##  to normalize these term frequencies by inverse document
##  frequency (or whatever other weighting strategy is
##  being used) while the terms are being summed or in
##  a posthoc pass.  The 2D vector array 
##
##    $doc_vector[ $doc_num ]{ $term }
##
##  stores these normalized term weights.
##
##  It is possible to weight different regions of the document
##  differently depending on likely importance to the classification.
##  The relative base weighting factors can be set when 
##  different segment boundaries are encountered.
##
##  This function is currently set up for simple TF weighting.
##########################################################

sub init_doc_vectors {


    my $token_docs_fh = new FileHandle $token_docs, "r"
        or croak "Failed $token_docs";

    my $word    = undef;

    my $doc_num =  0;    # current document number and total docs at end
    my $tweight =  1;    # current weight assigned to document token
    my $class = 0;
    @cur_words = ();
    @cur_weights = ();

    push @doc_vector, { };     # push one empty value onto @doc_vector so that
    push @correct_sense, 0;
    push @qry_vector, { };
    $ambiguous_word_ind = 0;
    # indices correspond with document numbers

    while (defined( $word = <$token_docs_fh> )) {

        chomp $word;


        if (($class) = $word =~ /^\.I\s\d*\s(\d*)/) {     # indicates start of a new document
            if ($doc_num > 0) {
                # print join "\n", @cur_words;
                if ($weighting_method =~ /exp/) { #     &assign_weights_exp;
                } elsif ($weighting_method =~ /step/) {
                    &assign_weights_step;
                } elsif ($weighting_method =~ /guassian/) {
                    &assign_weights_guassian;
                } else {
                    &assign_weights_uniform;
                }
                # print $doc_num, "\n", scalar @cur_words, "\n";
                for my $ind (0 .. scalar @cur_words - 1) {
                    $doc_vector[$doc_num]{$cur_words[$ind]} += $cur_weights[$ind];
                }
                # while (my ($key, $value) = each %{$doc_vector[$doc_num]}) {
                #     print "key: $key\tvalue: $value\n";

                # }
                @cur_words = ();
                @cur_weights = ();
                $ambiguous_word_ind = 0;
            }
            push @doc_vector, { };
            push @correct_sense, $class;
            $doc_num++;
            next;
        }

        
        if ($word =~ /[a-zA-Z]/ and ! exists $stoplist_hash{ $word }) {

            # print $word, "\n";
            # print $docs_freq_hash{ $word }, "\n";

            if (defined( $docs_freq_hash{ $word } )) {

		# print $word, "\n";
                push @cur_words, $word;
                push @cur_weights, 1;
                
                if (not ($word eq $ambiguous_word)) {
                    $ambiguous_word_ind++; 
                }
                # XXX
                # $doc_vector[$doc_num]{ $word } += $tweight;
            }
            else {
                print "ERROR: Document frequency of zero: ", $word, "\n";
            }
        }
    }
    if ($weighting_method =~ /exp/) { #     &assign_weights_exp;
    } elsif ($weighting_method =~ /step/) {
        &assign_weights_step;
    } elsif ($weighting_method =~ /guassian/) {
        &assign_weights_guassian;
    } else {
        &assign_weights_uniform;
    }
    # print $doc_num, "\n", scalar @cur_words, "\n";
    for my $ind (0 .. scalar @cur_words - 1) {
        $doc_vector[$doc_num]{$cur_words[$ind]} += $cur_weights[$ind];
    }

    # optionally normalize the raw term frequency
    #
    foreach my $hash (@doc_vector) {
        foreach my $key (keys %{ $hash }) {
            $hash->{ $key } *= log( $doc_num / $docs_freq_hash{ $key });
        }
    }

    return $doc_num;
}
sub assign_weights_uniform {
    for my $ind (0 .. scalar @cur_words - 1) {
        $cur_weights[$ind] = 1; 
    }
}
sub assign_weights_exp {
    for my $ind (0 .. scalar @cur_words - 1) {
        #XXX 
    }
}
sub assign_weights_step {
}
sub classify_training_docs {
    @sense1_docs = ();
    @sense2_docs = ();
    for (my $i = 1; $i <= 3600; $i++) {

        if ($correct_sense[$i] == 1) {
            push @sense1_docs, $doc_vector[$i];
        } else {
            push @sense2_docs, $doc_vector[$i];
        }
    }
}

sub compute_centroids {
    my $sum = 0;
    my $num = 0;
    my %norm = ();

    %centroid1 = ();
    %centroid2 = ();

    foreach my $hash (@sense1_docs) {
        $sum = 0;
        while (my ($key, $value) = each (%{$hash})) {
            # print "key: $key\tvalue: $value\n";
            $sum += $value * $value;
        }
        $sum = sqrt($sum);
        # $num = scalar keys %{$hash};
        %norm = ();
        while (my ($key, $value) = each (%{$hash})) {
            $norm{$key} = $value / $sum;
            $centroid1{$key} += $value / $sum;
        }
    }
    $num = scalar @sense1_docs;
    while (my ($key, $value) = each(%centroid1)) {
        $centroid1{$key} /= $num
    }

    foreach my $hash (@sense2_docs) {
        $sum = 0;

        while (my ($key, $value) = each (%{$hash})) {
            $sum += $value * $value;
        }
        $sum = sqrt($sum);
        # $num = scalar keys %{$hash};
        %norm = ();
        while (my ($key, $value) = each (%{$hash})) {
            $norm{$key} = $value / $sum;
            $centroid2{$key} += $value / $sum;
        }
    }
    $num = scalar @sense2_docs;
    while (my ($key, $value) = each(%centroid2)) {
        $centroid2{$key} /= $num
    }
}

sub determine_sense {
    @senses = ();
    @doc_sim1 = ();
    @doc_sim2 = ();
    push @doc_sim1, 0;
    push @doc_sim2, 0;
    push @senses, 0;
    for (my $ind = 3601; $ind <= 4000; $ind++) {
        my $sense = 1;
        my $sim1 = &cosine_sim_a($doc_vector[$ind], \%centroid1);
        my $sim2 = &cosine_sim_a($doc_vector[$ind], \%centroid2);

        if ($sim1 < $sim2) {
            $sense = 2;
        }
        push @doc_sim1, $sim1;
        push @doc_sim2, $sim2;
        push @senses, $sense;
        # print "===================================\n";
        # print "SENSE: ", $sense, "\n";
        # while (my ($term, $weight) = each ($doc_vector[$ind])) {
        #     if ($sense == 1) {
        #         if (exists $centroid1{$term}) {
        #             print $term, "\n";  
        #         } 
        #     } else {
        #         if (exists $centroid2{$term}) {
        #             print $term, "\n";
        #         }
        #     }
        # }
        # print "===================================\n";

    }
}
sub show_doc_senses {
    print << "EndOfList";
   ************************************************************
   Sense Choice for the Test Vectors
   ************************************************************
   Sim1\t\tSim2\t\tSense\tSim diff\tDoc#  Title
   ====\t\t====\t\t=====\t========\t====  ===================
EndOfList
    ;
    my $index = 1;
    my $correct = 0;
    for ($index = 1; $index <= 400; $index++) {
        my $my_sense = $senses[$index];
        my $correct_sense = $correct_sense[$index + 3600];
        if ($my_sense == $correct_sense) {
            $correct++;
            print " \+ "; 
        } else {
            print " \* ";
        }
        my ($sim1) = ($doc_sim1[$index] =~ /^([0-9]+\.\d{0,8})/);
        my ($sim2) = ($doc_sim2[$index] =~ /^([0-9]+\.\d{0,8})/);
        my $title = substr $titles_vector[$index + 3600], 0, 47;
        print $sim1, "\t", $sim2, "\t", $my_sense, "\t", $sim1 - $sim2, "\t", $title, "\n";
    }
    print "Accuracy: ", $correct / 400, "\n";
    
    
}
##########################################################
## MAIN_LOOP
##
## Parameters: currently no explicit parameters.
##             performance dictated by user imput.
## 
## Initializes document and query vectors using the
## input files specified in &init_files. Then offers
## a menu and switch to appropriate functions in an
## endless loop.
## 
## Possible extensions at this level:  prompt the user
## to specify additional system parameters, such as the
## similarity function to be used.
##
## Currently, the key parameters to the system (stemmed/unstemmed,
## stoplist/no-stoplist, term weighting functions, vector
## similarity functions) are hardwired in.
##
## Initializing the document vectors is clearly the
## most time consuming section of the program, as 213334 
## to 258429 tokens must be processed, weighted and added
## to dynamically growing vectors.
## 
##########################################################
sub main {
    &init_files("tank");
    &init_stoplist;
    &init_corp_freq;
    &init_doc_vectors;
    &classify_training_docs;
    &compute_centroids;
    &determine_sense;    
    &show_doc_senses;

    &init_files("plant");
    &init_corp_freq;
    &init_doc_vectors;
    &classify_training_docs;
    &compute_centroids;
    &determine_sense;
    &show_doc_senses;
}
sub main_loop {

    print "INITIALIZING VECTORS ... \n";

    &init_files ( "unstemmed" );
    &init_corp_freq;

    my $total_docs = &init_doc_vectors;
    my $total_qrys = &init_qry_vectors;

    while (1) {

        print <<"EndOfMenu";

    ============================================================
    ==     Welcome to the 600.466 Vector-based IR Engine
    ==                                                  
        == Total Documents: $total_docs                     
    == Total Queries:   $total_qrys                     
    ============================================================

    OPTIONS:
      1 = Find documents most similar to a given query or document
      2 = Compute precision/recall for the full query set
      3 = Compute cosine similarity between two queries/documents
      4 = Quit

    ============================================================

EndOfMenu
        ;

        print "Enter Option: ";

        my    $option = <STDIN>;
        chomp $option;

        exit 0 if $option == 4;

        &full_precision_recall_test and next if $option == 2;
        &do_full_cosine_similarity  and next if $option == 3;

        # default and choice 1 is

        &get_and_show_retrieved_set;
    } 
}


##########################################################
## GET_AND_SHOW_RETRIEVED_SET
##   
##  This function requests key retrieval parameters,
##  including:
##  
##  A) Is a query vector or document vector being used
##     as the retrieval seed? Both are vector representations
##     but they are stored in different data structures,
##     and one may optionally want to treat them slightly
##     differently.
##
##  B) Enter the number of the query or document vector to
##     be used as the retrieval seed.
##
##     Alternately, one may wish to request a new query
##     from standard input here (and call the appropriate
##     tokenization, stemming and term-weighting routines).
##
##  C) Request the maximum number of retrieved documents
##     to display.
##
##  Perl note: one reads a line from a file <FILE> or <STDIN>
##             by the assignment $string=<STDIN>; Beware of
##             string equality testing, as these strings 
##             will have a newline (\n) attached.
##########################################################

sub get_and_show_retrieved_set {

    print << "EndOfMenu";

    Find documents similar to:
        (1) a query from 'query.raw'
    (2) an interactive query
    (3) another document
EndOfMenu
    ;

    print "Choice: ";

    my    $comp_type = <STDIN>;
    chomp $comp_type;

    if   ($comp_type !~ /^[1-3]$/) { $comp_type = 1; }

    print "\n";


    # if not an interactive query than we need to retrieve which
    # query/document we want to use from the corpus

    my $vect_num = 1;

    if ($comp_type != 2) {
        print "Target Document/Query number: ";

        $vect_num  = <STDIN>;
        chomp $vect_num;

        if   ($vect_num !~ /^[1-9]/) { $vect_num  = 1; }

        print "\n";
    }


    print "Show how many matching documents (20): ";

    my    $max_show  = <STDIN>;
    chomp $max_show;

    if   ($max_show !~ /[0-9]/) { $max_show  = 20; }

    if    ($comp_type == 3) {

        print "Document to Document comparison\n";

        &get_retrieved_set( $doc_vector[$vect_num] );
        &shw_retrieved_set( $max_show, 
            $vect_num, 
            $doc_vector[$vect_num],
            "Document" );
    }
    elsif ($comp_type == 2) {

        print "Interactive Query to Document comparison\n";

        my $int_vector = &set_interact_vec;  # vector created by interactive
        #  query

        &get_retrieved_set( $int_vector );
        &shw_retrieved_set( $max_show,
            0,
            $int_vector,
            "Interactive Query" );
    }
    else {

        print "Query to Document comparison\n";

        &get_retrieved_set( $qry_vector[$vect_num] );
        &shw_retrieved_set( $max_show,
            $vect_num,
            $qry_vector[$vect_num],
            "Query" );

        &comp_recall( $relevance_hash{ $vect_num },
            $vect_num );
        &show_relvnt( $relevance_hash{ $vect_num },
            $vect_num,
            $qry_vector[$vect_num] );
    }
}


sub set_interact_vec {

    system "$DIR/interactive.prl" and die "Failed $DIR/interactive.prl: $!\n";

    my $QUERY_BASE_WEIGHT = 2;
    my $QUERY_AUTH_WEIGHT = 2;

    my $token_qrys_fh = new FileHandle $token_intr, "r"
        or croak "Failed $token_intr";

    my $int_vector = { };
    my $word       = undef;

    my $tweight =  0;
    my $qry_num =  0;

    while (defined( $word = <$token_qrys_fh> )) {

        chomp $word;
        print $word, "\n";

        next if $word =~ /^\.I/;   # start of query tokens

        $tweight = $QUERY_BASE_WEIGHT and next if $word =~ /^\.W/;
        $tweight = $QUERY_AUTH_WEIGHT and next if $word =~ /^\.A/;

        if ($word =~ /[a-zA-Z]/ && ! exists $stoplist_hash{ $word }) {

            if (! exists $docs_freq_hash{ $word }) {
                print "ERROR: Document frequency of zero: ", $word, "\n";
            }
            else {
                $$int_vector{ $word } += $tweight;
            }
        }
    }

    return $int_vector
}


###########################################################
## GET_RETRIEVED_SET
##
##  Parameters:
## 
##  $qry_vector{} - the query vector to be compared with the
##                  document set. May also be another document 
##                  vector.
##
##  This function computes the document similarity between the
##  given vector $qry_vector{} and all vectors in the document
##  collection storing these values in the array @doc_simula
##
##  An array of the document numbers is then sorted by this
##  similarity function, forming the rank order of documents
##  for use in the retrieval set.  
##
##  The -1 in the simcomp similarity comparision function
##  makes the sorted list in descending order.
##########################################################

sub get_retrieved_set {

    my $qry_vector = shift;
    my $tot_number = (scalar @doc_vector) - 1;
    my $index      = 0;

    @doc_simula = ( );   # insure that storage vectors are empty before we
    @res_vector = ( );   # calculate vector similarities

    push @doc_simula, 0.0;    # push one empty value so that indices 
    # correspond with document values

    for $index ( 1 .. $tot_number) {
        push @doc_simula, &cosine_sim_a( $qry_vector, $doc_vector[$index] );
    }

    @res_vector = 
    sort { -1 * ($doc_simula[$a] <=> $doc_simula[$b]); } 1 .. $tot_number;
}

############################################################
## SHW_RETRIEVED_SET
##
## Assumes the following global data structures have been
## initialized, based on the results of &get_retrieved_set.
##
## 1) @res_vector - contains the document numbers sorted in 
##                  rank order
## 2) @doc_simula - The similarity measure for each document, 
##                  computed by &get_retrieved_set.
##
## Also assumes that the following have been initialized in
## advance:
##
##       $titles[ $doc_num ]    - the document title for a 
##                                document number, $doc_num
##       $relevance_hash{ $qry_num }{ $doc_num }
##                              - is $doc_num relevant given
##                                query number, $qry_num
##
## Parameters:
##   $max_show   - the maximum number of matched documents 
##                 to display.
##   $qry_num    - the vector number of the query
##   $qry_vect   - the query vector (passed by reference)
##   $comparison - "Query" or "Document" (type of vector 
##                 being compared to)
##
## In the case of "Query"-based retrieval, the relevance 
## judgements for the returned set are displayed. This is 
## ignored when doing document-to-document comparisons, as 
## there are nor relevance judgements.
##
############################################################

sub shw_retrieved_set {

    my $max_show   = shift;
    my $qry_num    = shift;
    my $qry_vect   = shift;
    my $comparison = shift;

    print << "EndOfList";

    ************************************************************
    Documents Most Similar To $comparison number $qry_num
    ************************************************************
    Similarity   Doc#  Author      Title
    ==========   ==== ========     =============================

EndOfList
    ;

    my $rel_num = ($qry_num =~ /^\d$/) ? "0$qry_num" : $qry_num;
    my $index   = 0;

    for $index ( 0 .. $max_show ) {
        my $ind = $res_vector[$index];

        if (($comparison =~ /Query/) and 
            ($relevance_hash{ $rel_num }{ $ind })) {
            print "\* ";
        }
        else {
            print "  ";
        }

        my ($similarity) = ($doc_simula[$ind]    =~ /^([0-9]+\.\d{0,8})/);
        my  $title       = substr $titles_vector[$ind], 0, 47;

        print "  ", $similarity, "   ", $title, "\n";
    }

    print "\n";
    print "Show the terms that overlap between the query and ";
    print "retrieved docs (y/n): ";

    my  $show_terms = <STDIN>;
    if ($show_terms !~ /[nN]/) {

        my $index = 0;

        for $index ( 0 .. $max_show ) {
            my $ind = $res_vector[$index];

            show_overlap( $qry_vect,
                $doc_vector[$ind],
                $qry_num,
                $ind );

            if ($index % 5 == 4) {

                print "\n";
                print "Continue (y/n)? ";

                my  $cont = <STDIN>;
                if ($cont =~ /[nN]/) {
                    last;
                }
            }
        }
    }
}


##########################################################
## COMPUTE_PREC_RECALL
##
## Like &shw_retrieved_set, this function makes use of the following
## data structures which may either be passed as parameters or
## used as global variables. These values are set by the function
## &get_retrieved_set.
##
## 1) doc_simila[ $rank ] - contains the document numbers sorted 
##                          in rank order based on the results of 
##                          the similarity function
##
## 2) res_vector[ $docn ] - The similarity measure for each document, 
##                          relative to the query vector ( computed by 
##                          &get_retrieved_set).
##
## Also assumes that the following have been initialzied in advance:
##       $titles[ $docn ]       - the document title for a document 
##                                number $docn
##       $relevance_hash{ $qvn }{ $docn } 
##                              - is $docn relevant given query number 
##                                $qvn
##
##  The first step of this function should be to take the rank ordering
##  of the documents given a similarity measure to a query 
##  (i.e. the list docs_sorted_by_similarity[$rank]) and make a list 
##  of the ranks of just the relevant documents. In an ideal world,
##  if there are k=8 relevant documents for a query, for example, the list 
##  of rank orders should be (1 2 3 4 5 6 7 8) - i.e. the relevant documents
##  are the top 8 entries of all documents sorted by similarity.
##  However, in real life the relevant documents may be ordered
##  much lower in the similarity list, with rank orders of
##  the 8 relevant of, for example, (3 27 51 133 159 220 290 1821).
##  
##  Given this list, compute the k (e.g. 8) recall/precison pairs for
##  the list (as discussed in class). Then to determine precision
##  at fixed levels of recall, either identify the closest recall
##  level represented in the list and use that precision, or
##  do linear interpolation between the closest values.
##
##  This function should also either return the various measures
##  of precision/recall specified in the assignment, or store
##  these values in a cumulative sum for later averaging.
##########################################################

sub comp_recall {
    print "To be implemented\n";
}

##########################################################
## SHOW_RELVNT
## 
## UNIMPLEMENTED
##
## This function should take the rank orders and similarity
## arrays described in &show_retrieved_set and &comp_recall
## and print out only the relevant documents, in an order
## and manner of presentation very similar to &show_retrieved_set.
##########################################################

sub show_relvnt {
    print "To be implemented\n";
}


########################################################
## SHOW_OVERLAP
## 
## Parameters:
##  - Two vectors ($qry_vect and $doc_vect), passed by
##    reference.
##  - The number of the vectors for display purposes
##
## PARTIALLY IMPLEMENTED:
## 
## This function should show the terms that two vectors
## have in common, the relative weights of these terms
## in the two vectors, and any additional useful information
## such as the document frequency of the terms, etc.
##
## Useful for understanding the reason why documents
## are judged as relevant. 
##
## Present in a sorted order most informative to the user.
##
########################################################

sub show_overlap {

    my $qry_vect = shift;
    my $doc_vect = shift;
    my $qry_num  = shift;
    my $doc_num  = shift;

    print "============================================================\n";
    printf( "%-15s  %8d   %8d\t%s\n", 
        "Vector Overlap",
        $qry_num        ,
        $doc_num        ,
        "Docfreq"       );
    print "============================================================\n";

    my $term_one   = undef;
    my $weight_one = undef;

    while (($term_one, $weight_one) = each %{ $qry_vect }) {
        if (exists $$doc_vect{ $term_one }) {

            printf( "%-15s  %8d   %8d\t%d\n"    ,
                $term_one                    ,
                $weight_one                  ,
                $$doc_vect{ $term_one }      ,
                $docs_freq_hash{ $term_one } );
        }
    }
}


########################################################
## DO_FULL_COSINE_SIMILARITY
## 
##  Prompts for a document number and query number,
##  and then calls a function to show similarity.
##
##  Could/should be expanded to handle a variety of
##  similarity measures.
########################################################

sub do_full_cosine_similarity {

    print "\n";
    print "1st Document/Query number: ";

    my    $num_one = <STDIN>;
    chomp $num_one;

    print "\n";
    print "2nd Document/Query number: ";

    my    $num_two = <STDIN>;
    chomp $num_two;

    $num_one = 1 if $num_one !~ /[0-9]/;
    $num_two = 1 if $num_two !~ /[0-9]/;

    full_cosine_similarity( $qry_vector[$num_one],
        $doc_vector[$num_two],
        $num_one,
        $num_two );
}


########################################################
## FULL_COSINE_SIMILARITY
## 
## UNIMPLEMENTED
## 
## This function should compute cosine similarity between
## two vectors and display the information that went into
## this calculation, useful for debugging purposes.
## Similar in structure to &show_overlap.
########################################################

sub full_cosine_similarity {

    my $qry_vect = shift;
    my $doc_vect = shift;
    my $qry_indx = shift;
    my $doc_indx = shift;

    print "The rest is up to you . . . \n";
}


##########################################################
##  FULL_PRECISION_RECALL_TEST
##
##  This function should test the various precision/recall 
##  measures discussed in the assignment and store cumulative
##  statistics over all queries.
##
##  As each query takes a few seconds to process, print
##  some sort of feedback for each query so the user
##  has something to watch.
##
##  It is helpful to also log this information to a file.
##########################################################

sub full_precision_recall_test {

    print "Function is currently unimplemented\n";

    return;

    # Suggestion: if using global variables to store cumulative
    #             statistics, initialize them here.

#    for my $ind ( 1 .. $tot_queries ) {
    #
#	&get_retrieved_set( $qry_vector[$ind] );
#	&comp_recall( $relevance_hash{ $ind }, $ind );
    #
#	# Suggestion: Collect cumulative statistics here or in
#	#             global variables set in the above funtion
#    }

    # Suggestion: Print some sort of summary here.
}


########################################################
## COSINE_SIM_A
## 
## Computes the cosine similarity for two vectors
## represented as associate arrays.
########################################################

sub cosine_sim_a {

    my $vec1 = shift;
    my $vec2 = shift;

    my $num     = 0;
    my $sum_sq1 = 0;
    my $sum_sq2 = 0;

    my @val1 = values %{ $vec1 };
    my @val2 = values %{ $vec2 };

    # determine shortest length vector. This should speed 
    # things up if one vector is considerable longer than
    # the other (i.e. query vector to document vector).

    if ((scalar @val1) > (scalar @val2)) {
        my $tmp  = $vec1;
        $vec1 = $vec2;
        $vec2 = $tmp;
    }

    # calculate the cross product

    my $key = undef;
    my $val = undef;

    while (($key, $val) = each %{ $vec1 }) {
        $num += $val * ($$vec2{ $key } || 0);
    }

    # calculate the sum of squares

    my $term = undef;

    foreach $term (@val1) { $sum_sq1 += $term * $term; }
    foreach $term (@val2) { $sum_sq2 += $term * $term; }
    
    # print "sum_sq1: $sum_sq1\tsum_sq2: $sum_sq2\n";
    return ( $num / sqrt( $sum_sq1 * $sum_sq2 ));
}


########################################################
##  COSINE_SIM_B
##  
##  This function assumes that the sum of the squares
##  of the term weights have been stored in advance for
##  each document and are passed as arguments.
########################################################

sub cosine_sim_b {

    my $vec1 = shift;
    my $vec2 = shift;

    my $sum_sq1 = shift;
    my $sum_sq2 = shift;

    my $num     = 0;
    my $key     = undef;
    my $val     = undef;

    while (($key, $val) = each %{ $vec1 }) {
        $num += $val * $$vec2{ $key };
    }

    return ( $num / sqrt( $sum_sq1 * $sum_sq2 ));
}
