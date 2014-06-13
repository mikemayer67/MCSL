#!/bin/ksh --  # -*-perl-*-
eval 'exec $PERL $0 ${1+"$@"}'
  if 0;

use strict;
use warnings;
use Carp;

use FileHandle;
use FindBin;
use Text::CSV::Simple;

my $parser = Text::CSV::Simple->new;
foreach my $file (@ARGV)
{
  my @data = $parser->read_file($file);
  next unless @data;

  my $head = shift @data;

  my %swimmers;
  my $the_team;
  foreach my $line (@data)
  {
    my($event,$team,$name,$age,$best_time,$id) = @$line;

    $the_team=$team unless defined $the_team;
    die "Oops... multiple teams in $file ($team,$the_team)\n" unless $team eq $the_team;
    if(defined $swimmers{$id})
    {
      die "Swimmer id mismatch ($id / $name / $swimmers{$id}{name})\n" unless $name eq $swimmers{$id}{name};
    }
    else
    {
      $swimmers{$id} = { name => $name, age=>$age, events=>{} };
    }
    die "Multiple times found for $name in event $event\n" if exists $swimmers{$id}{events}{$event};
    $swimmers{$id}{events}{$event} = $best_time;
  }

  my $dst = new FileHandle(">x_$file") || die "Failed to create x_$file: $!\n";
  my @ids = sort { $swimmers{$a}{name} cmp $swimmers{$b}{name} } keys %swimmers;
  foreach my $id (@ids)
  {
    my $line = "$the_team,$id,\"$swimmers{$id}{name}\",$swimmers{$id}{age}";
    my @events = sort { $a<=>$b } keys %{$swimmers{$id}{events}};
    foreach my $event (@events)
    {
      $line .= ",$event,$swimmers{$id}{events}{$event}";
    }
    $line .= "\n";
    print $dst $line;
  }
}
