## Convert CC-CEDICT txt file to phrase table (for Moses Decoder)

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $MaxPhraseLen = 20;

my $fname_in = "cedict_1_0_ts_utf-8_mdbg.txt.smp";
my $fname_out = "phrase_table.cedict.zh-en";
open(my $fhin, "<:encoding(UTF-8)", $fname_in) or die("Can't open $fname_in: $!");
open(my $fhout, ">:encoding(UTF-8)", $fname_out) or die("Can't open $fname_out: $!");
#open(my $fherr, ">:encoding(UTF-8)", "$fname.dcx_log") or die("Can't open $fname.dcx_log: $!");

my $ln = 0;
my $n_entries = 0;
while(<$fhin>) {
	$ln++;
	#last if ($n_entries >= 10000);
	next if (substr($_,0,1) eq "#");
	if ($_ !~ /^(\S+) (\S+) \[([A-Za-z1-5\:\,\- ]+)\] \/(.*)\/\s*$/) {
		print STDERR "WARNING: line $ln does not conform to the expected format:\t$_\n";
		next;
	}
	$n_entries++;
	
	my ($zht, $zhs, $pinyin, $definition) = ($1, $2, $3, $4);
	#print "=== Entry $n_entries ===\n";
	#print "\tzht: $zht\n\tzhs: $zhs\n\tpinyin: $pinyin\n\tdefinition: $definition\n";
	
	$zhs =~ s/(\p{Han})/ $1 /g; # put space around every character
	$zhs =~ s/\s+/ /g;
	$zhs =~ s/^\s+//g;
	$zhs =~ s/\s+$//g;
	#$zhs = lc($zhs);
	my $zhslen = scalar(split(/\s+/, $zhs));
	
	my %defhash = (); # use a hash to merge duplicates
	for my $def (split(/[\/;]/, $definition)) {
		# curate definition
		my $def_o = $def;
		$def =~ s/([\p{LC}\-\.\' ]+) \(([0-9\-\? ]|c\.|BC|AD)+\), .+/$1/; # leave only the person name in definition of person names
		$def =~ s/\(.+?\)|\[.+?\]|\blit\.|\bfig\.|\bi\.e\. .+|\be\.g\. .+//g; # delete explanatory contents
		$def =~ s/\bsth\b/it/g; # replace "sth" in definitions with "it"
		$def =~ s/\b(sb|one's|oneself)\b//g; # delete "sb", "one's", "oneself" in definitions
		$def =~ s/^(two-character |polysyllabic )?surname (.+)$/$2/; # leave only the surname in definitions of surnames
		$def =~ s/^((\p{Lu}[\p{LC}\-\']*|the|of|to|and|for|in|on|at|with|[\-,\.\'\" ])+), \p{Ll}.*$/$1/; # delete descriptions in definitions of proper nouns, e.g. Head Word, descriptions ...)
		$def =~ s/^\s*(to|be) //; # delete the starting "to" and "be" in the definition of verbs/adjectives
		$def =~ s/^\s*\.+//; # delete starting dots
		$def =~ s/\s*[ ,;\.\!\?]+\s*$//; # delete ending punctuations
		#$def = lc($def);
		$def =~ s/\s+/ /g;
		$def =~ s/^\s+//g;
		$def =~ s/\s+$//g;
		if (!$def) { # skip empty definitions
			print STDERR "Empty definition \"$def_o\" for the entry \"$zhs\", skipped\n";
			next;
		}
		if ($def =~ /\p{Han}/) { # skip definitions containing Chinese characters
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains Chinese character, skipped\n";
			next;
		}
		if ($def =~ /^also .+/ || $def =~ /\bpr\./) { # skip definitions starting with "also", or definitions that are pronunciation notes
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is a P.S., skipped\n";
			next;
		}
		if ($def =~ /[\(\)\[\]]|[^\p{ASCII}\p{Latin}]/) { # skip definitions containing brackets or non-ASCII-non-Latin characters
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains unacceptable characters, skipped\n";
			next;
		}
		if ($def =~ /\.\.\.+/) { # skip definitions containing ellipses
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains ellipses, skipped\n";
			next;
		}
		# skip definitions that are too long
		my $deflen = scalar(split(/\s+/, $def));
		if ($deflen > $MaxPhraseLen || $deflen > $zhslen + 3) {
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is too long, skipped\n";
			#my $fname_err = "toolong$zhslen.txt";
			#open(my $fherr, ">>:encoding(UTF-8)", $fname_err) or die("Can't open $fname_err: $!");
			#print $fherr "$zhs: $def_o\n";
			#close($fherr);
			next;
		}
		# Possible future work: for definitions containing "sb", "one's" or "oneself", add multiple entries to the phrase table, each entry replacing "sb"/"one's"/"oneself" with "me"/"your"/"himself"/etc.
		#print $fhout "$zhs ||| $def\n";
		$defhash{$def} = 1;
	}
	my @defarray = keys %defhash;
	if (@defarray) {
		for my $def (@defarray) {
			print $fhout "$zhs ||| $def\n";
		}
	}
	else { # No definitions for this head word. Add the pinyin as a definition entry for single-character head word
		print STDERR "The headword \"$zhs\" has no entry\n";
		#if ($zhslen == 1) {
		#	print STDERR "Add a pinyin entry for single character headword \"$zhs\"\n";
		#	$pinyin =~ s/[1-5\: ]//g;
		#	$pinyin =~ s/\-/ /g;
		#	$pinyin =~ s/,/ , /g;
		#	#$pinyin = lc($pinyin);
		#	print $fhout "$zhs ||| $pinyin\n";
		#}
	}
}
close($fhin);
close($fhout);
