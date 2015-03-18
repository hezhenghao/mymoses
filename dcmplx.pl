## De-complicate a text file.
##
## Non-ASCII punctuation characters are replaced by their ASCII counterparts. (Also backticks "`" are replaced by apostrophes "'")
## A number of string patterns are replaced by XML tags:
##    <EMAIL>       email addresses
##    <URL>         URLs
##    <IDEN>        identifiers (strings that mostly consist of ASCII letters, but also contain digits and/or underscores)
##    <GREEK>       Greek letters
##    <NUM>         numbers (optionally with fractional part and/or power of 10)
##    <NUM RM>      Roman numerals
##    <NUM EN ORD>  English ordinal numbers with mixed digits and letters (e.g. 11th)
##    <ENCLOSED>    characters from the Unicode block "Enclosed Alphanumerics"
##    <CIRCLE>      various circles which can be used as ideographic zeros
##    <CROSS>       cross-shaped characters used in multiplication
##    <DEGREE>      the degree mark (U+00B0)

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 <filename> [[-]euignrEctd]") if (@ARGV < 1 || @ARGV > 2);
my $fname = $ARGV[0];
open(my $fhin, "<:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
open(my $fhout, ">:encoding(UTF-8)", "$fname.dcx") or die("Can't open $fname.dcx: $!");
#open(my $fherr, ">:encoding(UTF-8)", "$fname.dcx_log") or die("Can't open $fname.dcx_log: $!");

# a set of regular expressions
my $domain = qr/([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}/i;
my $protocol = qr{(http[s]?|ftp)://}i;
my $path = qr/([a-z0-9_\-\.\/]|%[0-9a-f]{2})+/i;
my $query = qr/([a-z0-9*_=&\+\-\.]|%[0-9a-f]{2})+/i;
my $fragid = qr/[a-z0-9_\.]+/i;
my $email = qr/[a-z0-9_\-\.]+\@$domain/i;
my $url = qr/($protocol|www.)$domain(:[0-9]+)?(\/($path(\?$query)?(\#$fragid)?)?)?/i;
my $number = qr/[0-9]+(\.[0-9]+)?(<TIMES>10\^?[0-9]+)?/;
my $numorden = qr/\b[0-9]+(1\-?st|2\-?nd|3\-?rd|[0-9]\-?th)\b/i;
my $xmltag = qr/<[A-Za-z]+( [^>]+)>/;

my $ln = 0;
while(!eof($fhin)) {
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
	s/[a-z][a-z0-9_]*[0-9_][a-z0-9_]*/<IDEN>/ig;
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
	s/[\N{BULLET}\N{MIDDLE DOT}\N{KATAKANA MIDDLE DOT}\N{BULLET OPERATOR}\N{DOT OPERATOR}]/\-/g; # In some cases maybe it's more desirable to replace with "." or "*".
	s/[\N{LEFT SINGLE QUOTATION MARK}\N{RIGHT SINGLE QUOTATION MARK}\N{SINGLE LOW-9 QUOTATION MARK}\N{SINGLE HIGH-REVERSED-9 QUOTATION MARK}\N{PRIME}\N{REVERSED PRIME}\N{SINGLE LEFT-POINTING ANGLE QUOTATION MARK}\N{SINGLE RIGHT-POINTING ANGLE QUOTATION MARK}\N{ACUTE ACCENT}]/\'/g;
	s/\`/\'/g; # In some cases maybe it's more desirable not to replace the backtick.
	s/[\N{LEFT ANGLE BRACKET}\N{RIGHT ANGLE BRACKET}]/\'/g; # In some cases maybe it's more desirable to replace with "<" and ">".
	s/[\N{LEFT DOUBLE QUOTATION MARK}\N{RIGHT DOUBLE QUOTATION MARK}\N{DOUBLE LOW-9 QUOTATION MARK}\N{DOUBLE HIGH-REVERSED-9 QUOTATION MARK}\N{DOUBLE PRIME}\N{REVERSED DOUBLE PRIME}\N{LEFT CORNER BRACKET}\N{RIGHT CORNER BRACKET}\N{LEFT WHITE CORNER BRACKET}\N{RIGHT WHITE CORNER BRACKET}\N{REVERSED DOUBLE PRIME QUOTATION MARK}\N{DOUBLE PRIME QUOTATION MARK}\N{LOW DOUBLE PRIME QUOTATION MARK}]/\"/g;
	s/[\N{LEFT DOUBLE ANGLE BRACKET}\N{RIGHT DOUBLE ANGLE BRACKET}]/\"/g; # In some cases maybe it's more desirable to replace with "<<" and ">>".
	s/[\N{LEFT SQUARE BRACKET WITH QUILL}\N{LEFT BLACK LENTICULAR BRACKET}\N{LEFT TORTOISE SHELL BRACKET}\N{LEFT WHITE LENTICULAR BRACKET}\N{LEFT WHITE TORTOISE SHELL BRACKET}\N{LEFT WHITE SQUARE BRACKET}]/\[/g;
	s/[\N{RIGHT SQUARE BRACKET WITH QUILL}\N{RIGHT BLACK LENTICULAR BRACKET}\N{RIGHT TORTOISE SHELL BRACKET}\N{RIGHT WHITE LENTICULAR BRACKET}\N{RIGHT WHITE TORTOISE SHELL BRACKET}\N{RIGHT WHITE SQUARE BRACKET}]/\]/g;
	s/[\N{LOW ASTERISK}\N{FLOWER PUNCTUATION MARK}\N{DOTTED CROSS}\N{ASTERISK OPERATOR}\N{STAR OPERATOR}]/\*/g;
	s/[\N{FRACTION SLASH}\N{DIVISION SLASH}]/\//g;
	s/[\N{SET MINUS}]/\\/g;
	s/[\N{DIVIDES}]/\|/g;
	s/[\N{SWUNG DASH}\N{WAVE DASH}]/\~/g; # In some cases maybe it's more desirable to replace with "-".
	s/[\N{TWO DOT PUNCTUATION}\N{RATIO}\N{PRESENTATION FORM FOR VERTICAL TWO DOT LEADER}\N{PRESENTATION FORM FOR VERTICAL COLON}\N{SMALL COLON}]/\:/g;
	s/[\N{IDEOGRAPHIC COMMA}\N{SMALL COMMA}\N{SMALL IDEOGRAPHIC COMMA}\N{SESAME DOT}\N{PRESENTATION FORM FOR VERTICAL IDEOGRAPHIC COMMA}]/\,/g;
	s/[\N{IDEOGRAPHIC FULL STOP}]/\./g;
	s/\N{HORIZONTAL ELLIPSIS}/\.\.\./g;
	s/\N{DOUBLE EXCLAMATION MARK}/\!\!/g;
	s/\N{DOUBLE QUESTION MARK}/\?\?/g;
	s/\N{QUESTION EXCLAMATION MARK}/\?\!/g;
	s/\N{EXCLAMATION QUESTION MARK}/\!\?/g;
	# replace currency symbols with dollar sign
	s/\p{Sc}/\$/g; # In some cases maybe it's more desirable not to replace the currency symbols.
	# replace numbers and certain symbols with XML tags
	s/[\N{MULTIPLICATION SIGN}\N{MULTIPLICATION X}\N{HEAVY MULTIPLICATION X}\N{CROSS MARK}\N{N-ARY TIMES OPERATOR}\N{VECTOR OR CROSS PRODUCT}]/<CROSS>/g;
	s/[\N{COMBINING ENCLOSING CIRCLE}\N{WHITE CIRCLE}\N{LARGE CIRCLE}\N{IDEOGRAPHIC NUMBER ZERO}]/<CIRCLE>/g;
	s/[\N{GREEK CAPITAL LETTER ALPHA}-\N{GREEK CAPITAL LETTER OMEGA}\N{GREEK SMALL LETTER ALPHA}-\N{GREEK SMALL LETTER OMEGA}]/<GREEK>/g;
	s/[\N{ROMAN NUMERAL ONE}-\N{ROMAN NUMERAL TWELVE}\N{SMALL ROMAN NUMERAL ONE}-\N{SMALL ROMAN NUMERAL TWELVE}]/<NUM RM>/g;
	s/[\p{EnclosedAlphanumerics}\p{EnclosedCJKLettersAndMonths}]/<ENCLOSED>/g;
	s/\N{DEGREE SIGN}/<DEGREE>/g;
	s/\N{DEGREE CELSIUS}/<DEGREE>C/g;
	s/\N{DEGREE FAHRENHEIT}/<DEGREE>F/g;
	s/$number/<NUM>/g;
	s/\s+/ /g;
	s/^ //g;
	s/ $//g;
	print $fhout $_, "\n";
}
close($fhin);
close($fhout);
