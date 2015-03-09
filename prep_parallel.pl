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
use Unicode::EastAsianWidth;
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
		# replace email address with XML tag
		my $domain = qr/([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}/i;
		s/[a-z0-9_\-\.]\@$domain/<EMAIL>/ig;
		# replace URL with XML tag
		my $protocol = qr{(http[s]?|ftp)://}i;
		my $path = qr/([a-z0-9_\-\.\/]|%[0-9a-f]{2})+/i;
		my $query = qr/([a-z0-9*_=&\+\-\.]|%[0-9a-f]{2})+/i;
		my $fragid = qr/[a-z0-9_\.]+/i;
		s/($protocol)?$domain(:[0-9]+)(\/$path(\?$query)?(\#$fragid)?)?/<URL>/ig;
		# replace non-ASCII punctuations with their ASCII counterparts:
		s/[\N{HYPHEN}\N{NON-BREAKING HYPHEN}\N{FIGURE DASH}\N{EN DASH}\N{EM DASH}\N{HORIZONTAL BAR}\N{HYPHEN BULLET}\N{BOX DRAWINGS LIGHT HORIZONTAL}\N{MINUS SIGN}]/\-/g;
		s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}\N{SINGLE LOW-9 QUOTATION MARK}\N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}\N{PRIME}\N{REVERSED PRIME}\N{SINGLE LEFT-POINTING ANGLE QUOTATION MARK}\N{SINGLE RIGHT-POINTING ANGLE QUOTATION MARK}]/\'/g;
		s/[\N{LEFT DOUBLE QUOTATION MARK}\N{RIGHT DOUBLE QUOTATION MARK}\N{DOUBLE LOW-9 QUOTATION MARK}\N{DOUBLE HIGH-REVERSED-9 QUOTATION MARK}\N{DOUBLE PRIME}\N{REVERSED DOUBLE PRIME}\N{LEFT DOUBLE ANGLE BRACKET}\N{RIGHT DOUBLE ANGLE BRACKET}\N{LEFT CORNER BRACKET}\N{RIGHT CORNER BRACKET}\N{LEFT WHITE CORNER BRACKET}\N{RIGHT WHITE CORNER BRACKET}\N{REVERSED DOUBLE PRIME QUOTATION MARK}\N{DOUBLE PRIME QUOTATION MARK}\N{LOW DOUBLE PRIME QUOTATION MARK}]/\"/g;
		s/[\N{LEFT SQUARE BRACKET WITH QUILL}\N{LEFT BLACK LENTICULAR BRACKET}\N{LEFT TORTOISE SHELL BRACKET}\N{LEFT WHITE LENTICULAR BRACKET}\N{LEFT WHITE TORTOISE SHELL BRACKET}\N{LEFT WHITE SQUARE BRACKET}]/\[/g;
		s/[\N{RIGHT SQUARE BRACKET WITH QUILL}\N{RIGHT BLACK LENTICULAR BRACKET}\N{RIGHT TORTOISE SHELL BRACKET}\N{RIGHT WHITE LENTICULAR BRACKET}\N{RIGHT WHITE TORTOISE SHELL BRACKET}\N{RIGHT WHITE SQUARE BRACKET}]/\]/g;
		s/[\N{LOW ASTERISK}\N{FLOWER PUNCTUATION MARK}\N{DOTTED CROSS}\N{ASTERISK OPERATOR}\N{STAR OPERATOR}]/\*/g;
		s/[\N{FRACTION SLASH}\N{DIVISION SLASH}]/\//g;
		s/[\N{SET MINUS}]/\\/g;
		s/[\N{DIVIDES}]/\|/g;
		s/[\N{SWUNG DASH}\N{WAVE DASH}]/\~/g;
		s/[\N{TWO DOT PUNCTUATION}\N{RATIO}\N{PRESENTATION FORM FOR VERTICAL TWO DOT LEADER}\N{PRESENTATION FORM FOR VERTICAL COLON}\N{SMALL COLON}]/\:/g;
		s/[\N{IDEOGRAPHIC COMMA}\N{SMALL COMMA}\N{SMALL IDEOGRAPHIC COMMA}\N{SESAME DOT}\N{PRESENTATION FORM FOR VERTICAL IDEOGRAPHIC COMMA}]/\,/g;
		s/[\N{IDEOGRAPHIC FULL STOP}]/\./g;
		s/[\N{LEFT ANGLE BRACKET}]/\</g;
		s/[\N{RIGHT ANGLE BRACKET}]/\>/g;
		s/\N{HORIZONTAL ELLIPSIS}/.../g;
		s/\N{DOUBLE EXCLAMATION MARK}/!!/g;
		s/\N{DOUBLE QUESTION MARK}/??/g;
		s/\N{QUESTION EXCLAMATION MARK}/?!/g;
		s/\N{EXCLAMATION QUESTION MARK}/!?/g;
		# replace certain symbols with letters and/or numbers
		s/\N{LATIN SMALL LETTER E WITH ACUTE}/e/g; # replace acute e with normal e
		#tr/\N{ROMAN NUMERAL ONE}-\N{ROMAN NUMERAL NINE}\N{SMALL ROMAN NUMERAL ONE}-N{SMALL ROMAN NUMERAL NINE}/1-91-9/;
		# replace numbers and certain symbols with XML tags
		s/[\N{BULLET}\N{MIDDLE DOT}\N{KATAKANA MIDDLE DOT}\N{BULLET OPERATOR}\N{DOT OPERATOR}]/<MIDDOT>/g;
		s/[\N{MULTIPLICATION SIGN}\N{MULTIPLICATION X}\N{HEAVY MULTIPLICATION X}\N{CROSS MARK}\N{N-ARY TIMES OPERATOR}\N{VECTOR OR CROSS PRODUCT}]/<TIMES>/g;
		s/[\N{COMBINING ENCLOSING CIRCLE}\N{WHITE CIRCLE}\N{LARGE CIRCLE}\N{IDEOGRAPHIC NUMBER ZERO}]/<CIRCLE>/g;
		s/[\N{GREEK CAPITAL LETTER ALPHA}-\N{GREEK CAPITAL LETTER OMEGA}\N{GREEK SMALL LETTER ALPHA}-\N{GREEK SMALL LETTER OMEGA}]/<GREEK>/g;
		s/\N{DEGREE SIGN}/<DEGREE>/g;
		s/\N{DEGREE CELSIUS}/<DEGREE>C/g;
		s/\N{DEGREE FAHRENHEIT}/<DEGREE>F/g;
		s/[0-9]+(\.[0-9]+)?(<TIMES>10\^?[0-9]+)?/<NUM>/g;
		
		my $junky = m/$junkchar/;
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
			s/\s+/ /g;
			s/^\s+//;
			s/\s+$//;
			my $wellformed = m/^[\"\']?\p{L}([\p{L}_,;:%&\$\/\(\)\-\|\'\"\!\?\. ]|<[^>]+>)*(\.|[!?]{1,2}|\.\.\.)[\"\']?$/;
			if(!$wellformed) {
				print $fherr "ill-formed sentence in line $ln: $_\n";
				$bad = 1;
			}
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
