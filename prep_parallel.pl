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
use Unicode::EastAsianWidth; # must do that again for 5.8.1
require charnames;
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
open(my $fherr, ">:encoding(UTF-8)", "$fname.prep_log") or die("Can't open $fname.prep_log: $!");
#my $junkchar = qr/[\p{C}\P{Print}\p{CJK_Unified_Ideographs_Extension_A}\p{CJK_Unified_Ideographs_Extension_B}\p{CJK_Unified_Ideographs_Extension_C}]/;
my $junkchar = qr/[^\p{BasicLatin}\p{CJKUnifiedIdeographs}]/;
my %junkcnt = ();

my $ln = 0;
my @sentence = ("") x $nlan;
while(!eof($fhin)) {
	my $bad = 0;
	for(my $ilan = 0; $ilan < $nlan; $ilan++) {
		if(eof($fhin)) {
			$bad = 1;
			print $fherr "readline failed after line $ln\n";
			last;
		}
		$_ = <$fhin>;
		$ln++;
		s/\s+/ /g; # replace excessive and non-ASCII whitespace with a single space (\x{20})
		s/[\x{00}-\x{1F}\x{7F}]//g; # delete ASCII control characters
		s/\p{Cf}//g; # delete format characters
		s{(\p{InHalfwidthAndFullwidthForms})} # replace fullwidth characters with halfwidth characters
			{
				my $char = $1;
				my $name = charnames::viacode(ord($char));
				(substr($name, 0, 10) eq 'FULLWIDTH ')
					? chr(charnames::vianame(substr($name, 10)))
				: $char;
			}eg;
		# replace non-ASCII punctuations with their ASCII counterparts:
		#$line =~ tr/“”‘’‐—「」/""''--""/;
		s/[\N{HYPHEN}\N{NON-BREAKING HYPHEN}\N{FIGURE DASH}\N{EN DASH}\N{EM DASH}\N{HORIZONTAL BAR}\N{HYPHEN BULLET}\N{BOX DRAWINGS LIGHT HORIZONTAL}\N{MINUS SIGN}\N{BULLET}\N{MIDDLE DOT}]/\-/g;
		s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}\N{SINGLE LOW-9 QUOTATION MARK}\N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}\N{PRIME}\N{REVERSED PRIME}\N{SINGLE LEFT-POINTING ANGLE QUOTATION MARK}\N{SINGLE RIGHT-POINTING ANGLE QUOTATION MARK}]/\'/g;
		s/[\N{LEFT DOUBLE QUOTATION MARK}\N{RIGHT DOUBLE QUOTATION MARK}\N{DOUBLE LOW-9 QUOTATION MARK}\N{DOUBLE HIGH-REVERSED-9 QUOTATION MARK}\N{DOUBLE PRIME}\N{REVERSED DOUBLE PRIME}\N{LEFT DOUBLE ANGLE BRACKET}\N{RIGHT DOUBLE ANGLE BRACKET}\N{LEFT CORNER BRACKET}\N{RIGHT CORNER BRACKET}\N{LEFT WHITE CORNER BRACKET}\N{RIGHT WHITE CORNER BRACKET}\N{REVERSED DOUBLE PRIME QUOTATION MARK}\N{DOUBLE PRIME QUOTATION MARK}\N{LOW DOUBLE PRIME QUOTATION MARK}]/\"/g;
		s/[\N{LEFT SQUARE BRACKET WITH QUILL}\N{LEFT BLACK LENTICULAR BRACKET}\N{LEFT TORTOISE SHELL BRACKET}\N{LEFT WHITE LENTICULAR BRACKET}\N{LEFT WHITE TORTOISE SHELL BRACKET}\N{LEFT WHITE SQUARE BRACKET}]/\[/g;
		s/[\N{RIGHT SQUARE BRACKET WITH QUILL}\N{RIGHT BLACK LENTICULAR BRACKET}\N{RIGHT TORTOISE SHELL BRACKET}\N{RIGHT WHITE LENTICULAR BRACKET}\N{RIGHT WHITE TORTOISE SHELL BRACKET}\N{RIGHT WHITE SQUARE BRACKET}]/\]/g;
		s/[\N{LOW ASTERISK}\N{FLOWER PUNCTUATION MARK}\N{DOTTED CROSS}\N{ASTERISK OPERATOR}\N{BULLET OPERATOR}\N{DOT OPERATOR}\N{STAR OPERATOR}]/\*/g;
		s/[\N{FRACTION SLASH}\N{DIVISION SLASH}]/\//g;
		s/[\N{SET MINUS}]/\\/g;
		s/[\N{DIVIDES}]/\|/g;
		s/[\N{SWUNG DASH}\N{WAVE DASH}]/\~/g;
		s/[\N{TWO DOT PUNCTUATION}\N{RATIO}]/\:/g;
		s/[\N{IDEOGRAPHIC COMMA}]/\,/g;
		s/[\N{IDEOGRAPHIC FULL STOP}]/\./g;
		s/[\N{LEFT ANGLE BRACKET}]/\</g;
		s/[\N{RIGHT ANGLE BRACKET}]/\>/g;
		s/\N{HORIZONTAL ELLIPSIS}/.../g;
		s/\N{DOUBLE EXCLAMATION MARK}/!!/g;
		s/\N{DOUBLE QUESTION MARK}/??/g;
		s/\N{QUESTION EXCLAMATION MARK}/?!/g;
		s/\N{EXCLAMATION QUESTION MARK}/!?/g;
		
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
			print $fherr "junk in line $ln: $_\n";
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
	print $fherr "U+", sprintf("%04X",ord($char)), " $char: $junkcnt{$char}\n";
}
close($fhin);
for(my $i = 0; $i < $nlan; $i++) {
	close($fhout[$i]);
}
