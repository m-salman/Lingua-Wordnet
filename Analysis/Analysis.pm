package Lingua::Wordnet::Analysis;

use strict;
use Lingua::Wordnet;
use vars qw($VERSION);

$VERSION = '0.3';

=head1 NAME

Lingua::Wordnet::Analysis - Perl extension for high-level processing of Wordnet databases.  

=head1 SYNOPSIS

 use Lingua::Wordnet::Analysis;

 $analysis = new Lingua::Wordnet::Analysis;

 # How many articles of clothing have 'tongues'?
 $tongue = $wn->lookup_synset("tongue","n",2);
 @articles = $analysis->search($clothes,$tongue,"all_meronyms");
 
 # Are there any parts, of any kinds, of any shoes, made of glass?
 @shoe_types = $analysis->traverse("hyponyms",$shoes);
 $count = $analysis->search(@shoe_types,$glass,"stuff_meronyms");

 # Compute the intersection of two lists of synsets
 @array1 = $shoes->all_holonyms;
 @intersect = $analysis->intersection
       (\@{$shoes->attributes},\@{$socks->attributes});

 # Generate a list of the inherited comp_meronyms for "apple"
 @apple_hypernyms = $analysis->traverse("hypernyms",$apple);
 @apple_parts = $analysis->traverse("comp_meronyms",@apple_hypernyms);
 

=head1 DESCRIPTION

Lingua::Wordnet::Analysis supplies high-level functions for analysis of word relationships. Most of these functions process and return potentially large amounts of data, so only use them if you "know what you are doing."

These functions could have been put into Lingua::Wordnet::Synset objects, but I wanted to keep those limited to core functionality. Besides, many of these functions have unproven usefulness.

=head1 Lingua::Wordnet::Analysis functions

=item $analysis->match(SYNSET,ARRAY)

Finds any occurance of SYNSET in the synset list ARRAY and the list's pointers. Returns a positive value if a match is found. match() does not traverse.


=item $analysis->search(SYNSET1,SYNSET2,POINTER)

Searches all pointers of type POINTER in SYNSET1 for SYNSET2. search() is recursive, and will traverse all depths. Returns the number of matches.
    

=item $analysis->traverse(POINTER,SYNSET)

Traverses all pointer types of POINTER in SYNSET and returns a list of all synsets found in the tree.


=item $analysis->coordinates(SYNSET)

Returns a list of the coordinate sisters of SYNSET.


=item $analysis->union(LIST)

Returns a list of synsets which is the union of synsets LIST. The union consists of synsets which occur in any lists. This is useful, for example, for determining all the holonyms for two or more synsets.


=item $analysis->intersection(ref LIST)

Returns a list of synsets of the intersection of ARRAY1 list of synsets with ARRAY2 list of synsets. The intersection consists of synsets which occur in both lists. This is useful, for example, to determine which meronyms are shared by two synsets:

    @synsets = $analysis->intersection
        (\@{$synset1->all_meronyms},\@{$synset2->all_meronyms});

=item $analysis->distance(SYNSET1,SYNSET2,POINTER)

Returns an integer value representing the distance in pointers between SYNSET1 and SYNSET2 using POINTER as the search path.

=head1 EXAMPLES

To print out an inherited meronym list, use traverse():

    $orange = $wn->lookup_synset("orange","n",1);
    @orange_hypernyms = $analysis->traverse("hypernyms",$orange);
    foreach ($analysis->traverse("all_meronyms",@orange_hypernyms)) {
        print $_->words, "\n";
    }

Note that the inherited meronyms will not contain the direct meronyms of
$orange.


=head1 BUGS/TODO

There is tons that could go in this module ... submissions are welcome!

Lots of cleanup.

Need to add a search_path function that will return a path to a match as a linked list or hash of hashes.

Some might want inherited meronym/holonym trees.

Please send bugs and suggestions/requests to dbrian@brians.org. Development
on this module is active as of Winter 2000.

=head1 AUTHOR

Copyright (C)2000, Daniel Brian.

D. Brian, dbrian@brians.org.

