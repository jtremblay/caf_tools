#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use File::Slurp;
use File::Find;
use POSIX;
use List::Util qw( sum min max);
use Iterator::FastaDb;
use File::Basename;

my $usage=<<'ENDHERE';
NAME:
compileRayResults.pl

PURPOSE:
Takes Ray output directory in input and generates some metrics.

INPUT:
--infile <string>  : Fasta file.
	
OUTPUT:
--outfile <string> : Outfile where results files will be written.

NOTES:

BUGS/LIMITATIONS:
 
AUTHOR/SUPPORT:
Julien Tremblay - jtremblay514@gmail.com

ENDHERE

## OPTIONS
my ($help, $infile, $outfile);
my $verbose = 0;

GetOptions(
  'infile=s'   => \$infile,
  'outfile=s'  => \$outfile,
  'verbose'    => \$verbose,
  'help'       => \$help
);
if ($help) { print $usage; exit; }

sub commify {
    my $text = reverse $_[0];
    $text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
    return scalar reverse $text
}

my %hash;


#my $cmd = "plotContigsLength.R";
#$cmd .= " -i $lengthList";
#$cmd .= " -o $outdir";
#print STDERR "[DEBUG] ".$cmd."\n";
#system($cmd);

# Print to file relevant values of the assembly process.
open(OUT, '>'.$outfile) or die "Can't open ".$outfile."/summaryTableAssembly.tsv";

my @fastaSeqsContigs;
push(@fastaSeqsContigs, $infile);
# Then compute N25, N50, N75, N90
printStats(\@fastaSeqsContigs, "contigs-scaffolds");

