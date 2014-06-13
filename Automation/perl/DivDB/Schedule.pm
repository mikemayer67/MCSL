package DivDB::Schedule;
use strict;
use warnings;

sub new
{
  my($proto,$dbh) = @_;

  my $sql = join '', <DATA>;
  my $q = $dbh->selectall_arrayref($sql);

  my %this;
  
  foreach my $x (@$q)
  {
    my($week,$home,$away) = @$x;
    $this{$week}{$home} = [ home => $away ];
    $this{$week}{$away} = [ away => $home ];
  }

  return bless \%this, (ref($proto) || $proto);
}

sub verify
{
  my($this,$week,$t1,$t2) = @_;
  
  $t1 = $this->{$week}{$t1};
  return $t1->[0] eq 'home' && $t1->[1] eq $t2;
}

1

__DATA__
select S.week,
       T1.team,
       T2.team
from   dual_schedule S,
       seed_standings T1,
       seed_standings T2
where  T1.rank = S.home
  and  T2.rank = S.away
order  by S.week;
