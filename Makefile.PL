use ExtUtils::MakeMaker;

print "NOTE: Before making this module, you should run scripts/convertdb.pl to\nconvert your Wordnet files. The tests will fail if you haven't.\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Lingua::Wordnet',
    'VERSION_FROM' => 'Wordnet.pm', # finds $VERSION
);

