## Convert CC-CEDICT txt file to phrase table (for Moses Decoder)

use strict;
use utf8;
use Unicode::EastAsianWidth;
require charnames;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $MaxPhraseLen = 20;

# load the language-specific non-breaking prefix info from files in the directory nonbreaking_prefixes
my %NONBREAKING_PREFIX = ();
load_prefixes(\%NONBREAKING_PREFIX);

# load protected_patterns
my $AGGRESSIVE = 1;
my $NO_ESCAPING = 1;
my @protected_patterns = (
		qr"<\/?\S+\/?>",
		qr"<\S+( [a-zA-Z0-9]+\=\"?[^\"]\")+ ?\/?>",
		qr"<\S+( [a-zA-Z0-9]+\=\'?[^\']\')+ ?\/?>",
	);

#my $fname_in = "cedict_1_0_ts_utf-8_mdbg.txt.smp";
my $fname_in = "cedict_1_0_ts_utf-8_mdbg.txt";
my $fname_out = "phrase_table.cedict.zh-en";
open(my $fhin, "<:encoding(UTF-8)", $fname_in) or die("Can't open $fname_in: $!");
open(my $fhout, ">:encoding(UTF-8)", $fname_out) or die("Can't open $fname_out: $!");
#open(my $fherr, ">:encoding(UTF-8)", "$fname.dcx_log") or die("Can't open $fname.dcx_log: $!");

