package DivDB::DivisionalsEntry;
use strict;
use warnings;

our @keys = qw(team start end score points);

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
  return "select $columns from divisionals";
}

package DivDB::Divisionals;
use strict;
use warnings;
use Carp;

use Scalar::Util qw(blessed);

use DivDB;
use DivDB::Teams;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;

    my %this;

    my $sql = DivDB::DivisionalsEntry->sql;
    my $q = $dbh->selectall_arrayref($sql);

    my %entries;
    foreach my $x (@$q)
    {
      my $entry = new DivDB::DivisionalsEntry(@$x);
      my $team  = $entry->{team};
      my $score = $entry->{score};
      $this{$team} = $score;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub gen_html
{
  my($this) = @_;
  my $teams = new DivDB::Teams;

  my $rval;
  $rval .= "<h2 class=reporthead>Divisionals</h2>\n";
  $rval .= "<div class=mcsllink><a href='http://mcsl.org/results/$DivDB::Year/week6/Div_$DivDB::Division.txt' target=_blank>Full MCSL Report</a></div>\n";
  $rval .= "<table class=report>\n";
  foreach my $team ( sort { $this->{$b} <=> $this->{$a} } keys %$this )
  {
    $rval .= " <tr><td class=reportbold>$teams->{$team}{team_name}</td>\n";
    $rval .= "     <td class=reportbody>$this->{$team}</td>\n";
    $rval .= " </tr>\n";
  }
  $rval .= "</table>\n";
  return $rval;
}

1
