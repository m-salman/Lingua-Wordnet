    #!/usr/bin/perl

    use Lingua::Wordnet;
    use strict;

    my $wn = new Lingua::Wordnet;
    my $password = $wn->lookup_synset("oven","n",1);
    my $word;
    my $pos;


    while (1) {
        print "Enter a word: ";
        chomp($word = <STDIN>);
        print "Enter a part-of-speech: ";
        chomp($pos  = <STDIN>);
 
        my @synsets = $wn->lookup_synset($word,$pos);
        unless (@synsets) { print "No matches found.\n\n"; next; }

        foreach my $synset (@synsets) {
            print "words: ", $synset->words, "\n";
            print "gloss: ", $synset->gloss, "\n";
            print "frames: ", $synset->frames, "\n\n";

        }
        
    }
