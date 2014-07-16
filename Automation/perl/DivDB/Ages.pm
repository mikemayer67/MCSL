package DivDB::Ages;
use strict;
use warnings;

use DivDB;

our $Instance;

sub new
{
  my($proto)  = @_;

  unless( defined $Instance )
  {
    my $dbh = &DivDB::getConnection;

    my %this;
    my $q = $dbh->selectall_arrayref('select ac.code,ac.text,ac.order from age_codes ac');
    foreach my $x (@$q)
    {
      my($code,$text,$order) = @$x;
      $this{labels}{$code} = $text;
      $this{order}{$code}  = $order;
    }

    $q = $dbh->selectall_arrayref('select age,code from age_groups');
    foreach my $x (@$q)
    {
      my($age,$code) = @$x;

      $this{ages}{$age} = { group  => $code,
                            order  => $this{order}{$code},
                          };
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

sub group
{
  my($this,$age) = @_;
  return $this->{ages}{$age}{group};
}

sub label
{
  my($this,$group) = @_;
  return $this->{labels}{$group};
}

sub may_swim
{
  my($this,$age,$group) = @_;

  return $this->{ages}{$age}{order} <= $this->{order}{$group};
}

1
