package DivDB;

use strict;
use warnings;
use DBI;

our $Division  = 'N';
our $Year      = 2017;

our $Instance;

sub getConnection
{
  unless(defined $Instance)
  {
    my $schema = 'div' . lc($Division) . '_' . $Year;
    $Instance  = DBI->connect("DBI:mysql:database=$schema",'divautomation','flippers');
  }
  return $Instance;
}

1
