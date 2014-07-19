#!/bin/ksh --  # -*-perl-*-
eval 'exec $PERL $0 ${1+"$@"}'
  if 0;

use strict;

my ($path,$cmd) = (".",$0);
if( $0 =~ /\/([^\/]+)$/ ) { ($path,$cmd) = ($`,$1); }

open (SQL,">points.sql");

foreach my $event (1..50)
{
  if($event==3 || $event==4 || $event==49 || $event==50)
  {
    print SQL "insert into points values ($event,1,8,'dual');\n";
    print SQL "insert into points values ($event,2,4,'dual');\n";
    print SQL "insert into points values ($event,3,2,'dual');\n";
  }
  else
  {
    print SQL "insert into points values ($event,1,6,'dual');\n";
    print SQL "insert into points values ($event,2,4,'dual');\n";
    print SQL "insert into points values ($event,3,3,'dual');\n";
    print SQL "insert into points values ($event,4,2,'dual');\n";
    print SQL "insert into points values ($event,5,1,'dual');\n";
  }
}
foreach my $event (1..50)
{
  if($event==3 || $event==4 || $event==49 || $event==50)
  {
    print SQL "insert into points values ($event,1,28,'divisional');\n";
    print SQL "insert into points values ($event,2,20,'divisional');\n";
    print SQL "insert into points values ($event,3,16,'divisional');\n";
    print SQL "insert into points values ($event,4,12,'divisional');\n";
    print SQL "insert into points values ($event,5,8,'divisional');\n";
    print SQL "insert into points values ($event,6,4,'divisional');\n";
  }
  else
  {
    print SQL "insert into points values ($event,1,16,'divisional');\n";
    print SQL "insert into points values ($event,2,13,'divisional');\n";
    print SQL "insert into points values ($event,3,12,'divisional');\n";
    print SQL "insert into points values ($event,4,11,'divisional');\n";
    print SQL "insert into points values ($event,5,10,'divisional');\n";
    print SQL "insert into points values ($event,6,9,'divisional');\n";
    print SQL "insert into points values ($event,7,7,'divisional');\n";
    print SQL "insert into points values ($event,8,5,'divisional');\n";
    print SQL "insert into points values ($event,9,4,'divisional');\n";
    print SQL "insert into points values ($event,10,3,'divisional');\n";
    print SQL "insert into points values ($event,11,2,'divisional');\n";
    print SQL "insert into points values ($event,12,1,'divisional');\n";
  }
}


