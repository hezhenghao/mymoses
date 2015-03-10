## Test whether a string matches several defined regular expressions

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

die("Usage: perl $0 <test_string>") if (@ARGV != 1);
my $teststr = $ARGV[0];

my $domain = qr/([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}/i;
my $protocol = qr{(http[s]?|ftp)://}i;
my $path = qr/([a-z0-9_\-\.\/]|%[0-9a-f]{2})+/i;
my $query = qr/([a-z0-9*_=&\+\-\.]|%[0-9a-f]{2})+/i;
my $fragid = qr/[a-z0-9_\.]+/i;
my $email = qr/[a-z0-9_\-\.]+\@$domain/i;
my $url = qr/$protocol$domain(:[0-9]+)?(\/($path(\?$query)?(\#$fragid)?)?)?/i;
my $number = qr/[0-9]+(\.[0-9]+)?(<TIMES>10\^?[0-9]+)?/;
my $numorden = qr/[0-9]+(1\-?st|2\-?nd|3\-?rd|[0-9]\-?th)/i;
my $xmltag = qr/<[^>]+>/;

my %pattern = (
				'domain', $domain,
				'protocol', $protocol,
				'path', $path,
				'query', $query,
				'fragid', $fragid,
				'email', $email,
				'url', $url,
				'number', $number,
				'numorden', $numorden,
				'xmltag', $xmltag,
				);

for my $patt (keys %pattern) {
	print "$patt: ", scalar($teststr =~ m/^$pattern{$patt}$/i)?"YES":"NO", "\n";
}
