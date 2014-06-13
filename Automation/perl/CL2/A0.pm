package CL2::A0;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code      => 2,
                  org       => 1,
                  vers      => 8,
                  file      => 2,
                  reserved1 => 30,
                  software  => 20,
                  sw_vers   => 10,
                  contact   => 20,
                  c_phone   => 12,
                  created   => 8,
                  reserved2 => 42,
                  LSC       => 2 ];

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
