package CL2::G0;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code          => 2,
                  org           => 1,
                  reserved1     => 12,
                  name          => 28,
                  ussid         => 12,
                  seq           => 1,
                  num_splits    => 2,
                  split_dist    => 4,
                  split_code    => 1,
                  split_time_1  => 8,
                  split_time_2  => 8,
                  split_time_3  => 8,
                  split_time_4  => 8,
                  split_time_5  => 8,
                  split_time_6  => 8,
                  split_time_7  => 8,
                  split_time_8  => 8,
                  split_time_9  => 8,
                  split_time_10 => 8,
                  prelim_final  => 1,
                ];

sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(org=>1);
    $this->decode(split_code=>15);
    $this->decode(prelim_final=>19);
  }
  return $this;
}

1
