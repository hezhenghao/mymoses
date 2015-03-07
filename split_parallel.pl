## Split a raw text file containing parallel corpus of N languages into N files.
## Input file: a raw text file in the following format:
##     s1l1  (s1l1 meaning sentence #1, language #1)
##     ...
##     s1lN
##     s2l1
##     ...
##     s2lN
##     ...
## Output file: N raw text files, one for each language.

use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl split_parallel.pl <filename> <N>") if (@ARGV != 2);
my $fname = $ARGV[0];
my $nlan = $ARGV[1]; 
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
my @fhout = (0) x $nlan;
for(my $i = 0; $i < $nlan; $i++) {
	open(my $FH, ">:encoding(UTF-8)", "$fname.lan$i") or die("Can't open $fname.lan$i: $!");
	$fhout[$i] = $FH;
}
my $ln = 0;
while(!eof($fhin)) {
	my $line = <$fhin>;
	my $FH = $fhout[$ln % $nlan];
	print $FH $line;
	$ln++;
}
if ($ln % $nlan != 0) {
	print STDOUT "Warning: Total number of sentences in $fname is not a multiple of $nlan.\n";
}
close($fhin);
for(my $i = 0; $i < $nlan; $i++) {
	close($fhout[$i]);
}
