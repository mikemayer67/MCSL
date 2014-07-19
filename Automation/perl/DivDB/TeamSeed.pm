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
    
    my $maxRank=0;

    foreach my $x (@$q)
    {
      my($team,$rank) = @$x;
      $this{rank}{$team} = $rank;
      $this{team}[$rank] = $team;
      $maxRank = $rank if $rank>$maxRank;
    }

    die "Need to update algorithm to handle a division $maxRank teams\n"
      if $maxRank<6 || $maxRank>7;

    foreach (1..$maxRank)
    {
      die "Missing team with rank $_\n" unless defined $this{team}[$_];
    }

    $this{maxRank} = $maxRank;

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

sub count
{
  my($this) = @_;
  return $this->{maxRank};
}

1
