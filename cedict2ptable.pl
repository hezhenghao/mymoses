## Convert CC-CEDICT txt file to phrase table (for Moses Decoder)

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $MaxPhraseLen = 20;

my $fname_in = "cedict_1_0_ts_utf-8_mdbg.txt";
my $fname_out = "phrase_table.cedict.zh-en";
open(my $fhin, "<:encoding(UTF-8)", $fname_in) or die("Can't open $fname_in: $!");
open(my $fhout, ">:encoding(UTF-8)", $fname_out) or die("Can't open $fname_out: $!");
#open(my $fherr, ">:encoding(UTF-8)", "$fname.dcx_log") or die("Can't open $fname.dcx_log: $!");

my $ln = 0;
my $n_entries = 0;
while(<$fhin>) {
	$ln++;
	#last if ($n_entries >= 10000);
	next if(substr($_,0,1) eq "#");
	if($_ !~ m/^(\S+) (\S+) \[([A-Za-z1-5: ]+)\] \/(.*)\/\s*$/) {
		print STDERR "WARNING: line $ln does not conform to the expected format:\t$_\n";
		next;
	}
	$n_entries++;
	my ($zht, $zhs, $pinyin, $definition) = ($1, $2, $3, $4);
	#print "=== Entry $n_entries ===\n";
	#print "\tzht: $zht\n\tzhs: $zhs\n\tpinyin: $pinyin\n\tdefinition: $definition\n";
	for my $def (split(/[\/;]/, $definition)) {
		$zhs =~ s/(\p{Han})/ $1 /g; # put space around every character
		$zhs =~ s/\s+/ /g;
		$zhs =~ s/^\s+//g;
		$zhs =~ s/\s+$//g;
		#$zhs = lc($zhs);
		
		# curate definition
		my $def_o = $def;
		$def =~ s/\(.+?\)|\[.+?\]|\blit\.|\bfig\.|\bi\.e\. .+|\be\.g\. .+//g; # delete explanatory contents
		$def =~ s/\bsth\b/it/g; # replace "sth" in definitions with "it"
		$def =~ s/\b(sb|one's|oneself)\b//g; # delete "sb", "one's", "oneself" in definitions
		$def =~ s/^(two-character |polysyllabic )?surname (.+)$/$2/; # leave only the surname in definitions of surnames
		$def =~ s/^((\p{Lu}\p{LC}*|the|of|to|and|for|in|on|at|-|,|.|'|"| )+), \p{Ll}.*$/$1/; # delete descriptions in definitions of proper nouns, e.g. Head Word, descriptions ...)
		$def =~ s/^\s*(to|be) //; # delete the starting "to" and "be" in the definition of verbs/adjectives
		$def =~ s/\s*[ ,;\.\!\?]+\s*$//; # delete ending punctuations
		#$def = lc($def);
		$def =~ s/\s+/ /g;
		$def =~ s/^\s+//g;
		$def =~ s/\s+$//g;
		if (!$def) {
			print STDERR "Empty definition \"$def_o\" for the entry \"$zhs\", skipped\n";
			next;
		}
		if ($def =~ /\p{Han}/) {
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains Chinese character, skipped\n";
			next;
		}
		if ($def =~ /^also /) {
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is a P.S., skipped\n";
			next;
		}
		if ($def =~ /\.\.\./) {
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains ellipses, skipped\n";
			next;
		}
		my $zhslen = scalar(split(/\s+/, $zhs));
		my $deflen = scalar(split(/\s+/, $def));
		if ($deflen > $MaxPhraseLen || $deflen > $zhslen + 3) {
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is too long, skipped\n";
			my $fname_err = "toolong$zhslen.txt";
			open(my $fherr, ">>:encoding(UTF-8)", $fname_err) or die("Can't open $fname_err: $!");
			print $fherr "$zhs: $def_o\n";
			close($fherr);
			next;
		}
		# Possible future work: for definitions containing "sb", "one's" or "oneself", add multiple entries to the phrase table, each entry replacing "sb"/"one's"/"oneself" with "me"/"your"/"himself"/etc.
		print $fhout "$zhs ||| $def\n";
	}
}
close($fhin);
close($fhout);
