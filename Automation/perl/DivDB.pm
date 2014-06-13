package DivDB;

use DivDB::Divisionals;
use DIVDB::Events;
use DivDB::CarnivalEvents;
use DivDB::CarnivalRelays;
use DivDB::Meets;
use DivDB::Points;
use DivDB::Relays;
use DivDB::Results;
use DivDB::SDIF;
use DivDB::Stats;
use DivDB::Swimmers;
use DivDB::Teams;
use DivDB::TeamSeed;

use strict;
use warnings;
use DBI;

use base qw/Exporter/;

our @EXPORT_OK = qw(getDBConnection);

our $Division  = 'O';
our $Year      = 2014;

sub getDBConnection
{
  my $schema = 'div' . lc($Division) . '_' . $Year;
  my $dbh = DBI->connect("DBI:mysql:database=$schema",'divautomation','flippers');
  return $dbh;
}

1
