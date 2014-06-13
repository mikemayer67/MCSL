package CL2::D3;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code         => 2,
                  ussnum       => 14,
                  first_name   => 15,
                  ethnicity    => 2,
                  jr_high      => 1,
                  sr_high      => 1,
                  ymca_ywca    => 1,
                  college      => 1,
                  summer       => 1,
                  masters      => 1,
                  disabled     => 1,
                  water_polo   => 1,
                  none         => 1,
                ];


sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(ethnicity=>26);
  }

  return $this;
}

1
