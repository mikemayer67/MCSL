package DivDB::Schedule;
use strict;
use warnings;

use DivDB;
use DivDB::TeamSeed;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $seed  = new DivDB::TeamSeed;
    my $team7 = $seed->team(7);

    my $dbh = &DivDB::getConnection;
    my $sql=<<SCHED_SQL;
select S.meet,
       S.week,
       T1.team,
       T2.team
from   dual_schedule S,
       seed_rank T1,
       seed_rank T2
where  T1.rank = S.home
  and  T2.rank = S.away
order  by S.week;
SCHED_SQL

    my $q = $dbh->selectall_arrayref($sql);

    my %this;

    my $max_meet=0;
    
    foreach my $x (@$q)
    {
      my($meet,$week,$home,$away) = @$x;
      $this{week}[$meet] = $week;
      $this{meet}{$home}{$away} = $meet;
      $this{meet}{$away}{$home} = $meet;
      $this{home}[$meet] = $home;
      $this{away}[$meet] = $away;

      if(defined $team7)
      {
        $this{exhibition}[$week] = {meet=>$meet,team=>$away} if ($home eq $team7);
        $this{exhibition}[$week] = {meet=>$meet,team=>$home} if ($away eq $team7);
      }

      $max_meet = $meet if $meet>$max_meet;
    }
    $this{relay_carnival} = $max_meet+1;
    $this{divisionals}    = $max_meet+2;

    $Instance = return bless \%this, (ref($proto) || $proto);
  }

  return $Instance;
}

sub week
{
  my $this = shift;

  my $meet = ( @_==1 ? $_[0] : $this->meet(@_) );

  return $this->{week}[$meet];
}

sub meet
{
  my($this,$t1,$t2) = @_;
  return $this->{meet}{$t1}{$t2};
}

sub week_and_meet
{
  my($this,$t1,$t2) = @_;
  my @rval = ( $this->week($t1,$t2), $this->meet($t1,$t2) );
  return wantarray ? @rval : \@rval;
}

sub relay_carnival_meet
{
  my($this) = @_;
  return $this->{relay_carnival};
}

sub divisionals_meet
{
  my($this) = @_;
  return $this->{divisionals};
}

sub home_team
{
  my($this,$meet) = @_;
  return $this->{home}[$meet];
}

sub away_team
{
  my($this,$meet) = @_;
  return $this->{away}[$meet];
}

sub teams
{
  my($this,$meet) = @_;
  my @rval = ( $this->home($meet), $this->away($meet) );
  return wantarray ? @rval : \@rval;
}

sub exhibition_team
{
  my($this,$week) = @_;
  return unless defined $this->{exhibition};
  return $this->{exhibition}[$week]{team};
}

sub exhibition_meet
{
  my($this,$week) = @_;
  return unless defined $this->{exhibition};
  return $this->{exhibition}[$week]{meet};
}

sub verify
{
  my($this,$week,$t1,$t2) = @_;
  return $this->week($t1,$t2) == $week;
}

1
