package DivDB::Event;
use strict;
use warnings;

use DivDB::Ages;

our @Columns = qw(number relay gender distance stroke age);
our %StrokeCodes;

sub new
{
  my($proto,@values) = @_;
  my %this = map { $Columns[$_] => $values[$_] } (0..$#Columns);

  my $ages = new DivDB::Ages;

  my $gender = $this{gender} eq 'M' ? 'Boys' : 'Girls';
  my $age    = $ages->label($this{age});
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

sub relays_sql
{
  my $columns = join ',', @Columns;
  return "select $columns from events where meet_type='relays'";
}

sub isRelay
{
  my $this = shift;
  return $this->{relay} eq 'Y' ? 1 : 0;
}

sub isComparable
{
  my($this,$event) = @_;
  return undef unless $this->{relay}    eq $event->{relay};
  return undef unless $this->{gender}   eq $event->{gender};
  return undef unless $this->{distance} eq $event->{distance};
  return undef unless $this->{stroke}   eq $event->{stroke};
  return 1;
}

sub isComparableRelay
{
  my($this,$event) = @_;
  return undef unless $this->{relay}    eq $event->{relay};
  return undef unless $this->{gender}   eq $event->{gender};
  return undef unless $this->{age}      eq $event->{age};
  return undef unless $this->{distance} eq $event->{distance};
  return undef unless $this->{stroke}   eq $event->{stroke};
  return 1;
}

package DivDB::Events;
use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed);

use DivDB;

our $Instance;
our $RelayCarnival;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;

    my %this;

    my $q = $dbh->selectall_arrayref('select code,value from sdif_codes where block=12');
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

    $sql = DivDB::Event->relays_sql;
    $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $event = new DivDB::Event(@$x);
      $RelayCarnival->{$event->{number}} = $event;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub comparable_events
{
  my($this,$event) = @_;

  my @rval;
  foreach my $number ( keys %$this )
  {
    next if $number == $event;
    push @rval, $number if $this->{$number}->isComparable($this->{$event});
  }
  return @rval;
}

sub comparable_carnival_event
{
  my($this,$event) = @_;
  croak "Oops... $event is not a relay\n" unless $this->{$event}->isRelay;

  foreach my $number (keys %$RelayCarnival)
  {
    return $number if $RelayCarnival->{$number}->isComparableRelay($this->{$event});
  }
  return undef;
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

    my $dbh = &DivDB::getConnection;
    $dbh->do("insert into events values ('dual',$values)");
    $this->{$number} = new DivDB::Event(@values);
  }
}


1
