# Enhance a phrase table with dictionary
use strict;
use utf8;
use feature "state";
binmode(STDIN,  ':utf8');
binmode(STDOUT, ':utf8');
binmode(STDERR, ':utf8');

my $fn_dict = "phrase_table.cedict.zh-en";
my $fn_pt = "/home/zhenghao/Desktop/phrase-table.UN.en-zh.for_train.zh-en";
my $fn_out = "phrase-table.UN-cedict.zh-en";

#my $fn_dict = "dict_test.txt";
#my $fn_pt = "pt_test.txt";
#my $fn_out = "pt_new.txt";

# Read dictionary file
my %h_dict_s2t = ();
my %h_dict_t2s = ();
open(my $fhin, "<:encoding(UTF-8)", $fn_dict) or die("Can't open $fn_dict: $!");
print STDERR "Reading dictionary file...\n";
while(<$fhin>) {
	my ($src, $tgt, @rest) = split(/ \|\|\| /, $_);
	chomp $tgt;
	if (!$h_dict_s2t{$src}) {
		$h_dict_s2t{$src} = {};
	}
	$h_dict_s2t{$src}->{$tgt} = 1;
	if (!$h_dict_t2s{$tgt}) {
		$h_dict_t2s{$tgt} = {};
	}
	$h_dict_t2s{$tgt}->{$src} = 1;
}
close($fhin);
print STDERR "Read dictionary file done.\n";

# Read phrase table file
my %h_pt_s2t = ();
my %h_pt_t2s = ();
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
	if (!$h_pt_s2t{$src}) {
		$h_pt_s2t{$src} = {};
	}
	$h_pt_s2t{$src}->{$tgt} = \@arr_scores;
	if (!$h_pt_t2s{$tgt}) {
		$h_pt_t2s{$tgt} = {};
	}
	$h_pt_t2s{$tgt}->{$src} = \@arr_scores;
}
close($fhin);
print STDERR "Read phrase table file done.\n";

=old
for my $src (keys %h_dict) {
	my $l_src = scalar(split(/\s+/, $src));
	my $n_tgts = scalar(keys %{$h_dict{$src}});
	if (!$h_pt{$src}) {
		$h_pt{$src} = $h_dict{$src};
		for my $tgt (keys %{$h_dict{$src}}) {
			my $l_tgt = scalar(split(/\s+/, $tgt));
			my @arr_scores = (0.5, 0.5**$l_src, 1.0/$n_tgts, 0.5**$l_tgt);
			push(@arr_scores, 2.718) if ($n_scores == 5);
			$h_pt{$src}->{$tgt} = \@arr_scores;
		}
	}
	else {
		for my $tgt (keys %{$h_dict{$src}}) {
			if (!$h_pt{$src}->{$tgt}) {
				my $l_tgt = scalar(split(/\s+/, $tgt));
				my @arr_scores = (0.5, 0.5**$l_src, 0.5/$n_tgts, 0.5**$l_tgt);
				push(@arr_scores, 2.718) if ($n_scores == 5);
				$h_pt{$src}->{$tgt} = \@arr_scores;
			}
			else {
				$h_pt{$src}->{$tgt}->[0] = 0.5 + 0.5 * $h_pt{$src}->{$tgt}->[0];
				$h_pt{$src}->{$tgt}->[2] = 0.5 + 0.5 * $h_pt{$src}->{$tgt}->[2];
			}
		}
	}
}
=cut

# Copy old phrase table to new phrase table
my %h_new_pt = ();
for my $src (keys %h_pt_s2t) {
	$h_new_pt{$src} = {};
	for my $tgt (keys %{$h_pt_s2t{$src}}) {
		$h_new_pt{$src}->{$tgt} = $h_pt_s2t{$src}->{$tgt};
	}
}

