package DivDB::TeamSeed;
use strict;
use warnings;

sub new
{
  my($proto,$dbh) = @_;

  my $sql = 'select team,rank from seed_standings';
  my $q = $dbh->selectall_arrayref($sql);

  my %this;
  
  foreach my $x (@$q)
  {
    my($team,$rank) = @$x;
    $this{rank}{$team} = $rank;
    $this{team}{$rank} = $team;
  }

  return bless \%this, (ref($proto) || $proto);
}

1
