package DivDB::MeetEntry;
use strict;
use warnings;

our @keys = qw(week team team_seed start end opponent opp_seed score points);

sub new
{
  my($proto,@values) = @_;
  my %this;
  @this{@keys} = @values;
  bless \%this, (ref($proto)||$proto);
}

sub pairedWith
{
  my($t1,$t2) = @_;
  foreach (qw/week start end/)
  {
    return 0 unless $t1->{$_} eq $t2->{$_};
  }
  return 0 unless $t1->{opponent} = $t2->{team};
  return 0 unless $t2->{opponent} = $t1->{team};

  my($s1,$s2) = ( $t1->{score},  $t2->{score}  );

  my($p1,$p2) = ( $s1>$s2 ? (6,0) :  # team 1 won, they get 6 points
                  $s1<$s2 ? (0,6) :  # team 2 won, they get 6 points
                            (3,3) ); # tie, both teams get 3 points

  $p1 = 0 if $t1->{opp_seed}  > 6;  # team 1 gets no points
  $p2 = 0 if $t1->{team_seed} > 6;  # team 2 gets no points

  return ( $t1->{points}==$p1 && $t2->{points}==$p2 );
}

package DivDB::Meet;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed);

sub new
{
  my($proto,$t1,$t2,$dbh) = @_;
  croak "Not a DivDB::MeetEntry ($t1)\n" unless blessed($t1) && $t1->isa('DivDB::MeetEntry');
  croak "Not a DivDB::MeetEntry ($t2)\n" unless blessed($t2) && $t2->isa('DivDB::MeetEntry');

  croak "\nMismatched Data\n".Dumper($t1)."vs\n".Dumper($t2)."\n" unless $t1->pairedWith($t2);

  my $url = substr($t2->{team},2) . 'v' . substr($t1->{team},2) . '.html';

  ($t1,$t2) = ($t2,$t1) if $t2->{score}>$t1->{score};

  bless { week   => $t1->{week},
          start  => $t1->{start},
          end    => $t1->{end},
          tied   => $t1->{points}==$t2->{points},
          teams  => [ $t1->{team},   $t2->{team} ],
          scores => [ $t1->{score},  $t2->{score} ],
          points => [ $t1->{points}, $t2->{points} ],
          url    => $url,
        }, (ref($proto)||$proto);
}

package DivDB::Meets;
use strict;
use warnings;
use Carp;

use DivDB::Schedule;
use Scalar::Util qw(blessed);

sub new
{
  my($proto,$dbh) = @_;
  croak "Not a DBI connection ($dbh)\n" unless ref($dbh) eq 'DBI::db';

  my $schedule = new DivDB::Schedule($dbh);

  my %this;

  my $sql = join '', <DATA>;
  my $q = $dbh->selectall_arrayref($sql);

  my %entries;
  foreach my $x (@$q)
  {
    my $entry = new DivDB::MeetEntry(@$x);
    my $week     = $entry->{week};
    my $team     = $entry->{team};
    my $opponent = $entry->{opponent};
    if(exists $entries{$week}{$opponent})
    {
      if($schedule->verify($week,$team,$opponent))
      {
        push @{$this{$week}}, new DivDB::Meet($entry,$entries{$week}{$opponent});
      }
      elsif($schedule->verify($week,$opponent,$team))
      {
        push @{$this{$week}}, new DivDB::Meet($entries{$week}{$opponent},$entry);
      }
      else
      {
        croak "\nUnschedule week $week meet ($team vs $opponent)\n";
      }
      $entries{$week}{$team} = $entries{$week}{$opponent} = 'Already Processed';
    } 
    else
    {
      $entries{$week}{$team} = $entry;
    }
  }

  bless \%this, (ref($proto)||$proto);
}

sub gen_html
{
  my($this,$teams) = @_;
  croak "Not a DivDB::Teams ($teams)\n" unless blessed($teams) && $teams->isa('DivDB::Teams');

  my $rval;

  $rval .= "<h1 class=reporthead>Dual Meet Results</h1>\n";

  foreach my $week (sort keys %$this)
  {
    $rval .= "<h2 class=reporthead>Week $week</h2>\n";
    my $url = "http://mcsl.org/results/$DivDB::Year/week$week";
    $rval .= "<table id=week$week class=report>\n";

    my @meets = sort { $b->{scores}[0] <=> $a->{scores}[0] } @{$this->{$week}};
    foreach my $meet (@meets)
    {
      $rval .= " <tr class=reporthead>\n";
      $rval .= "<td class=reportbold class=teamname>$teams->{$meet->{teams}[0]}{team_name}</td>\n";
      $rval .= "<td class=reportbody>$meet->{scores}[0]</td>\n";
      $rval .= "<td class=reportbold class=teamname>$teams->{$meet->{teams}[1]}{team_name}</td>\n";
      $rval .= "<td class=reportbody>$meet->{scores}[1]</td>\n";
      $rval .= "<td class=reporturl><a class=mcsldual href='$url/$meet->{url}' target=_blank>Full MCSL Report</a>\n";
      $rval .= "</tr>\n";
    }
    $rval .= "</table>\n";
    $rval .= "<div class=mcsllink><a href='$url' target=_blank>All Week $week MCSL Reports</a></div>\n";
  }

  return $rval;
}

1

__DATA__
select week,
       M.team,
       S1.rank,
       start,
       end,
       opponent,
       S2.rank,
       score,
       points
  from meets M,
       seed_standings S1,
       seed_standings S2
 where S1.team=M.team 
   and S2.team=M.opponent;
