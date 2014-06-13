package DivDB::Stats;
use strict;
use warnings;
use Carp;

use List::MoreUtils qw(any);

sub new
{
  my($proto,$dbh) = @_;
  croak "Not a DBI connection ($dbh)\n" unless ref($dbh) eq 'DBI::db';

  bless { dbh=>$dbh }, (ref($proto)||$proto);
}

sub gen_html
{
  my($this) = @_;

  my $rval;
  $rval .= "<h1 class=reporthead>Individual Event Stats</h1>\n";
  $rval .= $this->add_gender_stats;
  $rval .= $this->add_stroke_stats;
  $rval .= $this->add_age_stats;
  $rval .= $this->add_age_stats_for_stroke($_) foreach (1..5);

  $rval .= "<H1 class=reporthead>More Coming Shortly...</H1>\n";

  return $rval;
}

sub add_gender_stats
{
  my($this) = @_;

  my $sql = <<'GENDER_WEEK_SQL';
select team,
       week,
       gender,
       avg(points)
  from ( select b.team,
                a.week,
                b.gender,
                a.event,
                sum(a.points) points
           from individual_results a,
                swimmers b
          where b.ussid=a.swimmer
          group by team,event,week,gender
       ) d
group by team,week,gender
order by team,week,gender
GENDER_WEEK_SQL


  my %results;
  my $weeks=0;
  my $q = $this->{dbh}->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($team,$week,$gender,$avg) = @$x;
    $team=~s/^PV//;
    $weeks=$week if $week>$weeks;
    $results{$team}{$week}{$gender} = sprintf("%.2f",$avg);
  }

  $sql = <<'GENDER_SQL';
select team,
       gender,
       avg(points)
  from ( select b.team,
                b.gender,
                a.week,
                a.event,
                sum(a.points) points
           from individual_results a,
                swimmers b
          where b.ussid=a.swimmer
          group by team,week,event,gender
       ) d
group by team,gender
order by team,gender
GENDER_SQL

  $q = $this->{dbh}->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($team,$gender,$avg) = @$x;
    $team=~s/^PV//;
    $results{$team}{overall}{$gender} = sprintf("%.2f",$avg);
  }

  my @teams = sort keys %results;

  my $rval = "<h2 class=reporthead>Average Points per Event by Week</h2>\n";
  $rval .= "<table class=report>\n";
  $rval .= "<tr>\n";
  $rval .= " <th colspan=2></th>\n";
  $rval .= " <th class=reporthead>$_</th>\n" foreach @teams;
  $rval .= "</tr>\n";
  foreach my $week ((1..$weeks),'overall')
  {
    $rval .= "<tr>\n";
    my $label = ($week=~/^\d+$/ ? "Week $week" : "Overall");
    $rval .= " <td class=reportbold rowspan=2>$label</td>\n";
    $rval .= " <td class='reportbold boys'>Boys</td>\n";

    my $class = ($week=~/^\d+$/ ? 'reportbody' : 'reportbold');
    foreach my $team (@teams)
    {
      my $avg = $results{$team}{$week}{M} || '';
      $rval .= " <td class='$class boys'>$avg</td>\n"
    }
    $rval .= "</tr><tr>\n";
    $rval .= " <td class='reportbold girls'>Girls</td>\n";
    foreach my $team (@teams)
    {
      my $avg = $results{$team}{$week}{F} || '';
      $rval .= " <td class='$class girls'>$avg</td>\n"
    }
    $rval .= "</tr>\n";
  }
  $rval .= "</table>\n";

  return $rval;
}


sub add_stroke_stats
{
  my($this) = @_;

  my $sql = <<'STROKE_SQL';
select value,
       gender,
       team,
       avg(points)
  from ( select b.team,
                a.week,
                a.event,
                c.stroke,
                b.gender,
                sum(a.points) points
           from individual_results a,
                swimmers b,
                events c
          where b.ussid=a.swimmer
            and c.meet_type='dual'
            and c.number=a.event
         group by team,event,week
       ) d,
       sdif_codes e
 where e.block=12
   and e.code=d.stroke
group by team,stroke,gender
order by stroke,gender,team  
STROKE_SQL

  my %results;
  my @teams;
  my @strokes;
  my $q = $this->{dbh}->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($stroke,$gender,$team,$avg) = @$x;
    $team=~s/^PV//;
    push @teams, $team unless any { $_ eq $team } @teams;
    push @strokes, $stroke unless any { $_ eq $stroke } @strokes;
    $results{$stroke}{$gender}{$team} = sprintf("%.2f",$avg);
  }
  
  @teams = sort @teams;

  my $rval = "<h2 class=reporthead>Average Points per Event by Stroke</h2>\n";
  $rval .= "<table class=report>\n";
  $rval .= "<tr>\n";
  $rval .= " <th colspan=2></th>\n";
  $rval .= " <th class=reporthead>$_</th>\n" foreach @teams;
  $rval .= "</tr>\n";
  foreach my $stroke (@strokes)
  {
    $rval .= "<tr>\n";
    $rval .= "  <td class=reportbold rowspan=2>$stroke</td>\n";
    $rval .= "  <td class='reportbold boys'>Boys</td>\n";
    $rval .= "  <td class='reportbody boys'>$results{$stroke}{M}{$_}</td>\n"
    foreach @teams;
    $rval .= "</tr><tr>\n";
    $rval .= "  <td class='reportbold girls'>Girls</td>\n";
    $rval .= "  <td class='reportbody girls'>$results{$stroke}{F}{$_}</td>\n"
    foreach @teams;
    $rval .= "</tr>\n";
  }
  $rval .= "</table>\n";

  return $rval;
}

