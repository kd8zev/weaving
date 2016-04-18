#!/usr/bin/perl

#Script to fill weaving Draw Downs
#Inputs
#  Tie Up (10x10)
#  Treadiling Sequence (?x10)
#  Threading (10x?)

#For each row of the treadling sequence inspect each 
# element, for each true element OR all the corresponding
# columns of the Tie Up. Finally AND the result with each 
# column of the Threading. For any column with a TRUE mark 
# the location TRUE.

#use strict;
#use DateTime;
#use v5.10.1;
use feature "switch";

my $filename = @ARGV[0];

my @TieUp = ();
my $TieUpCnt = 0;

my @Treadling = ();
my $TreadlingCnt = 0;
my $TreadlingRpt = 1;

my @Threading = ();
my $ThreadingCnt = 0;
my $ThreadingRpt = 1;
my $ThreadingRptCnt = 1;

my $ReadState = 0;
my $line = '';
my @eles = ();
my $row = '';
my $trow = '';
my @row = ();
my @trow = ();
my $mask = '';

if(not open(PATFILE,"<",$filename)){ die "Error opening $filename\nExiting.\n" };
print "Generating a Weaving Draw Down for $filename...\n";

while (<PATFILE>)
{
  chomp;
  $line = $_;
  given($ReadState) {
    when(0){ # Idle state, looking for tags
      if ($line eq "TIEUP"){$ReadState = 1; print "Reading Tieup...\n";}
      elsif ($line eq "TREADLING"){$ReadState = 2; print "Reading Treadling...\n";}
      elsif ($line eq "THREADING"){$ReadState = 3; print "Reading Threading...\n";}
    }
    when(1){ 
      #Reading Tieup
      if ($line eq ''){$ReadState = 0;next;}

      @eles = split(//,$line);
      my $j = 0;
      foreach(@eles){
        if($TieUpCnt == 0){@TieUp[$j] = '';}
        when('X'){vec(@TieUp[$j],$TieUpCnt,1)=1; $j++; }
        default { $j++;}
      }
      $TieUpCnt++;
    }
    when(2){
      #Reading Treadling
      if ($line eq ''){$ReadState = 0; next;}
      if($line =~ /^[0-9]/){ $TreadlingRpt = $line; print "Repeat Treadling ".$TreadlingRpt." times.\n";next;}

      @Treadling[$TreadlingCnt] = '';
      @eles = split(//,$line);
      my $j = 0;
      foreach(@eles){
        when('X'){vec(@Treadling[$TreadlingCnt],$j,1)=1; $j++; }
        default { vec(@Treadling[$TreadlingCnt],$j,1)=0; $j++; }
      }
      #print $line." ".@Treadling[$TreadlingCnt]." ".$TreadlingCnt."\n";
      $TreadlingCnt++;
    }
    when(3){ 
      #Reading Threading
      if ($line eq ''){$ReadState = 0;next;}
      if($line =~ /^[0-9]/){ $ThreadingRpt = $line; print "Repeat Threading ".$ThreadingRpt." times.\n";next;}

      #@Threading[$ThreadingCnt] = '';
      @eles = split(//,$line);
      my $j = 0;
      foreach(@eles){
        if($ThreadingCnt == 0){@Threading[$j] = '';}
        when('X'){vec(@Threading[$j],$ThreadingCnt,1)=1; $j++; }
        default { vec(@Threading[$j],$ThreadingCnt,1)=0; $j++; }
      }
      $ThreadingCnt++;
    }
    default{
      $ReadState = 0;
    }
  }
}
close PATFILE;
#Finished reading the input file. 

#Now we need to calculate and append the reults.
if(not open(PATFILE,">>",$filename)){ die "Error opening $filename for writing.\nExiting.\n" };

print PATFILE "\n\nDRAWDOWN\n\n";

while($TreadlingRpt){
  foreach $row (@Treadling){
    #Calculate the Tieup/Treadle mask to apply to the Threading
    @row = split(//,unpack("b*",$row));
    #foreach (@row) {print $_;};print ", ";
    my $j = 0;
    $mask = '';
    foreach my $item (@row) {
      if($item) { $mask |= @TieUp[$j]; }
      $j++;
    }
    @row = split(//,unpack("b*",$mask));
    #foreach (@row) {print $_;};print " mask, ";

    # Apply the mask to the Threading
    $ThreadingRptCnt = $ThreadingRpt;
    while($ThreadingRptCnt){
      foreach $trow (@Threading){
        my $flag = 0;
        @trow = split(//,unpack("b*",($trow & $mask)));
        foreach (@trow) { if ($_ ne '0') {$flag=1;}};
        if(($flag) == 1) { print 'X';  print PATFILE 'X'; }
        else { print ' '; print PATFILE '.'; } 
      }
      $ThreadingRptCnt--;
    }
    print "\n";
    print PATFILE "\n";
  }
  $TreadlingRpt--;
}

print PATFILE "\n";
#my $today = DateTime->now;
#print PATFILE "$today \n";
close PATFILE;

