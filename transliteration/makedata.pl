# Take the "Dictionary for the Translation of Foreign Personal Names (世界人名翻译大辞典)" as input,
# generate a parallel corpus for training transliteration systems.
# 
# Input
#     The dictionary, saved in the files dict-1.csv and dict-2.csv
# Output
#     Six files, including:
#     1) xlit-west.en, xlit-west.zh
#        Names in languages not using Chinese characters (including those languages that are used by 
#        certain Chinese minority groups), and their translations in Chinese
#     2) xlit-japan.en, xlit-japan.zh
#        Names in Japanese (which uses Chinese characters) that are phonetically translated into
#        English, and their original forms written with Chinese characters
#     3) xlit-ckv.en, xlit-ckv.zh
#        Names in Chinese, Korean and Vietnamese that are phonetically translated into English,
#        and their original forms written with Chinese characters

use utf8;
my @inFileNames = ("dict-1.csv", "dict-2.csv");
my %outFileNames = (West => "xlit-west", Japan => "xlit-japan", CKV => "xlit-ckv"); # xlit stands for "transliteration", CKV stands for "Chinese, Korean, Vietnamese"
my $cueForChangeToEast = "第二部分";
my $cueForJapan = "日";
my $cueForChina = "中";
my $cueInZhForChineseMinority = "·汉语拼音";
my $cueInOriginForChineseMinority = "中少";
my $date = `date +%Y-%m-%d@%H:%M:%S`;
chomp $date;
my $errFileName = "log.$date";

# Open Files
my $fhi;
my $fhoEn;
my $fhoZh;
my $fhe;
open($fhe, ">:encoding(UTF-8)", $errFileName) or die $!; # Open log file
my %fhoEns;
my %fhoZhs;
for my $division (keys %outFileNames) {
	my $fileName = $outFileNames{ $division };
	open(my $fhTempEn, ">:encoding(UTF-8)", "$fileName.en") or die $!;
	$fhoEns{$division} = $fhTempEn;
	open(my $fhTempZh, ">:encoding(UTF-8)", "$fileName.zh") or die $!;
	$fhoZhs{$division} = $fhTempZh;
}

# Go through all the records in the Name Translation Dictionary
my $processingWest = 1;
for my $inFileName (@inFileNames) {
	open($fhi, "<:encoding(UTF-8)", $inFileName) or die $!; # Open input file
	my $lineNum = 0;
	while(<$fhi>) {
		chomp;
		my $line = $_;
		$lineNum++;
		
		# Change processing mode to "East" when a line is read containing the words "第二部分"
		if ($line =~ /$cueForChangeToEast/) {
			print $fhe "Change to East mode at line $lineNum: $line\n";
			$processingWest = 0;
			next;
		}
		
		# Replace erroneous characters
		$line =~ tr/，、；/,,;/; # Replace fullwidth punctuations with halfwidth punctuations
		$line =~ tr/АаӒӓЕеЁёОоӦӧ/AaÄäEeËëOoÖö/; # Replace Cyrillic letters with Latin homoglyphs
		$line =~ s/<sup>′<\/sup>/'/g; # Replace the string "<sup>′</sup>" with apostrophe
		$line =~ tr/\x{009A}/š/; # Replace the character U+009A (single character introducer) with "Latin small letter S with caron"
		$line =~ tr/∅/ø/; # Replace "empty set" with "Latin small letter O with stroke"
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
		
		# Process Origin
		if ($origin =~ /^\"(.+)\"$/) {
			$origin = $1;
		}
		if ($origin !~ /^[\p{Han},]+$/ && $zh =~ /〈(\p{Han}+)〉/) {
			$origin = $1;
		}
		if ($origin =~ /$cueForChina/ && $zh =~ /\((.+)$cueInZhForChineseMinority\)/) {
			$origin = "$cueInOriginForChineseMinority-$1";
		}
		
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
		next if ($entryCount == 0);
		my $division;
		if ($processingWest) {
			$division = "West";
		}
		else {
			if ($origin =~ /$cueForJapan/) {
				$division = "Japan";
			}
			elsif ($origin =~ /$cueInOriginForChineseMinority/) {
				$division = "West";
			} 
			else {
				$division = "CKV";
			}
		}
		$fhoEn = $fhoEns{ $division };
		$fhoZh = $fhoZhs{ $division };
		for my $zhItem (@zhList) {
			print $fhoEn "$en\n";
			print $fhoZh "$zhItem\n";
		}
	}
	close($fhi);
}
for my $division (keys %fhoEns) {
	close($fhoEns{ $division });
}
for my $division (keys %fhoZhs) {
	close($fhoZhs{ $division });
}
close($fhe);