=head1 SEE ALSO

Lingua::Wordnet.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub match {
    my $self = shift;
    my $synset = shift;
    my @synsets = @_;
    my $match = 0;
    foreach (@synsets) {
        if ($_->{offset} eq $synset->{offset}) {
            $match++;
        }
    }
    return $match;
}

sub distance {
    my $self = shift;
    my $synset1 = shift;
    my $matching = shift;
    my $ptrtype = shift;
    my @synsets = ( );
    my $findit;
    $findit = sub {
        my $synset = shift;
        my $matching = shift;
        my $pointer = shift;
        my $count = shift;
        $count++;
        my @synsets1 = ( );
        my @list = ( );
        my $found = 0;
        eval("\@list = \$synset->$pointer");
        die ($@) if ($@);
        foreach (@list) {
            if ($_->{offset} eq $matching->{offset}) {
                return (1,$count);
            } 
            ($found,$count) = &{$findit}($_,$matching,$pointer,$count);
            if ($found) { return (1,$count); }
        }
        return (0,$count);
    };
    my ($found,$count) = &{$findit}($synset1,$matching,$ptrtype,0);
    if ($found) { return $count; }
    else { return 0; }

}

sub search {
    my $self = shift;
    my $synset1 = shift;
    my $matching = shift;
    my $ptrtype = shift;
    my $lastsynset;
    my @synsets;
    my $matchit;
    $matchit = sub {
        my $synset = shift;
        my @list;
        eval("\@list = \$synset->$ptrtype");
        die ($@) if ($@);
        foreach (@list) {
            if ($_->{offset} eq $matching->{offset}) {
                push (@synsets,$lastsynset);
            }
            $lastsynset = $_;
            &{$matchit}($_);
        }
    };
    &{$matchit}($synset1);
    @synsets;
}

sub traverse {
    my $self = shift;
    my $ptrtype = shift;
    my @synsets = ( );
    my %hash;
    my $traverseit;
    $traverseit = sub {
        my $synset = shift;
        my $pointer = shift;
        my @synsets1 = ( );
        my @list = ( );
        eval("\@list = \$synset->$pointer");
        die ($@) if ($@);
        foreach (@list) {
            unless (exists $hash{$_}) {
                push @synsets1, $_;
                push @synsets1, &{$traverseit}($_,$pointer);
                $hash{$_->{offset}} = "";
            }
        }
        @synsets1;
    };
    foreach (@_) {
        push @synsets, &{$traverseit}($_,$ptrtype);
    }
    @synsets;
}

sub coordinates {
    my $self = shift;
    my $synset = shift;
    return ($synset->hypernyms)[0]->hyponyms;
}

sub union {
    my $self = shift;
    my @synsets;
    my %union = ( );
    foreach (@_) {
        @union{$_->{offset}} = $_;
    }
    foreach (keys %union) {
        push(@synsets,$union{$_});
    }
    return @synsets;
}

sub intersection {
    my $self = shift;
    my ($i,$sizei) = (0, scalar @{$_[0]});
    my ($j,$sizej);
    my $set;
    for ($j = 1; $j < scalar @_; $j++) {
        $sizej = scalar @{$_[$j]};
        ($i,$sizei) = ($j,$sizej) if ($sizej < $sizei);
    }
    my @intersection;
    my $array = splice @_, $i, 1;
    my %valuehash;
    foreach (@$array) { push @intersection, 
        $_->{offset}; $valuehash{$_->{offset}} = $_; }
    my $set;
    while ($set = shift) {
        my $newlist;
        foreach (@$set) {
            my @offsets;
            push @offsets, $_->{offset};
            $newlist->{$_->{offset}} = "";
        }
        @intersection = grep { exists $newlist->{$_} } @intersection;
    }
    my @synsets;
    foreach (@intersection) { push @synsets, $valuehash{$_} }
    return @synsets;
}

sub close {
    my $self = shift;
    $self->DESTROY();
}

sub DESTROY {
    my $self = shift;
    undef $self;
}

1;
__END__
