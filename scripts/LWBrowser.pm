# This interface requires that Lingua::Wordnet be installed and
# configured, as well as mod_perl. It is woefully incomplete, 
# but serves as an example of such an interface.
#
# To use it, copy it to the perl lib location for mod_perl 
# (/usr/local/apache/lib/perl/, etc.) and add these lines to your
# httpd.conf:
#
# PerlModule LWBrowser
# <Location /wn>
#    SetHandler perl-script
#    PerlHandler LWBrowser
#</Location>
#
# You can then use it at http://hostname/wn
#

package LWBrowser;

use strict;
use Apache::Constants ':common';
use Lingua::Wordnet;

my @pos = ("n","v","a","r");
my %poses = (
    "n" => "noun",
    "v" => "verb",
    "a" => "adjective",
    "r" => "adverb"
);
my @datatypes = ("antonyms","hypernyms", "hyponyms", 
    "entailment","comp_meronyms","member_meronyms","stuff_meronyms",
    "portion_meronyms","feature_meronyms","place_meronyms","phase_meronyms",
    "comp_holonyms","member_holonyms","stuff_holonyms","portion_holonyms",
    "feature_holonyms","place_holonyms","phase_holonyms","attributes",
    "functions","causes","pertainyms");
my %subst;
my %escapes;
for (0..255) {
    $escapes{chr($_)} = sprintf("%%%02X", $_);
}

sub handler {
    my $r = shift;
    my %params = ($r->content, $r->args);   
    my $content;
 
    $r->content_type('text/html');
    $r->send_http_header;
    
    if (exists($params{search})) {
        # this is a word search
        $content = do_search($params{word});
    } elsif (exists($params{help})) {
        # this is a cry for help
        $content = do_help($params{type}); 
        $r->print($content);
        return OK;
    } elsif (exists($params{edit})) {
        # editing a synset entry
    } elsif (exists($params{offset})) {
        $content = do_lookup(%params); 
    }

    $r->print(header());
    $r->print($content);
    $r->print(footer());
    return OK;
}



sub do_lookup {
    my (%params) = @_;
    my $offset = $params{offset};
    my $content;
    my $wn = new Lingua::Wordnet;
    my $synset = $wn->lookup_synset_offset($offset);
    if (!$offset) {
        $wn->close;
        return "Error: Offset $offset not found.";
    }
    $content = "<tr><td width='50%'><font size=+1 color=blue><b>";
    my $words = join(", ",$synset->words);
    $words =~ s/\%\d+//g;
    $words =~ s/\_/ /g;
    $content .= $words;
    $content .= "</b></font> (" . $synset->offset . ")</font><br></td>";
    $content .= "<form name='Display' METHOD=POST action='/wn'>\n<td
width='50%'>";
    $content .= "<p align=right><input type=submit name='refresh' value='refresh'></p>\n";
    $content .= "<input type=hidden name='offset' value='$offset'>\n";
    $content .= "<input type=hidden name='word' value='" . $params{word} .  "'>\n";
    $content .= "</td></tr><tr><td bgcolor=black>&nbsp;&nbsp;<font color=white><b>gloss</b></font></td><td bgcolor=black><font color=white size=1>&nbsp;&nbsp;<a href=''>edit</a> | <a href='javascript:openwin_s(\"gloss\")'>help</a></font></td></tr>\n";
    $content .= "<tr><td colspan=2 width='100%' bgcolor=black valign=top align=right><table width='100%' border=0 cellpadding=4 cellspacing=0><tr><td valign=top bgcolor=silver>" . $synset->gloss . "</td></tr></table></tr></td>\n";
    my $datatype;
    my $count = 0;
    foreach $datatype (@datatypes) {
        my $temp = $datatype;
        $count++;
        $content .= "<input type=hidden name='$count' value='" . $params{$count} .  "'>\n";
        $temp =~ s/\_/ /g;
        my @synsets;
        eval "\@synsets = \$synset->$datatype";
        if ($@) { die "eval error: $@"; }
        $content .= "<tr><td width='50%' bgcolor=black><a name='$temp'></a>&nbsp;&nbsp;<font color=white><b><font color=white>$temp: " . scalar(@synsets) . "</b></td><td bgcolor=black>&nbsp;<font size=1 color=white><a href='javascript:openlist($count,\"$temp\")'>expand</a> | <a href='javascript:closelist($count)'>collapse</a> | add | <a href='javascript:openwin_s(\"$temp\")'>help</a></font></td></tr>\n";
        if ($params{$count} > 0) {
          foreach (@synsets) {
            my $words = join(", ",$_->words);
            $words =~ s/\%\d+//g;
            $words =~ s/\_/ /g;
            $content .= "<tr><td colspan=2 width=100% bgcolor=black valign=top align=right><table width='100%' border=0 cellpadding=4 cellspacing=0><tr><td valign=top bgcolor=silver width='40%'>" . $words . "</td><td bgcolor=silver><font size=1><a href='/wn?offset=" . $_->offset . "'><font color=black>open</font></a> | delete | move </font></td></tr></table></tr></td>";
          }
       }
    }
    $content .= "</form>\n";
    $wn->close;
    $content;
}