my $ln = 0;
my $n_entries = 0;
while(<$fhin>) {
	$ln++;
	#last if ($n_entries >= 1000);
	next if (substr($_,0,1) eq "#");
	#if ($_ !~ /^(\S+) (\S+) \[([A-Za-z1-5\:\-, ]+)\] \/(.*)\/\s*$/) {
	if ($_ !~ /^(\S+) (\S+) \[([A-Za-z1-5\:·, ]+)\] \/(.*)\/\s*$/) {
		print STDERR "WARNING: line $ln does not conform to the expected format:\t$_\n";
		next;
	}
	$n_entries++;
	
	my ($zht, $zhs, $pinyin, $definition) = ($1, $2, $3, $4);
	#print "=== Entry $n_entries ===\n";
	#print "\tzht: $zht\n\tzhs: $zhs\n\tpinyin: $pinyin\n\tdefinition: $definition\n";
	
	$zhs =~ s/(\p{Han})/ $1 /g; # put space around every character
	#$zhs =~ s/\s+/ /g;
	#$zhs =~ s/^\s+//g;
	#$zhs =~ s/\s+$//g;
	$zhs = tokenize($zhs);
	#$zhs = lc($zhs);
	my $zhslen = scalar(split(/\s+/, $zhs));
	
	my %defhash = (); # use a hash to merge duplicates
	for my $def (split(/[\/;]/, $definition)) {
		# curate definition
		my $def_o = $def;
		$def =~ s/^([\p{LC}\-\.\' ]+) \(([0-9\-\? ]|c\.|BC|AD)+\), .+/$1/; # leave only the person name in definition of person names
		$def =~ s/^(\p{Lu}[\p{LC}\-\.\' ]+?) (autonomous )?(municipality|province|(subprovincial |prefecture level |county level )?city|prefecture|county|district|town|township|village).+/$1/i; # leave only the place name in definition of political divisions
		$def =~ s/\(.+?\)|\[.+?\]|\blit\.|\bfig\.|\bi\.e\. .+|\be\.g\. .+|, namely: .+|\bcf\b.+//g; # delete explanatory contents
		$def =~ s/(^|, )(see|see also|also written|also called|same as|abbr\.( of| for| to)?) \p{Han}.*//g; # delete reference to other entries
		$def =~ s/\bsth\b/it/g; # replace "sth" in definitions with "it"
		$def =~ s/\b(sb|one's|oneself)\b//g; # delete "sb", "one's", "oneself" in definitions
		$def =~ s/^\s*\.+//; # delete starting dots
		$def =~ s/^\s*(also |sometimes |formerly |commonly )((called|known as|translated as|referred to as) \b)//; # delete introductory comments
		$def =~ s/^\s*(two-character |polysyllabic |Japanese)?surname (.+)$/$2/; # leave only the surname in definitions of surnames
		$def =~ s/^\s*((\p{Lu}[\p{LC}\-\']*|the|of|to|and|for|in|on|at|with|[\-,\.\'\" ])+), \p{Ll}.*$/$1/; # delete descriptions in definitions of proper nouns, e.g. Head Word, descriptions ...)
		$def =~ s/^\s*(to be|to|be) //; # delete the starting "to" and "be" in the definition of verbs/adjectives
		$def =~ s/\s*[ ,;\.\!\?]+\s*$//; # delete ending punctuations
		#$def = lc($def);
		$def =~ s/\s+/ /g;
		$def =~ s/^\s+//g;
		$def =~ s/\s+$//g;
		if (!$def) { # skip empty definitions
			print STDERR "Empty definition \"$def_o\" for the entry \"$zhs\", skipped\n";
			next;
		}
		#if ($def =~ /\p{Han}/) { # skip definitions containing Chinese characters
		#	print STDERR "Definition \"$def_o\" for the entry \"$zhs\" contains Chinese character, skipped\n";
		#	next;
		#}
		if ($def =~ /\bpr\b/) { # skip definitions that are pronunciation guides
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is a pronunciation guide, skipped\n";
			next;
		}
		if ($def =~ /^(\w+ )?variant of/) { # skip variation notes
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is a variation note, skipped\n";
			next;
		}
		if ($def =~ /^CL:/) { # skip measure word guides
			print STDERR "Definition \"$def_o\" for the entry \"$zhs\" is a measure word guide, skipped\n";
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
		$def = tokenize($def);
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
		my $score_p2 = sprintf("%.6g", 0.5 + 0.5 / scalar(@defarray));
		my $score_l1 = sprintf("%.6g", 0.7**$zhslen);
		for my $def (@defarray) {
			my $deflen = scalar(split(/\s+/, $def));
			my $score_l2 = sprintf("%.6g", 0.7**$deflen);
			#my $def_tok = `echo "$def" | perl "$tokenizer" -a -q -l en`;
			print $fhout lc($zhs), " ||| ", lc($def), " ||| 0.7 $score_l1 $score_p2 $score_l2 2.718 ||| ||| \n";
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

sub tokenize 
{
    my($text) = @_;
    chomp($text);
    $text = " $text ";
    
    # remove ASCII junk
    $text =~ s/\s+/ /g;
    $text =~ s/[\000-\037]//g;

    # Find protected patterns
    my @protected = ();
    foreach my $protected_pattern (@protected_patterns) {
      my $t = $text;
      while ($t =~ /($protected_pattern)(.*)$/) {
        push @protected, $1;
        $t = $2;
      }
    }

    for (my $i = 0; $i < scalar(@protected); ++$i) {
      my $subst = sprintf("THISISPROTECTED%.3d", $i);
      $text =~ s,\Q$protected[$i], $subst ,g;
    }
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    # seperate out all "other" special characters
    $text =~ s/([^\p{IsAlnum}\s\.\'\`\,\-])/ $1 /g;

    # aggressive hyphen splitting
    if ($AGGRESSIVE) 
    {
        $text =~ s/([\p{IsAlnum}])\-(?=[\p{IsAlnum}])/$1 \@-\@ /g;
    }

    #multi-dots stay together
    $text =~ s/\.([\.]+)/ DOTMULTI$1/g;
    while($text =~ /DOTMULTI\./) 
    {
        $text =~ s/DOTMULTI\.([^\.])/DOTDOTMULTI $1/g;
        $text =~ s/DOTMULTI\./DOTDOTMULTI/g;
    }

    # seperate out "," except if within numbers (5,300)
    #$text =~ s/([^\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;

    # separate out "," except if within numbers (5,300)
    # previous "global" application skips some:  A,B,C,D,E > A , B,C , D,E
    # first application uses up B so rule can't see B,C
    # two-step version here may create extra spaces but these are removed later
    # will also space digit,letter or letter,digit forms (redundant with next section)
    $text =~ s/([^\p{IsN}])[,]/$1 , /g;
    $text =~ s/[,]([^\p{IsN}])/ , $1/g;

    # separate , pre and post number
    #$text =~ s/([\p{IsN}])[,]([^\p{IsN}])/$1 , $2/g;
    #$text =~ s/([^\p{IsN}])[,]([\p{IsN}])/$1 , $2/g;
	      
    # turn `into '
    #$text =~ s/\`/\'/g;
	
    #turn '' into "
    #$text =~ s/\'\'/ \" /g;

    #split contractions right (for language = en)
    $text =~ s/([^\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
    $text =~ s/([^\p{IsAlpha}\p{IsN}])[']([\p{IsAlpha}])/$1 ' $2/g;
    $text =~ s/([\p{IsAlpha}])[']([^\p{IsAlpha}])/$1 ' $2/g;
    $text =~ s/([\p{IsAlpha}])[']([\p{IsAlpha}])/$1 '$2/g;
    #special case for "1990's"
    $text =~ s/([\p{IsN}])[']([s])/$1 '$2/g;
	
    #word token method
    my @words = split(/\s/,$text);
    $text = "";
    for (my $i=0;$i<(scalar(@words));$i++) 
    {
        my $word = $words[$i];
        if ( $word =~ /^(\S+)\.$/) 
        {
            my $pre = $1;
            if (($pre =~ /\./ && $pre =~ /\p{IsAlpha}/) || ($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==1) || ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[\p{IsLower}]/))) 
            {
                #no change
			} 
            elsif (($NONBREAKING_PREFIX{$pre} && $NONBREAKING_PREFIX{$pre}==2) && ($i<scalar(@words)-1 && ($words[$i+1] =~ /^[0-9]+/))) 
            {
                #no change
            } 
            else 
            {
                $word = $pre." .";
            }
        }
        $text .= $word." ";
    }		

    # clean up extraneous spaces
    $text =~ s/ +/ /g;
    $text =~ s/^ //g;
    $text =~ s/ $//g;

    # restore protected
    for (my $i = 0; $i < scalar(@protected); ++$i) {
      my $subst = sprintf("THISISPROTECTED%.3d", $i);
      $text =~ s/$subst/$protected[$i]/g;
    }

    #restore multi-dots
    while($text =~ /DOTDOTMULTI/) 
    {
        $text =~ s/DOTDOTMULTI/DOTMULTI./g;
    }
    $text =~ s/DOTMULTI/./g;

    #escape special chars
    if (!$NO_ESCAPING)
	{
		$text =~ s/\&/\&amp;/g;   # escape escape
		$text =~ s/\|/\&#124;/g;  # factor separator
		$text =~ s/\</\&lt;/g;    # xml
		$text =~ s/\>/\&gt;/g;    # xml
		$text =~ s/\'/\&apos;/g;  # xml
		$text =~ s/\"/\&quot;/g;  # xml
		$text =~ s/\[/\&#91;/g;   # syntax non-terminal
		$text =~ s/\]/\&#93;/g;   # syntax non-terminal
	}

    return $text;
}

sub load_prefixes 
{
    my ($PREFIX_REF) = @_;
	
	my $prefixfile = "/media/zhenghao/Study/UKY/NLP/machine traslation/corpora/nonbreaking_prefix.en";
	die ("ERROR: No abbreviations file.\n") unless (-e $prefixfile);
	open(my $PREFIX, "<:utf8", "$prefixfile");
    while (<$PREFIX>) 
    {
        my $item = $_;
        chomp($item);
        if (($item) && (substr($item,0,1) ne "#")) 
        {
            if ($item =~ /(.*)[\s]+(\#NUMERIC_ONLY\#)/) 
            {
                $PREFIX_REF->{$1} = 2;
            } 
            else 
            {
                $PREFIX_REF->{$item} = 1;
            }
        }
    }
    close($PREFIX);
}