sub add_age_stats
{
  my($this) = @_;

  my $sql = <<'AGE_SQL';
select text,
       gender,
       team,
       avg(points)
  from ( select b.team,
                a.week,
                a.event,
                c.age,
                b.gender,
                sum(a.points) points
           from individual_results a,
                swimmers b,
                events c
          where b.ussid=a.swimmer
            and c.meet_type='dual'
            and c.number=a.event
         group by team,event,week
       ) d,
       age_codes e
 where e.code=d.age
group by team,age,gender
order by e.order,gender,team  
AGE_SQL

  my %results;
  my @teams;
  my @ages;
  my $q = $this->{dbh}->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($age,$gender,$team,$avg) = @$x;
    $team=~s/^PV//;
    push @teams, $team unless any { $_ eq $team } @teams;
    push @ages, $age unless any { $_ eq $age } @ages;
    $results{$age}{$gender}{$team} = sprintf("%.2f",$avg);
  }
  
  @teams = sort @teams;

  my $rval = "<h2 class=reporthead>Average Points per Event by Age</h2>\n";
  $rval .= "<table class=report>\n";
  $rval .= "<tr>\n";
  $rval .= " <th colspan=2></th>\n";
  $rval .= " <th class=reporthead>$_</th>\n" foreach @teams;
  $rval .= "</tr>\n";
  foreach my $age (@ages)
  {
    $rval .= "<tr>\n";
    $rval .= "  <td class=reportbold rowspan=2>$age</td>\n";
    $rval .= "  <td class='reportbold boys'>Boys</td>\n";
    $rval .= "  <td class='reportbody boys'>$results{$age}{M}{$_}</td>\n"
    foreach @teams;
    $rval .= "</tr><tr>\n";
    $rval .= "  <td class='reportbold girls'>Girls</td>\n";
    $rval .= "  <td class='reportbody girls'>$results{$age}{F}{$_}</td>\n"
    foreach @teams;
    $rval .= "</tr>\n";
  }
  $rval .= "</table>\n";

  return $rval;
}

sub add_age_stats_for_stroke
{
  my($this,$stroke) = @_;

  my $sql = "select value from sdif_codes where block=12 and code=$stroke";
  my $q = $this->{dbh}->selectall_arrayref($sql);
  die "Could not translate stroke $stroke\n" unless @$q;
  die "Stroke $stroke translates to multipole values\n" if @$q>1;
  my $text = $q->[0][0];

  $sql = <<"AGE_STROKE_SQL";
select text,
       gender,
       team,
       week,
       avg(points)
  from ( select b.team,
                a.week,
                a.event,
                c.age,
                b.gender,
                sum(a.points) points
           from individual_results a,
                swimmers b,
                events c
          where b.ussid=a.swimmer
            and c.meet_type='dual'
            and c.stroke=$stroke
            and c.number=a.event
         group by team,event,week
       ) d,
       age_codes e
 where e.code=d.age
group by team,age,gender,week
order by e.order,gender,team,week;
AGE_STROKE_SQL

  my %results;
  my %teams;
  my @ages;
  my %weeks;

  $q = $this->{dbh}->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($age,$gender,$team,$week,$avg) = @$x;
    $team=~s/^PV//;
    $teams{$team} = 1;
    $weeks{$week} = 1;
    push @ages, $age unless @ages && $age eq $ages[-1];
    $results{$age}{$gender}{$team}{$week} = $avg if defined $avg;
  }
  
  my @teams = sort keys %teams;
  my @weeks = sort {$a<=>$b} keys %weeks;

  my $rval = "<h2 class=reporthead>Point Trends by Age for $text</h2>\n";
  $rval .= "<table class=report>\n";
  $rval .= "<tr>\n";
  $rval .= " <th colspan=2></th>\n";
  $rval .= " <th class=reporthead>$_</th>\n" foreach @teams;
  $rval .= "</tr>\n";
  foreach my $age (@ages)
  {
    foreach my $gender ('M','F')
    {
      my $bg = $gender eq 'M' ? 'boys' : 'girls';
      $rval .= "<tr>\n";
      $rval .= "  <td class=reportbold rowspan=2>$age</td>\n" if $gender eq 'M';
      $rval .= "  <td class='reportbold $bg'>".ucfirst($bg)."\n";
      foreach my $team (@teams)
      {
        my @v = map { $results{$age}{$gender}{$team}{$_} || '' } @weeks;
        my $v = join '-',@v;
        $rval .= "  <td class='reportbody $bg'><div class=age_stroke>$v</div>\n";
      }
    }
    $rval .= "</tr>";
  }
  $rval .= "</table>\n";

  return $rval;
}

1
