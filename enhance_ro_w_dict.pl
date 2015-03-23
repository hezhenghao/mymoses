# Enhance a phrase table with dictionary
use strict;
use utf8;
use feature "state";
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

#my $fn_dict = "/media/zhenghao/Study/UKY/NLP/MT/corpora/CC-CEDICT/phrase-table.cedict.zh-en";
#my $fn_ro = "/home/zhenghao/Desktop/reordering-table.UN.en-zh.for_train.zh-en.wbe-msd-bidirectional-fe";
#my $fn_out = "/media/zhenghao/Study/UKY/NLP/MT/corpora/CC-CEDICT/reordering-table.UN-cedict.zh-en";

my $fn_dict = "dict_test.txt";
my $fn_ro = "ro_test.txt";
my $fn_out = "ro_new.txt";

# Read dictionary file
my %h_dict = ();
open(my $fhin, "<:encoding(UTF-8)", $fn_dict) or die("Can't open $fn_dict: $!");
print STDERR "Reading dictionary file...\n";
while(<$fhin>) {
	my ($src, $tgt, @rest) = split(/ \|\|\| /, $_);
	chomp $tgt;
	if (!$h_dict{$src}) {
		$h_dict{$src} = {};
	}
	$h_dict{$src}->{$tgt} = 1;
}
close($fhin);
print STDERR "Read dictionary file done.\n";

# Read reordering table file. Work include:
# 1. Calculate the average scores.
# 2. Mark the entries that occur in both the dictionary and the reordering table.
# 3. Print the entries in the old reordering table to the new reordering table.
my $n_scores = -1;
open(my $fhin, "<:encoding(UTF-8)", $fn_ro) or die("Can't open $fn_ro: $!");
open(my $fhout, ">:encoding(UTF-8)", $fn_out) or die("Can't open $fn_out: $!");
print STDERR "Reading reordering table file...\n";
my @stat_scores = ();
my $n_entries = 0;
while(<$fhin>) {
	$n_entries++;
	my ($src, $tgt, $scores, @rest) = split(/ \|\|\| /, $_);
	my @arr_scores = split(/\s+/, $scores);
	for (my $isc = 0; $isc < scalar(@arr_scores); $isc++) {
		$stat_scores[$isc] += $arr_scores[$isc];
	}
	if($h_dict{$src} && $h_dict{$src}->{$tgt}) {
		$h_dict{$src}->{$tgt} = 0;
	}
	print $fhout $_;
}
close($fhin);
print STDERR "Read reordering table file done.\n";

# Print statistics
print STDERR "$n_entries entries copied to the new reordering table.\nAverage scores are:";
for (my $isc = 0; $isc < scalar(@stat_scores); $isc++) {
	$stat_scores[$isc] = sprintf("%.6g", $stat_scores[$isc] / $n_entries);
	print STDERR " ", $stat_scores[$isc];
}
print STDERR "\n";
my $scores_filler = join(" ", @stat_scores);

# Add dictionary file entries that are not covered by the reordering table to the new reordering table
print STDERR "Adding dictionary entries to the new reordering table...\n";
for my $src (keys %h_dict) {
	for my $tgt (keys %{$h_dict{$src}}) {
		print $fhout "$src ||| $tgt ||| $scores_filler\n" if ($h_dict{$src}->{$tgt} == 1);
	}
}
close($fhout);
print STDERR "Add dictionary entries done.\n";

# Sort new reordering table
print STDERR "Sorting new reordering table...\n";
system("LC_ALL=C sort $fn_out > $fn_out.sorted");
system("mv $fn_out.sorted $fn_out");
print STDERR "Done.\n";
