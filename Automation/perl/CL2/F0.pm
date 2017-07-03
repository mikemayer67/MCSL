package CL2::F0;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code         => 2,
                  org          => 1,
                  reserved1    => 12,
                  team_code    => 6,
                  relay_team   => 1,
                  name         => 28,
                  ussid        => 12,
                  citizen      => 3,
                  birthdate    => 8,
                  age          => 2,
                  gender       => 1,
                  prelim_leg   => 1,
                  swimoff_leg  => 1,
                  finals_leg   => 1,
                  leg_time     => 8,
                  leg_code     => 1,
                  takeoff_time => 4,
                  ussnum       => 14,
                  first_name   => 15,
                ];


sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(org=>1);
    $this->decode(citizen=>9);
    $this->decode(gender=>10);
#   $this->decode(prelim_leg=>24);
#   $this->decode(swimoff_leg=>24);
#   $this->decode(finals_leg=>24);
    $this->decode(leg_code=>13);

    my $tc = $this->{team_code};
    unless ( $tc =~ /^PV/ )
    {
      $this->{team_code} = "PV$tc";
    }
  }
  return $this;
}

1
