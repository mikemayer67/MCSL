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
no warnings qw(uninitialized);
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed looks_like_number);
use List::Util qw(min max);
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
      $this{teams}{$relay_team}{$event}{$meet} = $result;
      $this{events}{$event}{$relay_team}{$meet} = $result;
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
  my $schedule = new DivDB::Schedule;
  my $swimmers = new DivDB::Swimmers;

  my $seed     = new DivDB::TeamSeed;
  my $team7    = $seed->team(7);

  my $colspan = 4 + $seed->count;

  my $rval;
  $rval .= "<h1 class=reporthead>Relay Event Results</h1>\n";
  $rval .= "<table class=report>\n";

  my @events = sort { $a<=>$b } keys %{$this->{events}};
  foreach my $event_number (@events)
  {
    $rval .= " <tr class=spacer></tr><tr>\n";
    $rval .= "  <td class=eventhead>$event_number</td>\n";
    $rval .= "  <td class=eventhead>$events->{$event_number}{label}</td>\n";
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
    $rval .= "<td class=eventcolhead><b>Best</b></td>\n";
    $rval .= "</tr>\n";

    my $event = $this->{events}{$event_number};

    my %times;
    my %best_time;
    my @teams = keys %$event;

    foreach my $team (@teams)
    {
      my $meets = $event->{$team};
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
          if( $meet eq $schedule->exhibition_meet($week) )
          {
            my $exhibition_team = $schedule->exhibition_team($week);
            $week = $team7 if $team=~/^$exhibition_team\./;
          }
        }
     
        if($meets->{$meet}{DQ}=~/y/i)
        {
          $times{$team}{$week} = 'DQ';
        }
        elsif(defined $time)
        {
          if($time==0.)
          {
            $times{$team}{$week} = 'NS';
          }
          else
          {
            $times{$team}{$week} = $time;
            $best_time{$team} = $time unless defined $best_time{$team};
            $best_time{$team} = $time if $time<$best_time{$team};
          }
        }
        else
        {
          $times{$team}{$week} = '';
        }
      }
    }

    @teams = sort { defined $best_time{$a}
                    ? ( defined $best_time{$b}
                        ? $best_time{$a} <=> $best_time{$b}
                        : -1 )
                    : ( defined $best_time{$b}
                        ? 1
                        : $a cmp $b )
                  } @teams;

    foreach my $team (@teams)
    {
      $team=~/^(\w+)\.([AB])/i;
      my $team_code = $1;
      my $ab = uc($2);
      my $name = $teams->{$team_code}{team_name};
      
      $rval .= " <tr>\n";
      $rval .= "   <td></td>\n";
      $rval .= "   <td class='reportbold swimmer'>$name - $ab</td>\n";
      foreach my $week (1..5)
      {
        my $time = time_string($times{$team}{$week});
        $time = '' unless defined $time;
        $rval .= "  <td class=reportbody>$time</td>\n";
      }
      if(defined $team7)
      {
        my $time = time_string($times{$team}{$team7});
        $time = '' unless defined $time;
        
        if($time)
        {
          my $real_week = $schedule->week($team_code,$team7);
          $time = "($real_week) $time";
        }
        $rval .= "  <td class=reportbody>$time</td>\n";
      }


      my $time = time_string($times{$team}{div});
      $time = '' unless defined $time;
#       $rval .= "  <td class=reportbody>$time</td\n";
      $rval .= "  <td class=reportbody>$time</td>\n";  # divisionals go here

      $time = time_string($best_time{$team});
      $time = '' unless defined $time;
      $rval .= "  <td class=reportbold>$time</td>\n";

      $rval .= " </tr>\n";

      $rval .= " <tr><td></td><td colspan=$colspan class=reportbody>\n";
      my $meets = $event->{$team};
      foreach my $meet ( sort { $a<=>$b } keys %$meets )
      {
        my $week;
        if( $meet == $schedule->divisionals_meet )
        {
          $week = 'div';
        }
        else
        {
          $week = $schedule->week($meet);
          if ( $team_code eq $schedule->exhibition_team($week) &&
            $meet      eq $schedule->exhibition_meet($week) )
          {
            $week = $team7;
            $week=~s/^PV//;
          }
        }

        my @swimmers = @{$meets->{$meet}{swimmers}};
        if(@swimmers)
        {
          my $names = join ' - ', 
          map { my $name = defined $_ ? $swimmers->{$_}{name} : "No Name";
               $name = "$2 $1" if $name=~/(.*),\s*(.*)/;
               $name } @swimmers;

          if($week eq 'div')
          {
            $rval .= "<div class=relayswimmers>Divisionals: $names</div>\n";
          }
          else
          {
            $rval .= "<div class=relayswimmers>Week $week: $names</div>\n";
          }
        }
      }
      $rval .= "  </td>\n";
#      $rval .= " <tr><td></td><td colspan=$colspan class=reportbody>\n";
#      foreach my $week (1..5)
#      {
#        next unless exists $event->{$team}[$week]{swimmers};
#        my @swimmers = @{$event->{$team}[$week]{swimmers}};
#
#        if(@swimmers)
#        {
#          my $names = join ' - ', 
#          map { my $name = defined $_ ? $swimmers->{$_}{name} : "No Name";
#               $name = "$2 $1" if $name=~/(.*),\s*(.*)/;
#               $name } @swimmers;
#
#          $rval .= "<div class=relayswimmers>Week $week: $names</div>\n";
#        }
#      }
#      $rval .= "  </td>\n";
    }
  }
#  $rval =~s/Week 6/Div./g;
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

