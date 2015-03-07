### Naive Chinese segmentation treating single characters as words.

use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');
open(my $fhin, "<:encoding(UTF-8)", $ARGV[0]) or die("Can't open $ARGV[0]: $!");
open(my $fhout, ">:encoding(UTF-8)", "$ARGV[0].ss") or die("Can't open $ARGV[0].ss: $!");
while(!eof($fhin)) {
	my $line = <$fhin>;
	$line =~ s/([\p{Han}])/ $1 /g;
	$line =~ s/\h+/ /g;
	$line =~ s/^\s+//;
	$line =~ s/\s+$//;
	print $fhout $line."\n";
}
close($fhin);
close($fhout);
