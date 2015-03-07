### Change full-width characters to half-width, and replace Chinese punctuations with English counterparts.

use strict;
use utf8;
use Unicode::EastAsianWidth; # must do that again for 5.8.1
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
open(my $fhin, "<:encoding(UTF-8)", $ARGV[0]) or die("Can't open $ARGV[0]: $!");
open(my $fhout, ">:encoding(UTF-8)", "$ARGV[0].hw") or die("Can't open $ARGV[0].hw: $!");

#while(!eof($fhin)) {
while(<$fhin>) {
#	my $line = <$fhin>;
	my $line = $_;
	$line =~ s{(\p{InHalfwidthAndFullwidthForms}|\p{InCJKSymbolsAndPunctuation})}
			{
				my $char = $1;
				my $name = charnames::viacode(ord($char));
				(substr($name, 0, 10) eq 'FULLWIDTH ')
					? chr(charnames::vianame(substr($name, 10)))
				: (substr($name, 0, 12) eq 'IDEOGRAPHIC ')
					? chr(charnames::vianame(substr($name, 12)))
				: $char;
			}eg;
	$line =~ tr/“”‘’—/""''-/;
	print $fhout $line;
	#print $line;
}
close($fhin);
close($fhout);
