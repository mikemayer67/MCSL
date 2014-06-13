package DivDB::SDIF;
use strict;
use warnings;
use Carp;

sub new
{
  my($proto,$dbh) = @_;
  croak "Not a DBI connection ($dbh)\n" unless ref($dbh) eq 'DBI::db';

  my %this;

  my $sql = "select block,code,value from sdif_codes";
  my $q = $dbh->selectall_arrayref($sql);
  foreach my $x (@$q)
  {
    my($block,$code,$value) = @$x;
    $this{$block}{$code} = $value;
  }

  bless \%this, (ref($proto)||$proto);
}

1
