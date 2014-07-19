package DivDB::RelayCarnivalEvent;
use strict;
use warnings;

our @Columns = qw(number gender distance stroke age);
our %AgeCodes;
our %GenderCodes;
our %StrokeCodes;

sub new
{
  my($proto,@values) = @_;
  my %this = map { $Columns[$_] => $values[$_] } (0..$#Columns);

  die "Unknown age: $this{age}\n" unless exists $AgeCodes{$this{age}};

  my $gender = $GenderCodes{$this{gender}};
  my $age    = $AgeCodes{$this{age}};
  my $dist   = $this{distance} . 'M';
  my $stroke = $StrokeCodes{$this{stroke}};

  $this{label} = "$gender $age $dist $stroke"; 
     
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @Columns;
  return "select $columns from events where meet_type='relays'";
}

package DivDB::CarnivalEvents;
use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed);

use DivDB;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;

    my %this;

    my $q = $dbh->selectall_arrayref('select code,text from age_codes');
    foreach my $x (@$q)
    {
      $DivDB::RelayCarnivalEvent::AgeCodes{$x->[0]} = $x->[1];
    }

    $q = $dbh->selectall_arrayref('select code,value from sdif_codes where block=11');
    foreach my $x (@$q)
    {
      $DivDB::RelayCarnivalEvent::GenderCodes{$x->[0]} = $x->[1];
    }

    $q = $dbh->selectall_arrayref('select code,value from sdif_codes where block=12');
    foreach my $x (@$q)
    {
      $DivDB::RelayCarnivalEvent::StrokeCodes{$x->[0]} = $x->[1];
    }

    my $sql = DivDB::RelayCarnivalEvent->sql;
    $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $event = new DivDB::RelayCarnivalEvent(@$x);
      $this{$event->{number}} = $event;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub verify_CL2
{
  my($this,$rec) = @_;
  croak "Not a CL2::Record ($rec)\n"
    unless blessed($rec) && $rec->isa('CL2::Record');
  croak "Not a CL2::D0 or CL2::E0 ($rec)\n"
    unless $rec->isa('CL2::D0') || $rec->isa('CL2::E0');

  my $number = $rec->{evt_number};

  my %recs = ( gender   => 'evt_gender',
               distance => 'evt_dist',
               stroke   => 'evt_stroke',
               age      => 'evt_age',
  );

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
    my @values;
    foreach my $key (qw(gender distance stroke age))
    {
      my $rkey  = $recs{$key};
      my $value = $rec->{$rkey} if exists $rec->{$rkey};
      $this->{$number}{$key} = $value;
      push @values, (defined $value ? $value : undef);
    }

    my $values = join ',', ( map { (defined $_ ? "'$_'" : 'NULL') } @values );

    my $dbh = &DivDB::getConnection;
    $dbh->do("insert into events values ('relays',$number,'Y',$values)");
    $this->{$number} = new DivDB::RelayCarnivalEvent($number,@values);
  }
}


1
