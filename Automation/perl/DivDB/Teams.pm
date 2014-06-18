package DivDB::Team;
use strict;
use warnings;

our @Columns = qw(code team_name addr1 addr2 city state zip_code);

sub new
{
  my($proto,@values) = @_;
  my %this = map { $Columns[$_] => $values[$_] } (0..$#Columns);
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @Columns;
  return "select $columns from teams";
}

package DivDB::Teams;
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

    my $sql = DivDB::Team->sql;
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $team = new DivDB::Team(@$x);
      $this{$team->{code}} = $team;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub verify_CL2
{
  my($this,$rec) = @_;
  croak "Not a CL2::C1 ($rec)\n" unless blessed($rec) && $rec->isa('CL2::C1');

  my $code = $rec->{team_code};

  my @keys = @DivDB::Team::Columns[1..$#DivDB::Team::Columns];

  my $dbh = &DivDB::getConnection;

  if(exists $this->{$code})
  {
    my $team = $this->{$code};
    foreach my $key (@keys)
    {
      my $value = $rec->{$key};
      next unless defined $value;
      my $oldvalue = $team->{$key};
      next if defined $oldvalue && $oldvalue eq $value;
      warn "Updating $key for team $code from $oldvalue to $value\n" if defined $oldvalue;
      $dbh->do("update teams set $key='$value' where code='$code'");
    }
  }
  else
  {
    my @values;
    foreach my $key (@keys)
    {
      my $value = $rec->{$key} if exists $rec->{$key};
      $this->{$code}{$key} = $value;
      push @values, (defined $value ? "'$value'" : 'NULL');
    }
    my $values = join ',', ("'$code'", @values);
    $dbh->do("insert into teams values ($values)");
  }
}


1
