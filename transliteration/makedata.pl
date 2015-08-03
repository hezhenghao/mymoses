use utf8;
my @inFileNames = ("dict-1.csv", "dict-2.csv");
my $outFileNameEnWestern = "west.en";
my $outFileNameZhWestern = "west.zh";
my $outFileNameEnEastern = "east.en";
my $outFileNameZhEastern = "east.zh";
my $cueForChangeOutFile = "第二部分";
my $date = `date +%Y-%m-%d@%H:%M:%S`;
chomp $date;
my $errFileName = "log.$date";

my $fhi;
my $fho_en;
my $fho_zh;
my $fhe;
open($fho_en, ">:encoding(UTF-8)", $outFileNameEnWestern) or die("Can't open $outFileNameEnWestern!");
open($fho_zh, ">:encoding(UTF-8)", $outFileNameZhWestern) or die("Can't open $outFileNameZhWestern!");
open($fhe, ">:encoding(UTF-8)", $errFileName) or die("Can't open $errFileName!");
for my $inFileName (@inFileNames) {
	open($fhi, "<:encoding(UTF-8)", $inFileName) or die("Can't open $inFileName!");
	my $lineNum = 0;
	while(<$fhi>) {
		chomp;
		my $line = $_;
		$lineNum++;
		
		# Change output file when a line is read containing the words "第二部分"
		if ($line =~ /$cueForChangeOutFile/) {
			print $fhe "Change output file at line $lineNum: $line\n";
			close($fho_en);
			open($fho_en, ">:encoding(UTF-8)", $outFileNameEnEastern) or die("Can't open $outFileNameEnEastern!");
			close($fho_zh);
			open($fho_zh, ">:encoding(UTF-8)", $outFileNameZhEastern) or die("Can't open $outFileNameZhEastern!");
			next;
		}
		
		# Replace erroneous characters
		$line =~ tr/，、；/,,;/; # Replace fullwidth punctuations with halfwidth punctuations
		$line =~ tr/АаӒӓЕеЁёОоӦӧ/AaÄäEeËëOoÖö/; # Replace Cyrillic homoglyphs with Latin letters
		$line =~ s/<sup>′<\/sup>/'/g; # Replace the string "<sup>′</sup>" with apostrophe
		$line =~ tr/\x{009A}/š/; # Replace the character U+009A (single character introducer) with "Latin small letter S with caron"
		$line =~ tr/∅/ø/; # Replace "empty set" with "Latin small letter O with stroke"
		#$line =~ s/&#(\d+);/chr($1)/ge; # Replace HTML escape codes (decimal) with characters
		#$line =~ s/&#x([0-9A-Fa-f]+);/chr(0x$1)/gee; # Replace HTML escape codes (hexadecimal) with characters
		$line =~ s/&#211;/Ó/g;
		$line =~ s/&#551;/ȧ/g;
		$line =~ s/<span class=\"\"PUC04_f7\"\">&#xf722;<\/span>/ť/g;
		$line =~ s/<span class=\"\"PUC04_f8\"\">&#xf892;<\/span>/ň/g;
		
		# Extract fields
		if ($line !~ /^(\d+),"(.+)",(.*),"(.+)"$/) {
			print $fhe "WARNING: line $lineNum does not conform to the expected format, skipped: $line\n";
			next;
		}
		my ($ln, $en, $origin, $zh) = ($1, $2, $3, $4);
		
		# Process English
		if ($en !~ /^[\p{Latin} '-]+$/) {
			print $fhe "WARNING: line $lineNum has an English entry that contains non-Latin characters, skipped: $en\n";
			next;
		}
		
		# Process Chinese
		$zh =~ s/\(.+\)//g; # Remove explanations in brackets
		$zh =~ s/〈\p{Han}+〉.+。$//; # Remove description of historical figures
		$zh =~ s/ //g; # Remove spaces
		if ($zh !~ /^[\p{Han},;-]+$/) {
			print $fhe "WARNING: line $lineNum has a Chinese entry that contains non-Chinese characters, skipped: $zh\n";
			next;
		}
		my @zhList;
		my $zhWord = qr/[\p{Han}-]+/;
		if ($zh =~ /^$zhWord$/) {
			@zhList = ($zh);
		}
		elsif ($zh =~ /^$zhWord(,$zhWord)+,?$/) {
			@zhList = split(',', $zh);
		}
		elsif ($zh =~ /^$zhWord(;$zhWord)+;?$/) {
			@zhList = split(';', $zh);
		}
		else {
			@zhList = ();
		}
		
		# Output transliteration entries into files
		my $entryCount = @zhList;
		if ($entryCount != 1) {
			print $fhe "$entryCount entries created for line $lineNum: $line\n";
		}		
		for my $zhItem (@zhList) {
			print $fho_en "$en\n";
			print $fho_zh "$zhItem\n";
		}
	}
	close($fhi);
}
close($fho_en);
close($fho_zh);
close($fhe);
