package DivDB::Eligible;
use strict;
use warnings;
use Carp;

use DivDB;
use DivDB::Schedule;
use DivDB::Teams;
use POSIX qw(floor);

my %gender = ( M=>'Boys', F=>'Girls' );
my $schedule = new DivDB::Schedule;
my $relay_meet = $schedule->relay_carnival_meet;

sub new
{
  my($proto) = @_;
  bless{}, (ref($proto)||$proto);
}

sub gen_html
{
  my($this) = @_;

  my $dbh = &DivDB::getConnection;

  my $teams = new DivDB::Teams;

  my $rval = "<h1 class=reporthead>Divisional Eligibility</h1>\n";

  my $sql = <<'DIV_SEED_TIMES';
select 
  s.team, 
  s.name,
  s.gender, 
  s.age, 
  ac.text,
  s.distance, 
  s.stroke, 
  s.seed_time
from 
  div_seed_times s,
  age_groups ag,
  age_codes ac
where
  ag.age = s.age and
  ac.code = ag.code
order by
  s.team,
  s.gender,
  ac.order,
  s.name,
  s.stroke_code
;
DIV_SEED_TIMES

  my $q = $dbh->selectall_arrayref($sql);
  my $last_team = '';
  my $last_group = '';
  my $last_gender = '';
  my $last_name = '';

  foreach my $x (@$q)
  {
    my($team,$name,$gender,$age,$age_group,$distance,$stroke,$seed_time) = @$x;

    $gender = $gender{$gender};
    my $group = "$age_group $gender";
    
    if($team ne $last_team)
    {
      $rval .= "</td></tr></table>\n" if length($last_gender)>0;
      my $team_name = $teams->{$team}{team_name};
      $rval .= "<h2 class=xyz>$team_name</h2>\n"; 
      $last_team = $team;
      $last_gender = '';
      $last_group = '';
      $last_name = '';
    }

    if($gender ne $last_gender)
    {
      $rval .= "</td></tr></table>\n" if length($last_gender)>0;
      $rval .= "<table class=eligible>\n";
      $last_gender = $gender;
      $last_group = '';
      $last_name = '';
    }
 
    if($group ne $last_group)
    {
      $rval .= "<tr>\n";
      $rval .= "<td class='eligible $gender' colspan=3>$group</td>\n";
      $rval .= "</tr>\n";
      $last_group = $group;
      $last_name = '';
    }

    if($name ne $last_name)
    {
      $rval .= "</td></tr>\n" if length($last_name) > 0;

      $rval .= "<tr>\n";
      $rval .= "<td class=blankcol />\n";
      $rval .= "<td class=st-name>$name</td>\n";

      $rval .= "<td class=reportbody>\n";

      $last_name = $name;
    }

    if($seed_time)
    {
      $seed_time = format_seed_time($seed_time);

      $rval .= " <div class=st-data>";
      $rval .= " <span class=seed-time>$seed_time</span>";
      $rval .= " <span class=seed-time-stroke>${distance}m $stroke</span>";
      $rval .= " </div>\n";
    }
  }

  $rval .= "</td><</tr></table>\n" if length($last_gender)>0;

  return $rval;
}

sub format_seed_time
{
  my($time) = @_;

  my $rval;

  if($time >= 60)
  {
    my $min = floor($time/60);
    my $sec = $time - 60*$min;
    $rval = sprintf('%d:%05.2f', $min, $sec);
  }
  else
  {
    $rval = sprintf('%05.2f', $time);
  }

  return $rval;
}


1
