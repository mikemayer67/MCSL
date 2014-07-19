package DivDB;

use strict;
use warnings;
use DBI;

our $Division  = 'O';
our $Year      = 2014;

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
