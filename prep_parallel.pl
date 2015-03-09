## Split a raw text file containing parallel corpus of N languages into N files,
## discarding sentences with junk characters in the process.
##
## SYNOPSIS
##     PROGRAMNAME <filename> <N> ['lan1 ... lanN']
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
## If lan1 ... lanN are specified, the file extensions of the output files will be the corresponding language codes.
## Otherwise the file extensions will be "lan0" ... "lan<N-1>"
## 
## Non-ASCII punctuation characters are replaced by their ASCII counterparts.
## A number of string patterns are replaced by XML tags:
##    <EMAIL>       email addresses
##    <URL>         URLs
##    <IDEN>        identifiers (strings that mostly consist of ASCII letters, but also contain digits and/or underscores)
##    <REFERID>     "@" followed by a string of (possibly non-ASCII) letters, digits and underscores
##    <GREEK>       Greek letters
##    <NUM>         numbers (optionally with fractional part and/or power of 10)
##    <NUM RM>      Roman numerals
##    <NUM EN ORD>  English ordinal numbers with mixed digits and letters (e.g. 11th)
##    <CIRCLE>      various circles which can be used as ideographic zeros
##    <TIMES>       cross-shaped characters used in multiplication
##    <DEGREE>      the degree mark (U+00B0)
## After the replacement with XML tags, the following characters will be considered junk and the sentence pairs (or sets)
## containing them will be discarded: ` @ # ^ * + = { } | \ and all the non-ASCII characters with Unicode property IsLetter=false.
## If language codes are specified, non-ASCII letter characters that are not orthographic to the language in question are also discarded. 
## Currently the following languages are supported for this function: en zh de fr jp

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 <filename> <N> ['lan1 ... lanN']") if (@ARGV < 2 || @ARGV > 3);
my $fname = $ARGV[0];
my $nlan = $ARGV[1];
my @lans = ('') x $nlan;
if(@ARGV == 3) {
	@lans = split(" ", $ARGV[2], $nlan);
	print "$nlan languages: ", join(', ', @lans), "\n";
}
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
my @fhout = (0) x $nlan;
for(my $i = 0; $i < $nlan; $i++) {
	my $exten = ($lans[$i])? $lans[$i] : "lan$i";
	open(my $FH, ">:encoding(UTF-8)", "$fname.$exten") or die("Can't open $fname.$exten: $!");
	$fhout[$i] = $FH;
}
open(my $fherr, ">:encoding(UTF-8)", "$fname.prep_log") or die("Can't open $fname.prep_log: $!");
#my $junkchar = qr/[\p{C}\P{Print}\p{CJK_Unified_Ideographs_Extension_A}\p{CJK_Unified_Ideographs_Extension_B}\p{CJK_Unified_Ideographs_Extension_C}]/;
#my $junkchar = qr/[^\p{BasicLatin}\p{CJKUnifiedIdeographs}]/;
my $junkchar = qr/[^\p{L}\p{ASCII}]/;
my %junkcnt = ();
# define allowable letter characters for different languages
my %letterchars = (
					'en', qr/[a-zé]/i,
					'zh', qr/[A-Za-z\p{CJKUnifiedIdeographs}]/,
					'de', qr/[a-zäöüß]/i,
					'fr', qr/[a-zçéàèùâêîôûëïüÿñœæ]/i,
					'jp', qr/[A-Za-z\p{CJKUnifiedIdeographs}\p{Katakana}\p{Hiragana}]/,
					);