# Update entries in the new phrase table with dictionary entries
for my $src (keys %h_dict_s2t) {
	my $l_src = scalar(split(/\s+/, $src)); # lf: length of source phrase
	my $N_src = scalar(keys %{$h_dict_s2t{$src}}); # Nf: number of entries (f,x) in dictionary
	
=old
	# get some stats from phrase table
	my $M2 = 0;
	my $M3 = 0;
	if ($h_pt_s2t{$src}) {
		for my $tgt (keys %{$h_pt_s2t{$src}}) {
			my $r_scores = $h_pt_s2t{$src}->{$tgt};
			$M2 = $r_scores->[2] if $r_scores->[2] > $M2;
			$M3 = $r_scores->[3] if $r_scores->[3] > $M3;
		}
	}
=cut
	
	# update phrase table entries
	$h_new_pt{$src} = {} if (!$h_new_pt{$src});
	for my $tgt (keys %{$h_dict_s2t{$src}}) {
		my $l_tgt = scalar(split(/\s+/, $tgt)); # le: length of target phrase
		my $N_tgt = scalar(keys %{$h_dict_t2s{$tgt}}); # Ne: number of entries (y,e) in dictionary
		if (!$h_pt_s2t{$src}) {
			if (!$h_pt_t2s{$tgt}) { # f not in pt and e not in pt, add an entry with artificial scores (with lf, le, Nf, Ne)
				my @arr_scores = (
					sprintf("%.6g", 1.0/$N_tgt),
					sprintf("%.6g", 0.5**$l_src),
					sprintf("%.6g", 1.0/$N_src),
					sprintf("%.6g", 0.5**$l_tgt));
				push(@arr_scores, "2.718") if ($n_scores == 5);
				$h_new_pt{$src}->{$tgt} = \@arr_scores;
			}
			else { # f not in pt but e in pt, add an entry with artificial scores (with le, Nf, M0, M1)
				my @arr_scores = (
					sprintf("%.6g", 0.5 * &max_score_in_pt("tgt", $tgt, 0)),
					sprintf("%.6g", 0.5 * &max_score_in_pt("tgt", $tgt, 1)),
					sprintf("%.6g", 1.0/$N_src),
					sprintf("%.6g", 0.5**$l_tgt));
				push(@arr_scores, "2.718") if ($n_scores == 5);
				$h_new_pt{$src}->{$tgt} = \@arr_scores;
			}
		}
		else {
			if (!$h_pt_t2s{$tgt}) { # f in pt but e not in pt, add an entry with artificial scores (with lf, Ne, M2, M3)
				my @arr_scores = (
					sprintf("%.6g", 1.0/$N_tgt),
					sprintf("%.6g", 0.5**$l_src),
					sprintf("%.6g", 0.5 * &max_score_in_pt("src", $src, 2)),
					sprintf("%.6g", 0.5 * &max_score_in_pt("src", $src, 3)));
				push(@arr_scores, "2.718") if ($n_scores == 5);
				$h_new_pt{$src}->{$tgt} = \@arr_scores;
			}
			else { # f in pt and e in pt, increase scores in the original entry (with M0, M1, M2, M3)
				my $r_scores = $h_pt_s2t{$src}->{$tgt};
				my @arr_scores = (0) x 4;
				for (my $isc = 0; $isc < 4; $isc++) {
					$arr_scores[$isc] = sprintf("%.6g", 0.5 * ($r_scores->[$isc] + &max_score_in_pt("src", $src, $isc)));
				}
				
				my @arr_scores = (
					sprintf("%.6g", 0.5 * ($r_scores->[0] + &max_score_in_pt("tgt", $tgt, 0))),
					sprintf("%.6g", 0.5 * ($r_scores->[1] + &max_score_in_pt("tgt", $tgt, 1))),
					sprintf("%.6g", 0.5 * ($r_scores->[2] + &max_score_in_pt("src", $src, 2))),
					sprintf("%.6g", 0.5 * ($r_scores->[3] + &max_score_in_pt("src", $src, 3))));
				push(@arr_scores, "2.718") if ($n_scores == 5);
				$h_new_pt{$src}->{$tgt} = \@arr_scores;
			}
		}
	}
}

print STDERR "New phrase table constructed. Writing to file...\n";
open(my $fhout, ">:encoding(UTF-8)", $fn_out) or die("Can't open $fn_out: $!");
for my $src (sort(keys %h_new_pt)) {
	for my $tgt (sort(keys %{$h_new_pt{$src}})) {
		print $fhout "$src ||| $tgt ||| ", join(" ", @{$h_new_pt{$src}->{$tgt}}), " ||| ||| \n";
	}
}
close($fhout);

# Sort new phrase table
print STDERR "Sorting new phrase table...\n";
system("LC_ALL=C sort $fn_out > $fn_out.sorted");
system("mv $fn_out.sorted $fn_out");
print STDERR "Done.\n";

### a subroutine for calculating the max score
sub max_score_in_pt {
	die("expects 3 arguments, got ".scalar(@_)) if (@_ != 3);
	my ($side, $phrase, $num) = @_;
	die("argument 1 should be \"src\" or \"tgt\", got $side") if ($side ne "src" && $side ne "tgt");
	die("argument 3 should be 0, 1, 2, or 3, got $num") if ($num != 0 && $num != 1 && $num != 2 && $num != 3);
	
	state $rh_max_src = {};
	state $rh_max_tgt = {};
	my $rh_max = ($side eq "src")? $rh_max_src : $rh_max_tgt;
	my $rh_pt = ($side eq "src")? \%h_pt_s2t : \%h_pt_t2s;
	if ($rh_max->{$phrase}) {
		return $rh_max->{$phrase}->[$num];
	}
	else {
		if (!$rh_pt->{$phrase}) {
			print STDERR "WARNING: no phrase table entry for \"$phrase\" as $side\n";
			return 0;
		}
		else {
			my $r_max_scores = [0, 0, 0, 0];
			for my $otherphrase (keys %{$rh_pt->{$phrase}}) {
				my $r_scores = $rh_pt->{$phrase}->{$otherphrase};
				for (my $isc = 0; $isc < 4; $isc++) {
					$r_max_scores->[$isc] = $r_scores->[$isc] if ($r_max_scores->[$isc] < $r_scores->[$isc]);
				}
			}
			$rh_max->{$phrase} = $r_max_scores;
			return $r_max_scores->[$num];
		}
	}
}
