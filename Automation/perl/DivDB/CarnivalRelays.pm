package DivDB::CarnivalRelay;
use strict;
use warnings;

use DivDB::Schedule;

our @keys = qw(event team swimmer1 swimmer2 swimmer3 swimmer4 DQ time place points);

sub new
{
  my($proto,@values) = @_;
  my %this;
  @this{@keys} = @values;
  my @swimmers = splice @values, 2, 4;
  $this{swimmers} = \@swimmers;
  bless \%this, (ref($proto)||$proto);
}

sub sql
{
  my $columns = join ',', @keys;
  my $schedule = new DivDB::Schedule;
  my $relay_meet = $schedule->relay_carnival_meet;
  return "select $columns from relay_results where meet = $relay_meet";
}

package DivDB::CarnivalRelays;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed looks_like_number);
use List::Util qw(min);
use POSIX qw(floor);

use DivDB;
use DivDB::CarnivalEvents;

our $Instance;

sub new
{
  my($proto) = @_;
  
  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;

    my %this;

    my $sql = DivDB::CarnivalRelay->sql;
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $result = new DivDB::CarnivalRelay(@$x);
      my $event = $result->{event};
      my $team  = $result->{team};
      $this{teams}{$team}{$event} = $result;
      $this{events}{$event}{$team} = $result;

      $this{total}{$team} += $result->{points} if defined $result->{points};
    }

    $q = $dbh->selectall_arrayref('select team,place1,place2,place3,place4 from rc_coaches');
    foreach my $x (@$q)
    {
      my($team,@places) = @$x;
      $this{coaches}{$team} = \@places;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this) = @_;
  my $teams    = new DivDB::Teams;
  my $swimmers = new DivDB::Swimmers;

  my $events = new DivDB::CarnivalEvents;

  my $rval;
  $rval .= "<h1 class=reporthead>Relay Carnival Results</h1>\n";

  $rval .= "<h2 class=reporthead>Team Scores</h2>\n";
  $rval .= "<table class=report>\n";
  foreach my $team ( sort { $this->{total}{$b} <=> $this->{total}{$a} } keys %{$this->{total}} )
  {   
    $rval .= " <tr><td class=reportbold>$teams->{$team}{team_name}</td>\n";
    $rval .= "     <td class=reportbody>$this->{total}{$team}</td>\n";
    $rval .= " </tr>\n";
  }
  $rval .= "</table>\n";

  my @teams = sort { $this->{coaches}{$a}[3] <=> $this->{coaches}{$b}[3] } keys %{$this->{coaches}};

  $rval .= "<h2 class=reporthead>Coaches' 100M Medley Relay</h2>\n";
  $rval .= "<table class=report>\n";
  $rval .= " <tr class=reporthead>\n";
  $rval .= "  <th></th>\n";
  $rval .= "  <th class=reporthead>25m</th>\n";
  $rval .= "  <th class=reporthead>50m</th>\n";
  $rval .= "  <th class=reporthead>75m</th>\n";
  $rval .= "  <th class=reporthead>100m</th>\n";
  $rval .= " </tr>\n";
  foreach my $team (@teams)
  {
    my $name = $teams->{$team}{team_name};
    $rval .= " <tr>\n";
    $rval .= "  <td class=reportbold>$name</td>\n";
    foreach my $i (0..3)
    {
      my $c = ($i==3 ? 'reportbold' : 'reportbody');
      my $place = $this->{coaches}{$team}[$i];
      $place .= ( $place==1 ? 'st' :
                  $place==2 ? 'nd' :
                  $place==3 ? 'rd' : 'th' );
      $rval .= "  <td class=$c>$place place</td>\n";
    }
    $rval .= " </tr>\n";
  }

  $rval .= "</table>\n";



  $rval .= "<h2 class=reporthead>Event Results</h2>\n";
  $rval .= "<table class=report>\n";

  my @events = sort { $a<=>$b } keys %{$this->{events}};
  foreach my $event_number (@events)
  {
    $rval .= " <tr class=spacer></tr><tr>\n";
    $rval .= "  <td class=eventhead>$event_number</td>\n";
    $rval .= "  <td class=eventhead colspan=4>$events->{$event_number}{label}</td>\n";
    $rval .= "</tr>\n";

    my $event = $this->{events}{$event_number};
    my %time;
    my @teams = keys %$event;

    foreach my $team (@teams)
    {
      if(exists($event->{$team}))
      {
        my $time = $event->{$team}{time};
        if($event->{$team}{DQ}=~/y/i)
        {
          $time{$team} = 'DQ';
        }
        elsif(! defined $time || $time==0.)
        {
          $time{$team} = 'NS';
        }
        else
        {
          $time{$team} = $time;
        }
      }
      else
      {
        $time{$team} = '';
      }
    }

    @teams = sort { looks_like_number($time{$a}) ? 
                    ( looks_like_number($time{$b}) ? $time{$a} <=> $time{$b} : -1 ) :
                    ( looks_like_number($time{$b}) ? 1 : $a cmp $b) } @teams;

    foreach my $team (@teams)
    {
      my $name = $teams->{$team}{team_name};
      my $time = time_string($time{$team});
      my $points = $event->{$team}{points};
      unless($points && looks_like_number($points))
      {
        $points = looks_like_number($time{$team}) ? 'X' : '';
      }

      my $names='';
      if(exists $event->{$team}{swimmers})
      {
        my @swimmers = @{$event->{$team}{swimmers}};
        $names = join ' - ', 
        map { my $name = defined $_ ? $swimmers->{$_}{name} : "No Name";
              $name = "$2 $1" if $name=~/(.*),\s*(.*)/;
              $name } @swimmers;
      }
      
      $rval .= " <tr>\n";
      $rval .= "   <td></td>\n";
      $rval .= "   <td class='reportbold swimmer'>$name</td>\n";
      $rval .= "   <td class=reportbody><div class=relayswimmers>$names<div></td>\n";
      $rval .= "   <td class=reportbold>$time</td>\n";
      $rval .= "   <td class=reportbody>$points</td>\n";

      $rval .= " </tr>\n";
    }
  }
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
