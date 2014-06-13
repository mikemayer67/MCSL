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
    my($week,$meet,$home,$away) = @$x;
    $this{$home}{$away} = [$week,$meet,'home'];
    $this{$away}{$home} = [$week,$meet,'away'];
  }

  return bless \%this, (ref($proto) || $proto);
}

sub verify
{
  my($this,$week,$t1,$t2) = @_;
  return $this->{$t1}{$t2}[0] == $week if exists $this->{$t1} && exists $this->{$t1}{$t2};
  return $this->{$t2}{$t1}[0] == $week if exists $this->{$t2} && exists $this->{$t2}{$t1};
  return undef;
}

1

__DATA__
select S.week,
       S.meet,
       T1.team,
       T2.team
from   dual_schedule S,
       seed_standings T1,
       seed_standings T2
where  T1.rank = S.home
  and  T2.rank = S.away
order  by S.week;
