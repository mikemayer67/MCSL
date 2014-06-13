package DivDB::Event;
use strict;
use warnings;

our @Columns = qw(number relay gender distance stroke age);
our %AgeCodes;
our %StrokeCodes;

sub new
{
  my($proto,@values) = @_;
  my %this = map { $Columns[$_] => $values[$_] } (0..$#Columns);

  my $gender = $this{gender} eq 'M' ? 'Boys' : 'Girls';
  my $age    = $AgeCodes{$this{age}};
  my $dist   = $this{distance} . 'M';
  my $stroke = $StrokeCodes{$this{stroke}};

  $this{label} = "$gender $age $dist $stroke"; 
     
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @Columns;
  return "select $columns from events where meet_type='dual'";
}

sub isRelay
{
  my $this = shift;
  return $this->{relay} eq 'Y' ? 1 : 0;
}

package DivDB::Events;
use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed);

sub new
{
  my($proto,$dbh) = @_;
  croak "Not a DBI connection ($dbh)\n" unless ref($dbh) eq 'DBI::db';

  my %this = (dbh=>$dbh);

  my $q = $dbh->selectall_arrayref('select code,text from age_codes');
  foreach my $x (@$q)
  {
    $DivDB::Event::AgeCodes{$x->[0]} = $x->[1];
  }

  $q = $dbh->selectall_arrayref('select code,value from sdif_codes where block=12');
  foreach my $x (@$q)
  {
    $DivDB::Event::StrokeCodes{$x->[0]} = $x->[1];
  }

  my $sql = DivDB::Event->sql;
  $q = $dbh->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my $event = new DivDB::Event(@$x);
    $this{$event->{number}} = $event;
  }

  bless \%this, (ref($proto)||$proto);
}

sub verify_CL2
{
  my($this,$rec) = @_;
  croak "Not a CL2::Record ($rec)\n"
    unless blessed($rec) && $rec->isa('CL2::Record');
  croak "Not a CL2::D0 or CL2::E0 ($rec)\n"
    unless $rec->isa('CL2::D0') || $rec->isa('CL2::E0');

  my $number = $rec->{evt_number};

  my %recs = ( relay    => 'relay',
               gender   => 'evt_gender',
               distance => 'evt_dist',
               stroke   => 'evt_stroke',
               age      => 'evt_age',
  );
  my $dbh = $this->{dbh};

  if(exists $this->{$number})
  {
    my $evt = $this->{$number};
    foreach my $key (keys %recs)
    {
      my $rkey  = $recs{$key};
      my $value = $rec->{$rkey};
      next unless defined $value;
      my $oldvalue = $evt->{$key};
      next if defined $oldvalue && $oldvalue eq $value;
      croak "Woa Nelly... The events cannot be changed!\n($number $key $oldvalue => $value)\n"; 
    }
  }
  else
  {
    my @values = ($number);
    foreach my $key (qw(relay gender distance stroke age))
    {
      my $rkey  = $recs{$key};
      my $value = $rec->{$rkey} if exists $rec->{$rkey};
      $this->{$number}{$key} = $value;
      push @values, (defined $value ? $value : undef);
    }

    my $values = join ',', ( map { (defined $_ ? "'$_'" : 'NULL') } @values );

    $dbh->do("insert into events values ('dual',$values)");
    $this->{$number} = new DivDB::Event(@values);
  }
}


1
