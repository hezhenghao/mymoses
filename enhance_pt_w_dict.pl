# Enhance a phrase table with dictionary
use strict;
use utf8;
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $fn_dict = "phrase_table.cedict.zh-en";
my $fn_pt = "/home/zhenghao/Desktop/phrase-table.UN.en-zh.for_train.zh-en";
my $fn_out = "phrase-table.UN-cedict.zh-en";

my %hash_dict = ();
open(my $fhin, "<:encoding(UTF-8)", $fn_dict) or die("Can't open $fn_dict: $!");
print STDERR "Reading dictionary file...\n";
while(<$fhin>) {
	my ($src, $tgt, @rest) = split(/ \|\|\| /, $_);
	chomp $tgt;
	if (!$hash_dict{$src}) {
		$hash_dict{$src} = {};
	}
	$hash_dict{$src}->{$tgt} = 1;
}
close($fhin);
print STDERR "Read dictionary file done.\n";

my %hash_pt = ();
my $n_scores = -1;
open(my $fhin, "<:encoding(UTF-8)", $fn_pt) or die("Can't open $fn_pt: $!");
print STDERR "Reading phrase table file...\n";
while(<$fhin>) {
	my ($src, $tgt, $scores, @rest) = split(/ \|\|\| /, $_);
	my @arr_scores = split(/\s+/, $scores);
	if ($n_scores < 0) {
		$n_scores = @arr_scores;
		die("ERROR: Number of scores is $n_scores while expecting 4 or 5") if ($n_scores != 4 && $n_scores != 5);
	}
	if (!$hash_pt{$src}) {
		$hash_pt{$src} = {};
	}
	$hash_pt{$src}->{$tgt} = \@arr_scores;
}
close($fhin);
print STDERR "Read phrase table file done.\n";

for my $src (keys %hash_dict) {
	my $l_src = scalar(split(/\s+/, $src));
	my $n_tgts = scalar(keys %{$hash_dict{$src}});
	if (!$hash_pt{$src}) {
		$hash_pt{$src} = $hash_dict{$src};
		for my $tgt (keys %{$hash_dict{$src}}) {
			my $l_tgt = scalar(split(/\s+/, $tgt));
			my @arr_scores = (0.5, 0.5**$l_src, 1.0/$n_tgts, 0.5**$l_tgt);
			push(@arr_scores, 2.718) if ($n_scores == 5);
			$hash_pt{$src}->{$tgt} = \@arr_scores;
		}
	}
	else {
		for my $tgt (keys %{$hash_dict{$src}}) {
			if (!$hash_pt{$src}->{$tgt}) {
				my $l_tgt = scalar(split(/\s+/, $tgt));
				my @arr_scores = (0.5, 0.5**$l_src, 0.5/$n_tgts, 0.5**$l_tgt);
				push(@arr_scores, 2.718) if ($n_scores == 5);
				$hash_pt{$src}->{$tgt} = \@arr_scores;
			}
			else {
				$hash_pt{$src}->{$tgt}->[0] = 0.5 + 0.5 * $hash_pt{$src}->{$tgt}->[0];
				$hash_pt{$src}->{$tgt}->[2] = 0.5 + 0.5 * $hash_pt{$src}->{$tgt}->[2];
			}
		}
	}
}

print STDERR "New phrase table constructed. Writing to file...\n";
open(my $fhout, ">:encoding(UTF-8)", $fn_out) or die("Can't open $fn_out: $!");
for my $src (keys %hash_pt) {
	for my $tgt (keys %{$hash_pt{$src}}) {
		print $fhout "$src ||| $tgt ||| ", join(" ", @{$hash_pt{$src}->{$tgt}}), " ||| ||| \n";
	}
}
close($fhout);
