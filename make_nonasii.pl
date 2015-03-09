## Replace private-use characters in UM corpus
use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
my $fname = "nonascii.txt";
open(my $fhout, ">:encoding(UTF-8)", $fname) or die("Can't open $fname: $!");
print $fhout "==Greek==\n";
for my $code (0x0391..0x03A9) {
	print $fhout chr($code);
}
for my $code (0x03B1..0x03C9) {
	print $fhout chr($code);
}

print $fhout "\n==Cyrillic==\n";
for my $code (0x0410..0x044F) {
	print $fhout chr($code);
}
print $fhout "\n==Latin 1 Letters==\n";
for my $code (0x00C0..0x00FF) {
	print $fhout chr($code);
}
print $fhout "\n==IPA Extensions==\n";
for my $code (0x0250..0x02AF) {
	print $fhout chr($code);
}
print $fhout "\n==Latin 1 Punctuations and Symbols==\n";
for my $code (0x00A1..0x00BF) {
	print $fhout chr($code);
}
print $fhout "\n==General Punctuation==\n";
for my $code (0x2010..0x2027) {
	print $fhout chr($code);
}
for my $code (0x2030..0x205E) {
	print $fhout chr($code);
}
print $fhout "\n==Currency Symbols==\n";
for my $code (0x20A0..0x20BA) {
	print $fhout chr($code);
}
print $fhout "\n==Letterlike Symbols==\n";
for my $code (0x2100..0x214F) {
	print $fhout chr($code);
}
print $fhout "\n==Number Forms==\n";
for my $code (0x2150..0x2189) {
	print $fhout chr($code);
}
print $fhout "\n==Arrows==\n";
for my $code (0x2190..0x21FF) {
	print $fhout chr($code);
}
print $fhout "\n==Mathematical Operators==\n";
for my $code (0x2200..0x22FF) {
	print $fhout chr($code);
}
print $fhout "\n==Enclosed Alphanumerics==\n";
for my $code (0x2460..0x24FF) {
	print $fhout chr($code);
}
print $fhout "\n==Box Drawing==\n";
for my $code (0x2500..0x257F) {
	print $fhout chr($code);
}
print $fhout "\n==Geometric Shapes==\n";
for my $code (0x25A0..0x25FF) {
	print $fhout chr($code);
}
print $fhout "\n==Miscellaneous Symbols==\n";
for my $code (0x2600..0x26FF) {
	print $fhout chr($code);
}
print $fhout "\n==Dingbats==\n";
for my $code (0x2700..0x27BF) {
	print $fhout chr($code);
}
print $fhout "\n==Miscellaneous Mathematical Symbols-A==\n";
for my $code (0x27C0..0x27EF) {
	print $fhout chr($code);
}
print $fhout "\n==Miscellaneous Mathematical Symbols-B==\n";
for my $code (0x2980..0x29FF) {
	print $fhout chr($code);
}
print $fhout "\n==Supplemental Mathematical Operators==\n";
for my $code (0x2A00..0x2AFF) {
	print $fhout chr($code);
}
print $fhout "\n==Supplemental Punctuation==\n";
for my $code (0x2E00..0x2E31) {
	print $fhout chr($code);
}
print $fhout "\n==CJK Radicals Supplement==\n";
for my $code (0x2E80..0x2EF3) {
	print $fhout chr($code);
}
print $fhout "\n==Kangxi Radicals==\n";
for my $code (0x2F00..0x2FD5) {
	print $fhout chr($code);
}
print $fhout "\n==Ideographic Description Characters==\n";
for my $code (0x2FF0..0x2FFB) {
	print $fhout chr($code);
}
print $fhout "\n==CJK Symbols and Punctuation==\n";
for my $code (0x3000..0x303F) {
	print $fhout chr($code);
}
print $fhout "\n==Hiragana==\n";
for my $code (0x3041..0x309F) {
	print $fhout chr($code);
}
print $fhout "\n==Katakana==\n";
for my $code (0x30A0..0x30FF) {
	print $fhout chr($code);
}
print $fhout "\n==Hangul Jamo==\n";
for my $code (0x1100..0x11FF) {
	print $fhout chr($code);
}
print $fhout "\n==Bopomofo==\n";
for my $code (0x3105..0x312D) {
	print $fhout chr($code);
}
print $fhout "\n==Vertical Forms==\n";
for my $code (0xFE10..0xFE19) {
	print $fhout chr($code);
}
print $fhout "\n==Halfwidth and Fullwidth Forms==\n";
for my $code (0xFF01..0xFF9F) {
	print $fhout chr($code);
}
close($fhout);
