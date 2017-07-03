package CL2::C1;
use strict;
use warnings;
use Carp;

use base qw/CL2::Record/;

our $Template = [ code      => 2,
                  org       => 1,
                  reserved1 => 8,
                  team_code => 6,
                  team_name => 30,
                  team_abrv => 16,
                  addr1     => 22,
                  addr2     => 22,
                  city      => 20,
                  state     => 2,
                  zip_code  => 10,
                  country   => 3,
                  region    => 1,
                ];

sub new
{
  my($proto,$line) = @_;

  my $this = $proto->SUPER::new($line,$Template);
  if($this)
  {
    $this->decode(org=>1);
    $this->decode(region=>7);

    my $tc = $this->{team_code};
    unless ( $tc =~ /^PV/ )
    {
      print "Changing team code from $tc to PV$tc\n";
      $this->{team_code} = "PV$tc";
    }
  }

  return $this;
}

sub verifyRoster
{
  my($this,$rec) = @_;
  
  my $sid = $rec->{ussid};
  
  warn "$rec->{name} from $rec->{team_code} is missing USSID\n" unless length($sid);

  if(exists $this->{roster}{$sid})
  {
    foreach my $key (qw/name age birthdate gender/)
    {
      croak "Inconsistent swimmer info for $sid (multiple $key values)\n"
        unless $this->{roster}{$sid}{$key} eq $rec->{$key};
    }
  }
  else
  {
    $this->{roster}{$sid} = 
      { map { ( $_ => $rec->{$_} ) } qw(name age birthdate gender) };
  }
}

1
