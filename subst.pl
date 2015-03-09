## Match a RegEx pattern and substitute with something else
use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 pattern replacement <infile >outfile") if (@ARGV != 2);
my $patt = $ARGV[0];
my $repl = $ARGV[1]; 
while(<STDIN>) {
	s/$patt/$repl/g;
	print $_;
}
