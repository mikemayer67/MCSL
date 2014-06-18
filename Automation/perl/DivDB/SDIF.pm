package DivDB::SDIF;
use strict;
use warnings;
use Carp;

use DivDB;

our $Instance;

sub new
{
  my($proto) = @_;

  unless( defined $Instance )
  {
    my %this;

    my $dbh = &DivDB::getConnection;
    my $sql = "select block,code,value from sdif_codes";
    my $q = $dbh->selectall_arrayref($sql);
    foreach my $x (@$q)
    {
      my($block,$code,$value) = @$x;
      $this{$block}{$code} = $value;
    }

    $Instance = bless \%this, (ref($proto)||$proto);
  }

  return $Instance;
}

1