sub do_search {
    my $word = shift;
    my $content;
    my $wn = new Lingua::Wordnet;

    $content .= "<tr><td>Search for: <b>" . $word . "</b></td></tr>\n";
    foreach (@pos) {
        $content .= "<tr><td colspan=2 bgcolor=black>&nbsp;<font color=white size=-1><b>" . $poses{$_} . "</b></td></tr>\n";
        my @synsets = ();
        foreach ($wn->lookup_synset($word,$_)) {
            $content .= "<tr><td width='40%' bgcolor=black valign=top align=right><table width='100%' border=0 cellpadding=4 cellspacing=0><tr><td valign=top bgcolor=silver>";
            $content .= "\n<a href='/wn?offset=" . escape($_->offset) .  "&word=" . escape($word) ."'><font color=blue>";
            my $words = join(", ",$_->words);
            $words =~ s/\%\d+//g;
            $words =~ s/\_/ /g;
            $content .= $words;
            $content =~ s/\,\s$//;
            $content .= "</a>";
            $content .= "</td><td width='60%' valign=top bgcolor=silver>" . $_->gloss . 
                "</td></tr></table></td></tr>\n";
        }
    }

    $wn->close;
    return $content;
}


sub header {
    my $content = <<HERE;
<html>
<head><title>LWBrowser</title>
<SCRIPT LANGUAGE="JavaScript">
<!--
     NS4 = (document.layers);
     IE4 = (document.all);
    ver4 = (NS4 || IE4);
   isMac = (navigator.appVersion.indexOf("Mac") != -1);
  isMenu = (NS4 || (IE4 && !isMac));
 
  function popUp(){return};
  function popDown(){return};
  function startIt(){return};
 
  if (!ver4) event = null;
//-->
</SCRIPT>           
<SCRIPT LANGUAGE="JavaScript1.2">
<!--
  if (isMenu) {
      menuVersion = 3;
 
      menuWidth = 120;
      childOverlap = 50;
      childOffset = 5;
      perCentOver = null;
      secondsVisible = .5;
 
      fntCol = "#000000";
      fntSiz = "8";
      fntBold = false;
      fntItal = false;
      fntFam = "helvetica";
 
      backCol = "#dcdcdc";
      overCol = "#ffffff";
      overFnt = "#000000";
 
      borWid = 1;
      borCol = "black";
      borSty = "solid";
      itemPad = 2;
 
      imgSrc = "images/arrow.gif";
      imgSiz = 7;
 
      separator = 0;
      separatorCol = "red";
 
      isFrames = false;
      navFrLoc = "left";
 
      keepHilite = true;
      NSfontOver = true;
      clickStart = true;
      clickKill = true;
 
HERE

#my $count = 0;
#foreach (@datatypes) {
#    $count++;
#    $content .= "\narMenu$count = new Array(\n";
#    $content .= "    110,\n";
#    $content .= "    '','',\n";
#    $content .= "    '','',\n";
#    $content .= "    '','',\n";
#    $content .= "    '','',\n";
#    $content .= "    'Open','javascript:openlist($count)',0,\n";
#    $content .= "    'Close','javascript:closelist($count)',0,\n";
#    $content .= "    'Help','javascript:openwin_s(\"/wn?type=$_&help\")',0\n";
#    $content .= ")\n";
#}

$content .= <<HERE;
}
//-->
</SCRIPT>
<SCRIPT LANGUAGE="JavaScript">
function openwin_s(type) {
    var win = window.open("/wn?type=" + type + "&help", "", "width=300,height=200");
}
function openlist(num,type) {
    document.Display.elements[num+2].value = 1;
    document.Display.action = document.Display.action + "#" + type;
    document.Display.submit();
}
function closelist(num) {
    document.Display.elements[num+2].value = 0;
    document.Display.submit();
}
</SCRIPT>
</head>

<body bgcolor="#ffffff" link="#ffffff" vlink="#ffffff" alink="#ffffff">
<p>
<b>Lingua::Wordnet Browser</b> &nbsp; &nbsp; &nbsp; &nbsp;<br>
<form name="search" method=POST action="/wn?search"><input name="word" size=20>
<input type=submit name="search" value="search"></form>
</p>

<table border=0 width='100%' cellpadding=1 cellspacing=1>

HERE

    return $content;
}

sub footer {
    return <<HERE;
</table>
<br>

<p>
<font size=2><a href="http://www.brians.org/wordnet/">http://www.brians.org/wordnet/</a></font><br>
</p>

</body>
</html>

HERE
}

sub do_help {
    my $type = shift;
    my $content;
    $content = <<END;
<html><body bgcolor='#dcdcdc'>
<p><b>Lingua::Wordnet Browser Help</b></p>
END
    #$content .= "<p><i>" . $type . "</i></p>\n";
    for ($type) {
        $content .= 
            /^gloss/ && "<p>A <b>gloss</b> is a short definition of the <a href='/wn?type=synset&help'>synset</a> as might be found in a dictionary.</p>\n"
           || /^synset/ && "<p>A <b>synset</b> is a single collection of synonyms in Wordnet:</p> <p>&nbsp;<u>synset</u>: dog, domestic dog, Canis familiaris</p>\n"       || /^antonyms/ && "<p>An <b>antonym</b> is the opposite or opposing sense of a word:</p> <p>&nbsp;'Unkind' is the antonym of 'kind'.</p>";
    }
    $content .= "</body></html>\n";
    return $content;
}

# from URI.pm, included for convenience
sub escape {
    my($text, $patn) = @_;
    return undef unless defined $text;
    if (defined $patn){
    unless (exists  $subst{$patn}) {
        # Because we can't compile the regex we fake it with a cached sub
        $subst{$patn} =
          eval "sub {\$_[0] =~ s/([$patn])/\$escapes{\$1}/g; }";
        die("uri_escape: $@") if $@;
    }
    &{$subst{$patn}}($text);
    } else {
    # Default unsafe characters. (RFC 2396 ^uric)
    $text =~ s/([^;\/?:@&=+\$,A-Za-z0-9\-_.!~*'()])/$escapes{$1}/g;
    }
    $text;
}

1;

