#!/usr/bin/perl

use DB_File;
use Fcntl;

#$DB_BTREE->{'flags'} = R_DUP;

print "This program will convert your Wordnet databases into files usable by\nLingua::Wordnet. This will not affect your existing Wordnet files, but\nwill require up to 40MB disk space. Continue? [y]";
if (<STDIN> =~ /^n/i) { return; }

if (shift(@ARGV) =~ /DATA_DIR=(.*)\s*$/) {
    $datadir = $1;
}
if (!$datadir) {
    print "Data directory: [/usr/local/wordnet1.6/dict/] ";
    $datadir = (<STDIN>);
    chop $datadir; 
    if (!$datadir) { $datadir = "/usr/local/wordnet1.6/dict/" }
}
if (!-e "$datadir/data.noun") {
    die "Directory $datadir doesn't exist, or doesn't contain the proper data
files.";
}

print "Lingua::Wordnet needs to write the new files to a data directory.\nWhere do you want these files saved?\n[/usr/local/wordnet1.6/lingua-wordnet/] ";
$newdir = <STDIN>;
chop $newdir;
if (!$newdir) { $newdir = "/usr/local/wordnet1.6/lingua-wordnet/"; }
if (!-d $newdir) {
    print "$newdir doesn't exist. Create it? [y] ";
    if (<STDIN> =~ /^n/i) { exit(0); }
    mkdir($newdir,0666) or do { print "Couldn't create $newdir: $!\n"; 
                                            exit(0); };
}
if (!-w $newdir) {
    die "$newdir doesn't exist, or you don't have permission to write there.";
}

print "\nStarting conversion ...\n";
print "  Index files:   \"index.noun\"  => \"lingua_wordnet.index\"\n";

unlink "$newdir/lingua_wordnet.index";

open FILE, "$datadir/index.noun" or die "Couldn't open $datadir/index.noun: $!";
tie %hash, "DB_File", "$newdir/lingua_wordnet.index", O_RDWR|O_CREAT, 0666, $DB_BTREE
    or die "Couldn't create lingua_wordnet.index: $!" ;
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$value) = formatindex($_);
    $hash{$key} = $value;
}
close FILE;

print "                 \"index.verb\"  => \"lingua_wordnet.index\"\n";

open FILE, "$datadir/index.verb" or die "Couldn't open $datadir/index.verb: $!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$value) = formatindex($_);
    $hash{$key} = $value;
}
close FILE;

print "                 \"index.adj\"   => \"lingua_wordnet.index\"\n";

open FILE, "$datadir/index.adj" or die "Couldn't open $datadir/index.adj:
$!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$value) = formatindex($_);
    $hash{$key} = $value;
}
close FILE;

print "                 \"index.adv\"   => \"lingua_wordnet.index\"\n";

open FILE, "$datadir/index.adv" or die "Couldn't open $datadir/index.adv: $!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$value) = formatindex($_);
    $hash{$key} = $value;
}
close FILE;
untie %hash;

unlink "$newdir/lingua_wordnet.morph";
tie %hash, "DB_File", "$newdir/lingua_wordnet.morph", O_RDWR|O_CREAT, 0666, $DB_BTREE
    or die "Couldn't create lingua_wordnet.sense: $!" ;

print "  Morph files:   \"adj.exc\"      => \"lingua_wordnet.morph\"\n";

open FILE, "$datadir/adj.exc" or die "Couldn't open $datadir/adj.exc: $!";
while (<FILE>) {
    my ($key,$value) = split(/\s/);
    $hash{"$key"} = $value;
}
close FILE;

print "                 \"adv.exc\"     => \"lingua_wordnet.morph\"\n";

open FILE, "$datadir/adv.exc" or die "Couldn't open $datadir/index.adv.exc:
$!";
while (<FILE>) {
   my ($key,$value) = split(/\s/);
    $hash{"$key"} = $value;
}
close FILE;

print "                 \"noun.exc\"    => \"lingua_wordnet.morph\"\n";

open FILE, "$datadir/noun.exc" or die "Couldn't open $datadir/noun.exc: $!";
while (<FILE>) {
    my ($key,$value) = split(/\s/);
    $hash{"$key"} = $value;
}
close FILE;

print "                 \"verb.exc\"    => \"lingua_wordnet.morph\"\n";

open FILE, "$datadir/verb.exc" or die "Couldn't open $datadir/verb.exc: $!";
while (<FILE>) {
    my ($key,$value) = split(/\s/);
    $hash{"$key"} = $value;
}
close FILE;

print "                 \"cousin.exc\"  => \"lingua_wordnet.morph\"\n";

open FILE, "$datadir/cousin.exc" or die "Couldn't open $datadir/cousin.exc: $!";
while (<FILE>) {
    my ($key,$value) = split(/\s/);
    $hash{"$key"} = $value;
}
close FILE;

untie %hash;

unlink "$newdir/lingua_wordnet.data";
tie %hash, "DB_File", "$newdir/lingua_wordnet.data", O_RDWR|O_CREAT, 0666, $DB_BTREE
    or die "Couldn't create lingua_wordnet.data: $!" ;

$hash{offsetcount} = "10989500";

print "  Data files:    \"data.adj\"    => \"lingua_wordnet.data\"\n";

open FILE, "$datadir/data.adj" or die "Couldn't open $datadir/data.adj: $!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$data) = formatsynset($_);
    $hash{$key} = $data;
}
close FILE;

print "                 \"data.adv\"    => \"lingua_wordnet.data\"\n";

open FILE, "$datadir/data.adv" or die "Couldn't open $datadir/data.adv: $!";
while (<FILE>) {
     chop $_;
    if (/^\s+/) { next; }
    my ($key,$data) = formatsynset($_);
    $hash{$key} = $data;
}
close FILE;

