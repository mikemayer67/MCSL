package DivDB::MeetEntry;
use strict;
use warnings;

our @keys = qw(week team start end opponent score points);

sub new
{
  my($proto,@values) = @_;
  my %this;
  @this{@keys} = @values;
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @keys;
  return "select $columns from meets";
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
  return 0 unless $t1->{points} + $t2->{points} == 6;
  return 0 unless ( ($t1->{score} > $t2->{score} && $t1->{points}==6) ||
                    ($t2->{score} > $t1->{score} && $t2->{points}==6) ||
                    ($t1->{score} == $t2->{score} && $t1->{points}==$t2->{points}) );
  return 1;
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

  my $sql = DivDB::MeetEntry->sql;
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
