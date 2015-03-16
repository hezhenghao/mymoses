## Match a RegEx pattern and substitute with something else
use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 filename N_sentence") if (@ARGV != 2);
my $fname = $ARGV[0];
my $n_sents = $ARGV[1];
my $minlen = 1;
my $maxlen = 80;

# get number of lines in the corpus
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
my $n_lines = 0;
while(<$fhin>) {
	$n_lines++;
}
my $seg_sz = int($n_lines / $n_sents); # size of each segment
close($fhin);
die("Not enough lines in the corpus file: Only $n_lines lines.") if ($seg_sz < 1);

# get a sentence from each segment
my $offset = int(rand($seg_sz));
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
open(my $fhout, ">:encoding(UTF-8)", "$fname.shk") or die("Can't open $fname.shk: $!");
my $ln = 0;
my $n_copied = 0;
my $debt = 0;
while(<$fhin>) {
	$ln++;
	if($ln % $seg_sz != $offset && $debt <= 0) {
		next;
	}
	chomp;
	if(/(\p{C})/) {
		print STDERR "control character U+", sprintf("%04X", ord($1)), " in line $ln, skipped\n\tcontent: $_\n";
		$debt++ if($ln % $seg_sz == $offset);
		next;
	}
	my $n_words = scalar(split(/\W+/));
	if($n_words < $minlen || $n_words > $maxlen) {
		print STDERR "word count is $n_words in line $ln, skipped\n\tcontent: $_\n";
		$debt++ if($ln % $seg_sz == $offset);
		next;
	}
	print $fhout $_, "\n";
	$n_copied++;
	if($ln % $seg_sz != $offset) {
		$debt--;
		print STDERR "debt repaid at line $ln, $n_copied lines copied\n";
	}
	last if($n_copied >= $n_sents);
}
close($fhin);
close($fhout);