sub printStats{

  my $refArray = shift;
  my $prefix = shift;

  my @seqArray = @$refArray;

	foreach my $contigs (@seqArray){
	  my $totalBases = 0;
	  my $counter = 1;
	  my %hash;	
	  my $gcCount=0;
	  my @seqLengths;
	  my $opt_i = 100;
	  my %len= ();
	  my $n = 0;
	  my $int;
	  my $totalLength = 0;
	  my @length;
	  my $totalContigs;    #		TotalContigsInScaffolds
	  #my $totalBases;      #  	TotalBasesInScaffolds
	  my $minContigLength; #		MinContigLength
	  my $maxContigLength; #		MaxContigLength
	  my $N50Bases;        #		N50ContigBases
	  my $contigCoverage;  #		$contigCoverage = ContigsOnly
	  my $gcContent;       #		Content
	  my $ge5Kb = 0;
	  my $ge10Kb = 0;
	  my $ge20Kb = 0;
	  my $ge40Kb = 0;
	  my $ge80Kb = 0;
	  my $ge160Kb = 0;
	  my $ge320Kb = 0;
	  my $ge640Kb = 0;
	  my $ge1Mb = 0;
	  my $ge2Mb = 0;
	  my $ge4Mb = 0;
	  my $ge6Mb = 0;
	  my $ge8Mb = 0;
	  my $ge10Mb = 0;
	
		my $ref_fasta_db = Iterator::FastaDb->new($contigs) or die("Unable to open Fasta file, $contigs\n");
		while( my $curr = $ref_fasta_db->next_seq() ) {
			my $length = length($curr->seq);
			my $header = $curr->header;
			$header =~ s/>//;
		  push(@length, $length);
		
			###################
			push @seqLengths, $length; # record length for N50 calc's 
			$n++; 
			$int = floor( $length/$opt_i );  
			$totalLength += $length; 
			if( !defined($len{$int}) ) { 
				$len{$int} = 1;  
			} else { 
				$len{$int}++; 
			}   
			$gcCount += ($curr->seq()  =~ tr/gGcC/gGcC/);
			###################
		
			#print STDOUT "Sequence: ".$header."\t".$length." bp\n";
			$totalBases += $length;
			$hash{$header} = $length;
			$counter++;
	
	    $ge5Kb++    if($length >= 5000);
	    $ge10Kb++   if($length >= 10000);
	    $ge20Kb++   if($length >= 20000);
	    $ge40Kb++   if($length >= 40000);
	    $ge80Kb++   if($length >= 80000);
	    $ge160Kb++  if($length >= 160000);
	    $ge320Kb++  if($length >= 320000);
	    $ge640Kb++  if($length >= 640000);
	    $ge1Mb++    if($length >= 1000000);
	    $ge2Mb++    if($length >= 2000000);
	    $ge4Mb++    if($length >= 4000000);
	    $ge6Mb++    if($length >= 6000000);
	    $ge8Mb++    if($length >= 8000000);
	    $ge10Mb++   if($length >= 10000000);
		}
		$maxContigLength = max @length;
		$minContigLength = min @length;
		$gcContent = sprintf "%.2f", ($gcCount/$totalBases * 100);
		$counter = ($counter - 1);
		print STDOUT "Total of ".$counter." sequences\n";
		$totalContigs = $counter;
		
		# Calculate N25, N50, N75, and N90 and counts 
		my $N25; my $N50; my $N75; my $N90; 
		my $N25count=0; my $N50count=0; my $N75count=0; my $N90count=0; 
		my $frac_covered = $totalLength; 
		@seqLengths = reverse sort { $a <=> $b } @seqLengths; 
		$N25 = $seqLengths[0]; 
		while ($frac_covered > $totalLength*3/4) { 
			$N25 = shift(@seqLengths); 
			$N25count++; $N50count++; $N75count++; $N90count++; 
			$frac_covered -= $N25; 
		} 
		$N50 = $N25; 
		while ($frac_covered > $totalLength/2) { 
			$N50 = shift(@seqLengths); 
			$N50count++; $N75count++; $N90count++; 
			$frac_covered -= $N50; 
		} 
		$N75 = $N50; 
		while ($frac_covered > $totalLength/4) { 
			$N75 = shift(@seqLengths); 
			$N75count++; $N90count++; 
			$frac_covered -= $N75; 
		} 
		$N90 = $N75; 
		while ($frac_covered > $totalLength/10) { 
			$N90 = shift(@seqLengths); 
			$N90count++; 
			$frac_covered -= $N90; 
		}
		
	  $totalContigs = commify($totalContigs);
	  $totalBases = commify($totalBases);
	  $minContigLength = commify($minContigLength);
	  $maxContigLength = commify($maxContigLength);
	  $gcContent = commify($gcContent);
	  $N25count = commify($N25count);
	  $N50count = commify($N50count);
	  $N75count = commify($N75count);
	  $N90count = commify($N90count);
	  $N25 = commify($N25);
	  $N50 = commify($N50);
	  $N75 = commify($N75);
	  $N90 = commify($N90);
	
	  $ge5Kb = commify($ge5Kb);
	  $ge10Kb = commify($ge10Kb); 
	  $ge20Kb = commify($ge20Kb); 
	  $ge40Kb = commify($ge40Kb); 
	  $ge80Kb = commify($ge80Kb); 
	  $ge160Kb = commify($ge160Kb);
	  $ge320Kb = commify($ge320Kb);
	  $ge640Kb = commify($ge640Kb);
	  $ge1Mb = commify($ge1Mb);  
	  $ge2Mb = commify($ge2Mb);  
	  $ge4Mb = commify($ge4Mb);  
	  $ge6Mb = commify($ge6Mb);  
	  $ge8Mb = commify($ge8Mb);  
	  $ge10Mb = commify($ge10Mb); 
	
	  print OUT "\"Assembly name\"\t\"".($contigs)."\"\n";	
	  print OUT "\"$prefix greater than 5kb\"\t\"".$ge5Kb."\"\n";
	  print OUT "\"$prefix greater than 10kb\"\t\"".$ge10Kb."\"\n";
	  print OUT "\"$prefix greater than 20kb\"\t\"".$ge20Kb."\"\n";
	  print OUT "\"$prefix greater than 40kb\"\t\"".$ge40Kb."\"\n";
	  print OUT "\"$prefix greater than 80kb\"\t\"".$ge80Kb."\"\n";
	  print OUT "\"$prefix greater than 160kb\"\t\"".$ge160Kb."\"\n";
	  print OUT "\"$prefix greater than 320kb\"\t\"".$ge320Kb."\"\n";
	  print OUT "\"$prefix greater than 640kb\"\t\"".$ge640Kb."\"\n";
	  print OUT "\"$prefix greater than 1Mb\"\t\"".$ge1Mb."\"\n";
	  print OUT "\"$prefix greater than 2Mb\"\t\"".$ge2Mb."\"\n";
	  print OUT "\"$prefix greater than 4Mb\"\t\"".$ge4Mb."\"\n";
	  print OUT "\"$prefix greater than 6Mb\"\t\"".$ge6Mb."\"\n";
	  print OUT "\"$prefix greater than 8Mb\"\t\"".$ge8Mb."\"\n";
	  print OUT "\"$prefix greater than 10Mb\"\t\"".$ge10Mb."\"\n";
	
		print OUT "\"Total $prefix\"\t\"$totalContigs\"\n";
		print OUT "\"Total bases in $prefix (bp)\"\t\"$totalBases\"\n";
		print OUT "\"Minimum $prefix length (bp)\"\t\"$minContigLength\"\n";
		print OUT "\"Maximum $prefix length (bp)\"\t\"$maxContigLength\"\n";
		print OUT "\"GC content (%)\"\t\"$gcContent\"\n";
		print OUT "\"N25 - 25% of total sequence length is contained in the ".$N25count." sequence(s) having a length >= \"\t".$N25."\" bp\"\n";
		print OUT "\"N50 - 50% of total sequence length is contained in the ".$N50count." sequence(s) having a length >= \"\t".$N50."\" bp\"\n";
		print OUT "\"N75 - 75% of total sequence length is contained in the ".$N75count." sequence(s) having a length >= \"\t".$N75."\" bp\"\n";
		print OUT "\"N90 - 90% of total sequence length is contained in the ".$N90count." sequence(s) having a length >= \"\t".$N90."\" bp\"\n";
	}
}
close(OUT);
exit;
