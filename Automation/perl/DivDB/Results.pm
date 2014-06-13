package DivDB::Result;
use strict;
use warnings;

our @keys = qw(week swimmer event DQ time place points);

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
use Carp;

our %AllStarTimes;

use Data::Dumper;
use Scalar::Util qw(blessed looks_like_number);
use List::Util qw(min);
use POSIX qw(floor);

sub new
{
  my($proto,$dbh) = @_;
  croak "Not a DBI connection ($dbh)\n" unless ref($dbh) eq 'DBI::db';
  
  my %this;

  my $sql = DivDB::Result->sql;
  my $q = $dbh->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my $result = new DivDB::Result(@$x);
    my($swimmer,$event,$week) = map { $result->{$_} } qw(swimmer event week);
    $this{swimmers}{$swimmer}{$event}[$week] = $result;
    $this{events}{$event}{$swimmer}[$week] = $result;
  }

  $q = $dbh->selectall_arrayref('select event,time from all_star_times');
  foreach my $x (@$q)
  {
    $AllStarTimes{$x->[0]} = $x->[1];
  }

  bless \%this, (ref($proto)||$proto);
}

sub gen_html
{
  my($this,$events,$swimmers) = @_;
  croak "Not a DivDB::Events ($events)\n" unless blessed($events) && $events->isa('DivDB::Events');
  croak "Not a DivDB::Swimmers ($swimmers)\n" unless blessed($swimmers) && $swimmers->isa('DivDB::Swimmers');

  my $rval;
  $rval .= "<h1 class=reporthead>Individual Event Results</h1>\n";
  $rval .= "<table class=report>\n";

  my @events = sort { $a<=>$b } keys %{$this->{events}};
  foreach my $event_number (@events)
  {
    $rval .= " <tr class=spacer></tr><tr>\n";
    $rval .= "  <td class=eventhead>$event_number</td>\n";
    my $allstar = time_string($AllStarTimes{$event_number});
    $rval .= "  <td class=eventhead colspan=9>$events->{$event_number}{label}
                &nbsp;&nbsp;&nbsp;&nbsp;
                <span style='font-weight:normal'>(All Star = $allstar)</span></td>\n";
    $rval .= "</tr>\n";
    $rval .= "<tr>\n";
    $rval .= "<td colspan=3></td>\n";
    $rval .= "<td class=reportbody>Week $_</td>\n" foreach 1..5;
    $rval .= "<td class=reportbody>Div.</td>\n";
    $rval .= "<td class=reportbold>Best</td></tr>\n";

    my $event = $this->{events}{$event_number};

    my %times;
    my @swimmers = keys %$event;

    foreach my $swimmer (@swimmers)
    {
      my $weeks = $event->{$swimmer};
      $times{$swimmer}[0]=3600.;
      foreach my $week (1..6)
      {
        if(exists($weeks->[$week]))
        {
          my $time = $weeks->[$week]{time};
          if($weeks->[$week]{DQ}=~/y/i)
          {
            $times{$swimmer}[$week] = 'DQ';
          }
          elsif($time=~/dnf/i)
          {
            $times{$swimmer}[$week] = 'DNF';
          }
          elsif($time==0.)
          {
            $times{$swimmer}[$week] = 'NS';
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
              $times{$swimmer}[$week] = -$time;
            }
            unless($bad_time)
            {
              $times{$swimmer}[$week] = $time;
              $times{$swimmer}[0] = $time if $time<$times{$swimmer}[0];
            }
          }
        }
        else
        {
          $times{$swimmer}[$week] = '';
        }
      }
    }
    
    @swimmers = sort { $times{$a}[0] <=> $times{$b}[0] } @swimmers;

    foreach my $swimmer (@swimmers)
    {
      my $team = $swimmers->{$swimmer}{team};
      my $name = $swimmers->{$swimmer}{name};
      $name = "$2 $1" if $name=~/(.*),(.*)/;
      $team=~s/^PV//;
      $rval .= " <tr>\n";
      $rval .= "   <td></td>\n";
      $rval .= "   <td class='reportbold swimmer'>$name</td>\n";
      $rval .= "   <td class=reportbody>$team</td>\n";
      foreach my $week (1..6)
      {
        my $time = $times{$swimmer}[$week];
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

        $rval .= "  <td class=$style>$time</td>\n";
      }
      my $time = time_string($times{$swimmer}[0],$event_number);
      $rval .= "  <td class=reportbold>$time</td>\n";

      $rval .= " </tr>\n";

    }
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
