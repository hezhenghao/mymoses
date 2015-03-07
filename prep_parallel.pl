## Split a raw text file containing parallel corpus of N languages into N files,
## discarding sentences with junk characters in the process.
## 
## Input file: a raw text file in the following format:
##     s1l1  (s1l1 meaning sentence #1, language #1)
##     ...
##     s1lN
##     s2l1
##     ...
##     s2lN
##     ...
## Output file: N raw text files, one for each language.
## 
## If junk characters (Unicode properties C=true or Print=false, or those belonging to 
## the CJK Unified Ideographs Extension blocks) occurs in a sentence, 
## then this sentence and its parallel sentences are discarded.

use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 <filename> <N>") if (@ARGV != 2);
my $fname = $ARGV[0];
my $nlan = $ARGV[1]; 
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
my @fhout = (0) x $nlan;
for(my $i = 0; $i < $nlan; $i++) {
	open(my $FH, ">:encoding(UTF-8)", "$fname.lan$i") or die("Can't open $fname.lan$i: $!");
	$fhout[$i] = $FH;
}
my $junkchar = qr/[\p{C}\P{Print}\p{CJK_Unified_Ideographs_Extension_A}\p{CJK_Unified_Ideographs_Extension_B}\p{CJK_Unified_Ideographs_Extension_C}]/;
my %junkcnt = ();

my $ln = 0;
my @sentence = ("") x $nlan;
while(!eof($fhin)) {
	my $bad = 0;
	for(my $ilan = 0; $ilan < $nlan; $ilan++) {
		if(eof($fhin)) {
			$bad = 1;
			print STDERR "readline failed after line $ln\n";
			last;
		}
		$_ = <$fhin>;
		$ln++;
		chomp;
		s/\s+/ /g;
		s/[\x{00}-\x{1F}\x{7F}]//g; # delete ASCII control characters without discarding the sentence
		s/\p{Cf}//g; # delete format characters without discarding the sentence
		my $junky = /$junkchar/;
		if($junky) {
			s/($junkchar)/
				if($junkcnt{$1}) {
					$junkcnt{$1}++;
				}
				else {
					$junkcnt{$1} = 1;
				}
				"{U+".sprintf("%04X",ord($1)).":$1}"
				/ge;
			print STDERR "junk in line $ln: $_\n";
			$bad = 1;
		}
		else {
			s/^\s+//;
			s/\s+$//;
			$sentence[$ilan] = $_;
		}
	}
	if(!$bad) {
		for(my $ilan = 0; $ilan < $nlan; $ilan++) {
			my $fho = $fhout[$ilan];
			print $fho $sentence[$ilan], "\n";
		}
	}
}
for my $char (keys %junkcnt) {
	print STDERR "U+", sprintf("%04X",ord($char)), " $char: $junkcnt{$char}\n";
}
close($fhin);
for(my $i = 0; $i < $nlan; $i++) {
	close($fhout[$i]);
}
