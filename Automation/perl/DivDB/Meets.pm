package DivDB::Meet;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed);

use DivDB;
use DivDB::Schedule;

sub new
{
  my($proto,$meet,@entries) = @_;

  my $schedule = new DivDB::Schedule;
  my $seed     = new DivDB::TeamSeed;

  my $n = @entries;
  die "found $n teams rather than the expected 2\n" unless $n==2;

  die "start times do not match\n" unless $entries[0]{start} eq $entries[1]{start};
  die "end times do not match\n"   unless $entries[0]{end}   eq $entries[1]{end};

  my @teams  = map { $_->{team} } @entries;
  my $home = $schedule->home_team($meet);
  my $away = $schedule->away_team($meet);

  if( $home eq $teams[0] )
  {
    die "missing away team $away\n" unless $away eq $teams[1];
  }
  elsif( $home eq $teams[1] )
  {
    die "missing away team $away\n" unless $away eq $teams[0];
    @entries = reverse @entries;
  }
  else
  {
    die "missing home team $home\n";
  }

  die "opponent entry for $home is $entries[0]{opponent}, not $away\n"
    unless $entries[0]{opponent} eq $away;
  die "opponent entry for $away is $entries[1]{opponent}, not $home\n"
    unless $entries[1]{opponent} eq $home;

  my @scores = map { $_->{score}  } @entries;

  my @points = ( $scores[0] > $scores[1] ? ( 6, 0 ) :  # team 1 won, they get 6 points
                 $scores[0] < $scores[1] ? ( 0, 6 ) :  # team 2 won, they get 6 points
                                           ( 3, 3 ) ); # tie, both teams get 3 points

  $points[0] = 0 if $seed->rank($away)>6;
  $points[1] = 0 if $seed->rank($home)>6;

  die "incorrect number of points for $teams[0]\n" unless $points[0] == $entries[0]{points};
  die "incorrect number of points for $teams[1]\n" unless $points[1] == $entries[1]{points};

  my $week = $schedule->week($meet);

  bless { meet      => $meet,
          start     => $entries[0]{start},
          end       => $entries[0]{end},
          home      => { team=>$home, score=>$scores[0], points=>$points[0] },
          away      => { team=>$away, score=>$scores[1], points=>$points[1] },
          url       => ( ( $home eq 'PVP' || $away eq 'PVP') ? 
                           "Parkland_week_${week}A.pdf" :
                           substr($away,2) . 'v' . substr($home,2) . '.html' ),
        }, (ref($proto)||$proto);
}

sub url
{
  my($this) = @_;
  return $this->{url};
}

package DivDB::Meets;
use strict;
use warnings;
use Carp;

use DivDB;
use DivDB::Schedule;
use DivDB::Teams;

use Scalar::Util qw(blessed);
use List::Util qw(max);

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $schedule = new DivDB::Schedule;

    my %this;

    my @columns = qw(meet team start end opponent score points);

    my $dbh = &DivDB::getConnection;
    my $sql = 'select ' . (join ', ', @columns) . ' from meets';
    my $q = $dbh->selectall_arrayref($sql);

    my %meets;
    foreach my $x (@$q)
    {
      my $meet  = $x->[0];
      my %entry = map { ( $columns[$_] => $x->[$_] ) } (1..$#columns);

      push @{$meets{$meet}}, \%entry;
    }

    foreach my $meet ( keys %meets )
    {
      eval { $this{$meet} = new DivDB::Meet( $meet, @{$meets{$meet}} ) };
      croak "There is a problem with meet: $@" if $@;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this) = @_;
  my $teams = new DivDB::Teams;

  my $schedule = new DivDB::Schedule;

  my $rval;

  $rval .= "<h1 class=reporthead>Dual Meet Results</h1>\n";

  my %meets;
  foreach my $meet (keys %$this)
  {
    my $week = $schedule->week($meet);
    push @{$meets{$week}}, $meet;
  }

  foreach my $week ( sort {$a<=>$b} keys %meets )
  {
    $rval .= "<h2 class=reporthead>Week $week</h2>\n";
    my $url = "http://mcsl.org/results/$DivDB::Year/week$week";
    $rval .= "<table id=week$week class=report>\n";

    my @meets = sort { max ( $this->{$b}{home}{score},
                             $this->{$b}{away}{score} ) <=>
                       max ( $this->{$a}{home}{score},
                             $this->{$a}{away}{score} ) } @{$meets{$week}};

    foreach (@meets)
    {
      my $meet = $this->{$_};

      my $home = $meet->{home}{team};
      my $away = $meet->{away}{team};

      $rval .= " <tr class=reporthead>\n";

      if( $meet->{home}{score} > $meet->{away}{score} )
      {
        $rval .= "<td class=reportbold class=teamname>$teams->{$home}{team_name}</td>\n";
        $rval .= "<td class=reportbody>$meet->{home}{score}</td>\n";
        $rval .= "<td class=reportbold class=teamname>$teams->{$away}{team_name}</td>\n";
        $rval .= "<td class=reportbody>$meet->{away}{score}</td>\n";
      }
      else
      {
        $rval .= "<td class=reportbold class=teamname>$teams->{$away}{team_name}</td>\n";
        $rval .= "<td class=reportbody>$meet->{away}{score}</td>\n";
        $rval .= "<td class=reportbold class=teamname>$teams->{$home}{team_name}</td>\n";
        $rval .= "<td class=reportbody>$meet->{home}{score}</td>\n";
      }

      my $meet_url = $url . '/' . $meet->url;
      $rval .= "<td class=reporturl><a class=mcsldual href='$meet_url' target=_blank>Full MCSL Report</a>\n";
      $rval .= "</tr>\n";
    }
    $rval .= "</table>\n";
    $rval .= "<div class=mcsllink><a href='$url' target=_blank>All Week $week MCSL Reports</a></div>\n";
  }

  return $rval;
}

1
