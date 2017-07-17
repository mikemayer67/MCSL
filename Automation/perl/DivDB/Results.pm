package DivDB::Result;
use strict;
use warnings;

our @keys = qw(meet event swimmer DQ time place points);

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
  return "select $columns from individual_results";
}

package DivDB::Results;
use strict;
use warnings;
no warnings qw(uninitialized);
use Carp;

our %AllStarTimes;

use Data::Dumper;
use Scalar::Util qw(blessed looks_like_number);
use List::Util qw(min max);
use POSIX qw(floor);

use DivDB;
use DivDB::Events;
use DivDB::Swimmers;
use DivDB::Teams;

our $Instance;

sub new
{
  my($proto) = @_;
  
  unless( defined $Instance )
  {
    my %this;

    my $dbh = &DivDB::getConnection;
    my $sql = DivDB::Result->sql;
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my $result = new DivDB::Result(@$x);
      my($swimmer,$event,$meet) = map { $result->{$_} } qw(swimmer event meet);
      $this{swimmers}{$swimmer}{$event}{$meet} = $result;
      $this{events}{$event}{$swimmer}{$meet}   = $result;
    }

    $q = $dbh->selectall_arrayref('select event,time from all_star_times');
    foreach my $x (@$q)
    {
      $AllStarTimes{$x->[0]} = $x->[1];
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this,$teamFilter) = @_;
  my $events   = new DivDB::Events;
  my $swimmers = new DivDB::Swimmers;
  my $schedule = new DivDB::Schedule;

  my $seed     = new DivDB::TeamSeed;
  my $team7    = $seed->team(7);

  my $colspan = 4 + $seed->count;

  my $rval;
  
  my $label = 'Individual Event Results';
  if( defined $teamFilter )
  {
    my $teams = new DivDB::Teams;
    $label = $teams->{$teamFilter}{team_name};
  }
  $rval .= "<h1 class=reporthead>$label</h1>\n";
  $rval .= "<table class=report>\n";

  my @events = sort { $a<=>$b } keys %{$this->{events}};
  foreach my $event_number (@events)
  {
    $rval .= " <tr class=spacer></tr><tr>\n";
    $rval .= "  <td class=eventhead>$event_number</td>\n";

    $rval .= "<td class=eventhead colspan=2>$events->{$event_number}{label}</td>\n";
    foreach my $week ( 1..5 )
    {
      $rval .= "<td class=eventcolhead>Week $week</td>\n";
    }
    if(defined $team7)
    {
      my $week = $team7;
      $week=~s/^PV//;
      $rval .= "<td class=eventcolhead>Week $week</td>\n";
    }
    $rval .= "<td class=eventcolhead>Div.</td>\n";
    $rval .= "<td class=eventcolhead><b>Best</b></td></tr>\n";
    $rval .= "</tr>\n";

    my $event = $this->{events}{$event_number};

    my %times;
    my %best_time;
    my @swimmers = keys %$event;

    foreach my $swimmer (@swimmers)
    {
      my $team = $swimmers->{$swimmer}{team};

      my $meets = $event->{$swimmer};
      foreach my $meet ( keys %$meets )
      {
        my $time = $meets->{$meet}{time};

        my $week;
        if($meet == $schedule->divisionals_meet)
        {
          $week = 'div';
        }
        else
        {
          $week = $schedule->week($meet);
          if ( $team eq $schedule->exhibition_team($week) &&
               $meet eq $schedule->exhibition_meet($week) )
          {
            $week = $team7 
          }
        }
     
        if($meets->{$meet}{DQ}=~/y/i)
        {
          $times{$swimmer}{$week} = 'DQ';
        }
        elsif(defined $time)
        {
          if($time=~/dnf/i)
          {
            $times{$swimmer}{$week} = 'DNF';
          }
          elsif($time==0.)
          {
            $times{$swimmer}{$week} = 'NS';
          }
          else
          {
            my $bad_time = 0;
            if( $DivDB::Year==2013 ) {
              if($week==1) {
                if( $swimmers->{$swimmer}{team}=~/(EG|WLP)$/i ) {
                  $bad_time = 1;
                }
              }
            }

            if($bad_time)
            {
              $times{$swimmer}{$week} = -$time;
            }
            else
            {
              $times{$swimmer}{$week} = $time;
              $best_time{$swimmer} = $time unless defined $best_time{$swimmer};
              $best_time{$swimmer} = $time if $time<$best_time{$swimmer};
            }
          }
        }
        else
        {
          $times{$swimmer}{$week} = '';
        }
      }
    }
    
    @swimmers = sort { defined $best_time{$a}
                       ? ( defined $best_time{$b}
                           ? $best_time{$a} <=> $best_time{$b}
                           : -1 )
                       : ( defined $best_time{$b}
                           ? 1
                           : $a cmp $b )
                     } @swimmers;

    foreach my $swimmer (@swimmers)
    {
      my $team = $swimmers->{$swimmer}{team};
      
      next if (defined $teamFilter) && ($team ne $teamFilter);

      my $name = $swimmers->{$swimmer}{name};
      $name = "$2 $1" if $name=~/(.*),(.*)/;

      my $team_key = $team;
      $team_key=~s/^PV//;

      $rval .= " <tr>\n";
      $rval .= "   <td></td>\n";
      $rval .= "   <td class='reportbold swimmer'>$name</td>\n";
      $rval .= "   <td class=reportbody>$team_key</td>\n";

      foreach my $week (1..5)
      {
        my $time = $times{$swimmer}{$week};
        my $style;
        if(looks_like_number($time) && $time<0.)
        {
          $time = -$time;
          $time = time_string($time);
          $style = 'reportbad';
        }
        else
        {
          $time = time_string($time,$event_number);
          $style = 'reportbody';
        }

        $time = '' unless defined $time;
        $rval .= "  <td class=$style>$time</td>\n";
      }

      if(defined $team7)
      {
        my $time = $times{$swimmer}{$team7};
        my $style;
        if(looks_like_number($time) && $time<0.)
        {
          $time = -$time;
          $time = time_string($time);
          $style = 'reportbad';
        }
        else
        {
          $time = time_string($time,$event_number);
          $style = 'reportbody';
        }

        if($time)
        {
          my $real_week = $schedule->week($team,$team7);
          $time = "($real_week) $time";
        }
        else
        {
          $time = '' unless defined $time;
        }

        $rval .= "  <td class=$style>$time</td>\n";
      }

      my $time = $times{$swimmer}{div};
      my $style;
      if(looks_like_number($time) && $time<0.)
      {
        $time = -$time;
        $time = time_string($time);
        $style = 'reportbad';
      }
      else
      {
        $time = time_string($time,$event_number);
        $style = 'reportbody';
      }
      $time = '' unless defined $time;
      $rval .= "  <td class=$style>$time</td>\n";  # divisionals go here

      $time = time_string($best_time{$swimmer},$event_number);
      $time = '' unless defined $time;
      $rval .= "  <td class=reportbold>$time</td>\n";

      $rval .= " </tr>\n";

    }

    my $allstar = time_string($AllStarTimes{$event_number});
    $rval .= "<tr><td colspan=$colspan class=allstar>(All Star Time = $allstar)</td></tr>\n";

    if($DivDB::Year==2013)
    {
      $rval .= "<tr><td><td colspan=9 class='reportnote'>Due to an automation glitch, week 1 times for the EG/WLP meet are unofficial</td></tr>\n";
    }
  }

  $rval .= "</table>\n";


  return $rval;
}

sub time_string
{
  my $time = shift;
  my $event = shift;
  return $time unless looks_like_number($time);
  return '' if $time>=3600;
  my $star = defined $event && $time<$AllStarTimes{$event} ? ' * ' : '';
  return sprintf("$star%.2f$star",$time) if $time<60;

  my $min  = floor($time/60);
  return sprintf("$star%d:%05.2f$star", $min, $time-60*$min);
}

1