# a set of regular expressions
my $domain = qr/([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}/i;
my $protocol = qr{(http[s]?|ftp)://}i;
my $path = qr/([a-z0-9_\-\.\/]|%[0-9a-f]{2})+/i;
my $query = qr/([a-z0-9*_=&\+\-\.]|%[0-9a-f]{2})+/i;
my $fragid = qr/[a-z0-9_\.]+/i;
my $email = qr/[a-z0-9_\-\.]+\@$domain/i;
my $url = qr/$protocol$domain(:[0-9]+)?(\/$path(\?$query)?(\#$fragid)?)?/i;
my $number = qr/[0-9]+(\.[0-9]+)?(<TIMES>10\^?[0-9]+)?/;
my $numorden = qr/[0-9]+(1\-?st|2\-?nd|3\-?rd|[0-9]\-?th)/i;
my $xmltag = qr/<[^>]+>/;
#my $clause_a = qr/([\p{L}\'\"\(\$]|$xmltag)/;
#my $clause_z = qr/([\p{L}\'\"\)\%]|$xmltag)/;
#my $clause_m = qr/([\p{L}\'\"\(\)\$\%\~\&\-\/\. ]|$xmltag)/;
#my $clause = qr/($clause_a($clause_m)*$clause_z|\p{L}|$xmltag)/;
#my $clp = qr/$clause[,;:!?]/; # clp: clause with punctuation
#my $clpz = qr/$clause([;\.]|[!?]+|\.{3,6})/;
#my $sentence = qr/(\"?\p{L}([\p{L},;:%&\$\/\(\)\-\|\'\"\!\?\. ]|<[^>]+>)*\p{L}\"?(;|\.|[!?]+|\.\.\.)\"?)/;
#my $sentence = qr/(($clp|\($clp\)|\'$clp\'|\"$clp\") ?)*($clpz|\($clpz\)|\'$clpz\'|\"$clpz\")/;
#my $sentence = qr/($clp[\'\"\)]? ?)*$clpz[\'\"\)]?/;

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
		# replace email address with XML tag
		s/$email/<EMAIL>/ig;
		# replace URL with XML tag
		s/$url/<URL>/ig;
		# replace English ordinal number (mixed digit-letter form) with XML tag
		s/$numorden/<NUM EN ORD>/ig;
		# replace identifiers with XML tag
		s/@\w+/<REFERID>/g;
		s{([A-Za-z0-9_]+)}
			{
				my $str = $1;
				($str =~ m/[A-Za-z]/ && ($str =~ m/_/ || $str =~ m/[0-9]/))?
					"<IDEN>"
					: $str;
			}eg;
		# replace fullwidth characters with halfwidth characters
		s{(\p{InHalfwidthAndFullwidthForms})}
			{
				my $char = $1;
				my $name = charnames::viacode(ord($char));
				(substr($name, 0, 10) eq 'FULLWIDTH ')?
					chr(charnames::vianame(substr($name, 10)))
					: $char;
			}eg;
		# replace non-ASCII punctuations with their ASCII counterparts:
		s/[\N{HYPHEN}\N{NON-BREAKING HYPHEN}\N{FIGURE DASH}\N{EN DASH}\N{EM DASH}\N{HORIZONTAL BAR}\N{HYPHEN BULLET}\N{BOX DRAWINGS LIGHT HORIZONTAL}\N{MINUS SIGN}]/\-/g;
		s/[\N{BULLET}\N{MIDDLE DOT}\N{KATAKANA MIDDLE DOT}\N{BULLET OPERATOR}\N{DOT OPERATOR}]/-/g;
		s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}\N{SINGLE LOW-9 QUOTATION MARK}\N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}\N{PRIME}\N{REVERSED PRIME}\N{SINGLE LEFT-POINTING ANGLE QUOTATION MARK}\N{SINGLE RIGHT-POINTING ANGLE QUOTATION MARK}`]/\'/g;
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
		# replace currency symbols with dollar sign
		s/\p{Sc}/\$/g;
		## replace certain symbols with letters and/or numbers
		#s/\N{LATIN SMALL LETTER E WITH ACUTE}/e/g; # replace acute e with normal e
		#tr/\N{ROMAN NUMERAL ONE}-\N{ROMAN NUMERAL NINE}\N{SMALL ROMAN NUMERAL ONE}-N{SMALL ROMAN NUMERAL NINE}/1-91-9/;
		# replace numbers and certain symbols with XML tags
		s/[\N{MULTIPLICATION SIGN}\N{MULTIPLICATION X}\N{HEAVY MULTIPLICATION X}\N{CROSS MARK}\N{N-ARY TIMES OPERATOR}\N{VECTOR OR CROSS PRODUCT}]/<TIMES>/g;
		s/[\N{COMBINING ENCLOSING CIRCLE}\N{WHITE CIRCLE}\N{LARGE CIRCLE}\N{IDEOGRAPHIC NUMBER ZERO}]/<CIRCLE>/g;
		s/[\N{GREEK CAPITAL LETTER ALPHA}-\N{GREEK CAPITAL LETTER OMEGA}\N{GREEK SMALL LETTER ALPHA}-\N{GREEK SMALL LETTER OMEGA}]/<GREEK>/g;
		s/[\N{ROMAN NUMERAL ONE}-\N{ROMAN NUMERAL TWELVE}\N{SMALL ROMAN NUMERAL ONE}-\N{SMALL ROMAN NUMERAL TWELVE}]/<NUM RM>/g;
		s/\N{DEGREE SIGN}/<DEGREE>/g;
		s/\N{DEGREE CELSIUS}/<DEGREE>C/g;
		s/\N{DEGREE FAHRENHEIT}/<DEGREE>F/g;
		s/$number/<NUM>/g;
		
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
			#my $wellformed =  (scalar(() = m/\(/g) == scalar(() = m/\)/g)) && (scalar(() = m/\"/g) % 2 == 0)
			#				&& m/^($clause|$sentence)$/;
			#my $wellformed = m/^([\p{L}0-9~!\$%&\(\)\-\[\];:\'\",\.\?\/ ]|$xmltag)+$/;
			my $lanchar = $letterchars{$lans[$ilan]};
			my $letter = ($lanchar)? $lanchar : qr/\p{L}/;
			my $wellformed = m/^($letter|[0-9~!\$%&\(\)\-\[\];:\'\",\.\?\/ ]|$xmltag)+$/;
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
