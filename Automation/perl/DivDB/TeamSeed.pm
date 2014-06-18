package DivDB::TeamSeed;
use strict;
use warnings;

use DivDB;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;
    my $sql = 'select team,rank from seed_rank';
    my $q = $dbh->selectall_arrayref($sql);

    my %this;
    
    foreach my $x (@$q)
    {
      my($team,$rank) = @$x;
      $this{rank}{$team} = $rank;
      $this{team}[$rank] = $team;
    }

    $Instance = return bless \%this, (ref($proto) || $proto);
  }
}

sub rank
{
  my($this,$team) = @_;
  return $this->{rank}{$team};
}

sub team
{
  my($this,$rank) = @_;
  return $this->{team}[$rank];
}

1
