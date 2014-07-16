package DivDB::Swimmer;
use strict;
use warnings;

our @Columns = qw(ussid team name birthdate age gender ussnum);

sub new
{
  my($proto,@values) = @_;
  my %this = map { $Columns[$_] => $values[$_] } (0..$#Columns);
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @Columns;
  return "select $columns from swimmers";
}


package DivDB::Swimmers;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed);

use DivDB;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my %this;

    my $dbh = DivDB::getConnection;
    my $sql = DivDB::Swimmer->sql;
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $swimmer = new DivDB::Swimmer(@$x);
      $this{$swimmer->{ussid}} = $swimmer;
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
  croak "Not a CL2::D0 or CL2::F0 ($rec)\n"
    unless $rec->isa('CL2::D0') || $rec->isa('CL2::F0');

  my $ussid = $rec->{ussid};
  croak "Found a swimmer witout a USSID:\n".Dumper($rec) unless $ussid=~/\w/;

  my @keys = @DivDB::Swimmer::Columns[1..$#DivDB::Swimmer::Columns];

  my $dbh = DivDB::getConnection;

  if(exists $this->{$ussid})
  {
    my $swimmer = $this->{$ussid};
    foreach my $key (@keys)
    {
      my $value = $rec->{$key};
      next unless defined $value;
      my $oldvalue = $swimmer->{$key};
      next if defined $oldvalue && $oldvalue eq $value;
      warn "Updating $key for swimmer $ussid from $oldvalue to $value\n"
        if defined $oldvalue;
      $value=~s/'/''/g;
      $dbh->do("update swimmers set $key='$value' where ussid='$ussid'");
    }
  }
  else
  {
    my @values;
    foreach my $key (@keys)
    {
      my $value = $rec->{$key} if exists $rec->{$key};
      $this->{$ussid}{$key} = $value;
      if(defined $value)
      {
        $value=~s/'/''/g;
        push @values, "'$value'";
      }
      else
      {
        push @values, 'NULL';
      }
    }
    my $values = join ',', ("'$ussid'", @values);
    $dbh->do("insert into swimmers values ($values)");
  }
}

sub verify_ussnum
{
  my($this,$rec) = @_;
  croak "Not a CL2::D3 ($rec)\n" unless blessed($rec) && $rec->isa('CL2::D3');

  my $dbh = DivDB::getConnection;

  my $ussnum = $rec->{ussnum};
 
  return unless $ussnum=~/^(............)/;
  my $ussid = $1;

  if(exists $this->{$ussid})
  {
    my $oldvalue = $this->{$ussid}{ussnum};
    return if defined $oldvalue && $oldvalue eq $ussnum;
    warn "Updating ussnum for swimmer $ussid from $oldvalue to $ussnum\n" if defined $oldvalue;
    $this->{$ussid}{ussnum} = $ussnum;
    $dbh->do("update swimmers set ussnum='$ussnum' where ussid='$ussid'");
  }
  else
  {
    warn "Bad D3 record... no swimmer has ussid=$ussid\n";
  }

}


1
