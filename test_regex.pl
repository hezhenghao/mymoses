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

die("Usage: perl $0 <test_string>") if (@ARGV != 1);
my $teststr = $ARGV[0];

my $domain = qr/([a-z0-9][a-z0-9\-]*\.)+[a-z]{2,}/i;
my $protocol = qr{(http[s]?|ftp)://}i;
my $path = qr/([a-z0-9_\-\.\/]|%[0-9a-f]{2})+/i;
my $query = qr/([a-z0-9*_=&\+\-\.]|%[0-9a-f]{2})+/i;
my $fragid = qr/[a-z0-9_\.]+/i;

my $email = qr/[a-z0-9_\-\.]\@$domain/i;
my $url = qr/($protocol)?$domain(:[0-9]+)?(\/$path(\?$query)?(\#$fragid)?)?/i;

print "domain: ", scalar($teststr =~ m/^$domain$/i)?"YES":"NO", "\n";
print "protocol: ", scalar($teststr =~ m/^$protocol$/i)?"YES":"NO", "\n";
print "path: ", scalar($teststr =~ m/^$path$/i)?"YES":"NO", "\n";
print "query: ", scalar($teststr =~ m/^$query$/i)?"YES":"NO", "\n";
print "fragid: ", scalar($teststr =~ m/^$fragid$/i)?"YES":"NO", "\n";
print "email: ", scalar($teststr =~ m/^$email$/i)?"YES":"NO", "\n";
print "url: ", scalar($teststr =~ m/^$url$/i)?"YES":"NO", "\n";
