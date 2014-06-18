package DivDB::Relay;
use strict;
use warnings;

use DivDB::Schedule;

our @keys = qw(meet event team relay_team swimmer1 swimmer2 swimmer3 swimmer4 DQ time place points);

sub new
{
  my($proto,@values) = @_;
  my %this;
  @this{@keys} = @values;
  my @swimmers = splice @values, 4, 4;
  $this{swimmers} = \@swimmers;
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @keys;
  my $schedule = new DivDB::Schedule;
  my $relay_meet = $schedule->relay_carnival_meet;
  return "select $columns from relay_results where meet != $relay_meet";
}

package DivDB::Relays;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed looks_like_number);
use List::Util qw(min);
use POSIX qw(floor);

use DivDB;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my %this;

    my $dbh = &DivDB::getConnection;
    my $sql = DivDB::Relay->sql;
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $result = new DivDB::Relay(@$x);
      my($team,$relay_team,$event,$meet) = map { $result->{$_} } qw(team relay_team event meet);
      $relay_team = "$team.$relay_team";
      $this{teams}{$relay_team}{$event}[$meet] = $result;
      $this{events}{$event}{$relay_team}[$meet] = $result;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this) = @_;
  my $events   = new DivDB::Events;
  my $teams    = new DivDB::Teams;
  my $swimmers = new DivDB::Swimmers;

  my $rval;
  $rval .= "<h1 class=reporthead>Relay Event Results</h1>\n";

  $rval .= "<table class=report>\n";

  my @events = sort { $a<=>$b } keys %{$this->{events}};
  foreach my $event_number (@events)
  {
    $rval .= " <tr class=spacer></tr><tr>\n";
    $rval .= "  <td class=eventhead>$event_number</td>\n";
    $rval .= "  <td class=eventhead colspan=8>$events->{$event_number}{label}</td>\n";
    $rval .= "</tr>\n";

    my $event = $this->{events}{$event_number};
    my %times;
    my @teams = keys %$event;

    foreach my $team (@teams)
    {
      my $weeks = $event->{$team};
      $times{$team}[0]=3600.;
      foreach my $week (1..6)
      {
        if(exists($weeks->[$week]))
        {
          my $time = $weeks->[$week]{time};
          if($weeks->[$week]{DQ}=~/y/i)
          {
            $times{$team}[$week] = 'DQ';
          }
          elsif(! defined $time || $time==0.)
          {
            $times{$team}[$week] = 'NS';
          }
          else
          {
            $times{$team}[$week] = $time;
            $times{$team}[0] = $time if $time<$times{$team}[0];
          }
        }
        else
        {
          $times{$team}[$week] = '';
        }
      }
    }

    @teams = sort { $times{$a}[0] <=> $times{$b}[0] } @teams;

    foreach my $team (@teams)
    {
      $team=~/^(\w+)\.([AB])/i;
      my $team_code = $1;
      my $ab = uc($2);
      my $name = $teams->{$team_code}{team_name};
      
      $rval .= " <tr>\n";
      $rval .= "   <td></td>\n";
      $rval .= "   <td class='reportbold swimmer'>$name - $ab</td>\n";
      foreach my $week (1..6)
      {
        my $time = time_string($times{$team}[$week]);
        $rval .= "  <td class=reportbody>$time</td>\n";
      }
      my $time = time_string($times{$team}[0]);
      $rval .= "  <td class=reportbold>$time</td>\n";
      $rval .= " </tr>\n";

      $rval .= " <tr><td></td><td colspan=8 class=reportbody>\n";
      foreach my $week (1..6)
      {
        next unless exists $event->{$team}[$week]{swimmers};
        my @swimmers = @{$event->{$team}[$week]{swimmers}};

        if(@swimmers)
        {
          my $names = join ' - ', 
          map { my $name = defined $_ ? $swimmers->{$_}{name} : "No Name";
               $name = "$2 $1" if $name=~/(.*),\s*(.*)/;
               $name } @swimmers;

          $rval .= "<div class=relayswimmers>Week $week: $names</div>\n";
        }
      }
      $rval .= "  </td>\n";
    }
  }
  $rval =~s/Week 6/Div./g;
  $rval .= "</table>\n";

  return $rval;
}

sub time_string
{
  my $time = shift;
  return $time unless looks_like_number($time);
  return '' if $time>=3600;
  return sprintf("%.2f",$time) if $time<60;
  my $min  = floor($time/60);
  return sprintf("%d:%05.2f", $min, $time-60*$min);
}


1

