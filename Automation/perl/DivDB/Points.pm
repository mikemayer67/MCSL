package DivDB::Points;
use strict;
use warnings;
use Carp;

use Data::Dumper;
use Scalar::Util qw(blessed);

use DivDB;
use DivDB::Teams;

our $Instance;

sub new
{
  my($proto) = @_;

  unless ( defined $Instance )
  {
    my %this;

    my $dbh = &DivDB::getConnection;

    my $sql = 'select team,sum(points) from meets group by team';
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      $this{$x->[0]}{dual} = $x->[1];
      $this{$x->[0]}{total} = $x->[1];
    }

    $q = $dbh->selectall_arrayref('select team,points from relay_carnival');
    foreach my $x (@$q)
    {
      $this{$x->[0]}{relay} = $x->[1];
      $this{$x->[0]}{total} += $x->[1];
    }

    $q = $dbh->selectall_arrayref('select team,points from divisionals');
    foreach my $x (@$q)
    {
      $this{$x->[0]}{div} = $x->[1];
      $this{$x->[0]}{total} += $x->[1];
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this) = @_;

  my $teams = new DivDB::Teams;

  my @teams = sort { $this->{$b}{total} <=> $this->{$a}{total} } keys %$this;

  my $rval = "<h1 class=reporthead>Team Standings</h1>\n";
  $rval .= "<table id=teamstandings class=report>\n";
  $rval .= " <tr class=reporthead>\n";
  $rval .= "   <th class=reporthead>Place</th>\n";
  $rval .= "   <th class=reporthead>Team</th>\n";
  $rval .= "   <th class=reporthead>Dual Meets</th>\n";
  $rval .= "   <th class=reporthead>Relay Carnival</th>\n";
  $rval .= "   <th class=reporthead>Divisionals</th>\n";
  $rval .= "   <th class=reporthead>Total</th>\n";
  $rval .= " </tr>\n";

  my $lastScore=0;
  my $lastPlace=0;
  foreach my $i (0..$#teams)
  {
    next unless exists $teams[$i];

    my $team = $teams[$i];
    my $pts  = $this->{$team};

    my $score = $pts->{total};
    my $place = ($score==$lastScore) ? $lastPlace : $i+1;

    $rval .= " <tr class=reportbody>\n";
    $rval .= "   <td class=reportbody>$place</td>\n";
    $rval .= "   <td class=reportbold>$teams->{$team}{team_name}</td>\n";
    foreach my $type (qw/dual relay div/)
    {
      my $pts = $pts->{$type} || 0;
      $rval .= "   <td class=reportbody>$pts</td>\n";
    }
    $rval .= "   <td class=reportbold>$pts->{total}</td>\n";
    $rval .= " </tr>\n";

    $lastScore = $score;
    $lastPlace = $place;
  }

  $rval .= "</table>\n";
  return $rval;
}

1

