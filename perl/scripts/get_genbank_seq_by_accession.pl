#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;
use Bio::DB::Query::GenBank;
use Bio::DB::GenBank;
use Iterator::FastaDb;
use Data::Dumper;

my $usage=<<'ENDHERE';
NAME:
get_genbank_annotation.pl

PURPOSE:
From a GI list, get sequence from ncbi

INPUT:
--infile <string> : list file having one reference per line.

OUTPUT:
STDOUT

NOTES:

BUGS/LIMITATIONS:

AUTHOR/SUPPORT:
Julien Tremblay - jtremblay514@gmail.com

ENDHERE

## OPTIONS
my ($help, $infile);
my $verbose = 0;

## SCRIPTS
GetOptions(
   'infile=s'  => \$infile,
   'verbose'   => \$verbose,
   'help'      => \$help
);
if ($help) { print $usage; exit; }

#VALIDATE
die "--infile missing\n" unless($infile);

#MAIN

my %seen;
my @queries;

open(IN, "<".$infile) or die "Can't open $infile\n";
while(<IN>){
   chomp;
   my @row = split(/\t/, $_);
   my $query = $row[0];

   if(!exists $seen{$query}){
      push(@queries, $query);  
   }
}
close(IN);

print STDERR join("\n", @queries);
my $i = 0;

for my $query (@queries){

   if($query =~ m/gi\|(\d+)\|/){
      $query = $1;
   }
   print STDERR "querying $query\n";

   my $query_obj = Bio::DB::Query::GenBank->new(-db => 'nucleotide', -query => $query );
   my $gb_obj = Bio::DB::GenBank->new;
   my $stream_obj = $gb_obj->get_Stream_by_query($query_obj);

   while (my $seq_object = $stream_obj->next_seq) {  
         
      my $species_object = $seq_object->species;
      my $species_string = $species_object->node_name;
      my $seq = $seq_object->seq;    
      my $desc = $seq_object->desc;    

      # Perlish
      # my $species_string = $seq_object->species->node_name;
      # either way, $species_string is "Homo sapiens"
         
      # get all taxa from the ORGANISM section in an array
      print STDOUT ">$query ";
      my @classification = $seq_object->species->classification;
      @classification = reverse(@classification);
      foreach $_ (@classification){
          #$_ = s/\///g;
         print STDOUT $_.";";
      }
      print STDOUT "DESC=".$desc."\n".$seq."\n";
   }
   $i++;
   #last if($i > 4);
}

exit;