print "                 \"data.noun\"   => \"lingua_wordnet.data\"\n";

open FILE, "$datadir/data.noun" or die "Couldn't open $datadir/data.noun: $!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$data) = formatsynset($_);
    $hash{$key} = $data;
}
close FILE;

print "                 \"data.verb\"   => \"lingua_wordnet.data\"\n";

open FILE, "$datadir/data.verb" or die "Couldn't open $datadir/data.verb: $!";
while (<FILE>) {
    chop $_;
    if (/^\s+/) { next; }
    my ($key,$data) = formatsynset($_);
    $hash{$key} = $data;
}
close FILE;
untie %hash;


print "  Gloss index:   \"index.gloss\" => \"lingua_wordnet.gloss\"\n";

print "\nConversion completed.\n"; sleep(1);

if ($newdir ne "/usr/local/wordnet1.6/lingua-wordnet/"){
    chdir("../");
    link("Wordnet.pm","Wordnet.pm.old");
    unlink("Wordnet.pm");
    open FILE, "Wordnet.pm.old";
    open NEWFILE, ">Wordnet.pm";
    while (<FILE>) {
        if (/^\$DICTDIR/) {
            print NEWFILE "\$DICTDIR = '$newdir'\n";
        } else {
            print NEWFILE;
        }
    }
    close NEWFILE;
    close FILE;
}

sub formatindex {
    #s_gravenhage n 1 2 @ #p 1 0 06537474
    my $string = shift;
    my $okparse = 1;
    my @synsets;
    my ($lemma,$pos,$poly_cnt,$p_cnt,$ptr_symbol,$sense_cnt,$tagsense_cnt,$syset_offsets) = "";

    if ($string =~ /^(\S+)\s(\w)\s(\d+)\s(\d+)\s/g) {
        $lemma = $1;
        $pos = $2;
        $poly_cnt = $3;
        $p_cnt = $4;
        for (1 .. $p_cnt) { 
            # discard the pointer symbols
            if ($string !~ /\G(\S{1,2})\s/g) {
                print "pointers error\n";
                $okparse = 0;
            }
        }
        if ($string =~ /\G(\d+)\s(\d+)\s/g) {
            $sense_cnt = $1;
            $tagsense_cnt = $2; 
        } else {
            print "sense_cnt error";
            $okparse = 0;
        }
        my $i = 0;
        for $i (1 .. $sense_cnt) {
            if ($string =~ /\G(\d{8})\s*/g) {
                push(@synsets,$1);
            } else {
                print "synsets error\n";
                $okparse = 0;
            }
        }
    } else {
        print "whole error";
        $okparse = 0;
    }
    if ($okparse == 0) { 
        print "WARNING: index entry did not parse: $string\n";
    }
    
    $synset_offsets = join("\|",@synsets);
    my $key = "$lemma\%$pos";
    #$poly_cnt||$synset_offsets
    my $data = "$poly_cnt||$synset_offsets";
    return ($key,$data);
}

sub formatsynset {
    my $string = shift;
    my $okparse = 1;
    my ($offset,$filenum,$ss_type,$w_cnt,$words,$ptrs,$frames) = "";
    if ($string =~ /^(\d+)\s(\d{2})\s(\w)\s(\w{2})\s/g) {
        $offset = $1;
        $filenum = $2;
        $ss_type = $3;
        $w_cnt = $4;
        my $thiscount = 0;
        for (1 .. hex($w_cnt)) {
            if ($string =~ /\G(\S+)\s(\w)*\s*/g) {
                my $word = $1;
                my $lex_id = $2;
                $words .= "|$word\%$lex_id";
            } else {
                $okparse = 0;
            }
            $words =~ s/^\|//;
        }
        if ($string =~ /\G(\d{3})\s/g) {
            $p_cnt = $1;
            for (1 .. $p_cnt) {
                my ($ptrsym,$ptroffset,$ptrpos,$ptrsrc) = "";
                if ($string =~ /\G(\S{1,2})\s(\d+)\s(\w)\s(\w{4})\s/g) {
                    $ptrsym = $1;
                    $ptroffset = $2; 
                    $ptrpos = $3;
                    $ptrsrc = $4;
                    $ptrs .= "|$ptrsym $ptroffset\%$ptrpos $ptrsrc";
                } else {
                    $okparse = 0;
                }
            }
            $ptrs =~ s/^\|//;
        } else {
            $okparse = 0;
        }
        if ($ss_type eq "v") {
            if ($string =~ /\G\s*(\d{2})\s/g) {
                my $f_cnt = $1;
                my ($f_num,$w_num) = "";
                for (1 .. $f_cnt) {
                    if ($string =~ /\G\+\s(\d{2})\s(\w{2})\s/g) {
                        $f_num = $1;
                        $w_num = $2; 
                        $frames .= "|$f_num $w_num";
                    } else {
                        $okparse = 0;
                    }
                }
                $frames =~ s/^\|//;
            } else {
                $okparse = 0;
            }
        }
        if ($string =~ /\G\s*\|\s*(.+)\s*$/g) {
            $gloss = $1;
        }
    } else {
        $okparse = 0;
    }
    if ($okparse != 1) {
        print "WARNING: a synset did not parse properly:\n$string\n";
    }

    #$filenum||$pos||$ss_type||$words||$prts||$frames||$gloss
    if ($ss_type eq "s") { $ss_type = "a"; }
    $key = "$offset\%$ss_type";
    $data = "$filenum||$words||$ptrs||$frames||$gloss";
    return($key,$data);
}


