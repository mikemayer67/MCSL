package CL2::B1;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code        => 2,
                  org         => 1,
                  reserved1   => 8,
                  meet        => 30,
                  addr1       => 22,
                  addr2       => 22,
                  city        => 20,
                  state       => 2,
                  zip_code    => 10,
                  country     => 3,
                  meet_code   => 1,
                  start_date  => 8,
                  end_date    => 8,
                  altitude    => 4,
                  reserved2   => 8,
                  course_code => 1 ];

sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(org=>1);
    $this->decode(meet_code=>5);
    $this->decode(course_code=>13);
  }

  return $this;
}

1
