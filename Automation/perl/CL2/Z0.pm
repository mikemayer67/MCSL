package CL2::Z0;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code          => 2,
                  org           => 1,
                  reserved1     => 8,
                  file          => 2,
                  notes         => 30,
                  num_B         => 3,
                  num_meets     => 3,
                  num_C         => 4,
                  num_teams     => 4,
                  num_D         => 6,
                  num_swimmers  => 6,
                  num_E         => 5,
                  num_F         => 6,
                  num_G         => 6,
                  batch         => 5,
                  num_new       => 3,
                  num_renew     => 3,
                  num_change    => 3,
                  num_delete    => 3,
                ];

sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(org=>1);
    $this->decode(file=>3);
  }
  return $this;
}

1
