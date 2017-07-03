package CL2;
use strict;
use warnings;
use Carp;

use FileHandle;
use File::Basename qw(dirname basename);

BEGIN
{
  my $dir = dirname(__FILE__);
  my @pm = <$dir/CL2/*.pm>;
  foreach my $pm (@pm)
  {
    $pm = basename($pm,'.pm');
    next unless $pm=~/^[A-Z]\d$/;

    my $use = "use CL2::$pm;";
    eval $use;
  }
}

sub new
{
  my($proto,$filename) = @_;
  croak "Missing filename\n" unless defined $filename;

  my $fh = new FileHandle($filename);
  unless($fh)
  {
    carp "Failed to open $filename: $!\n";
    return undef;
  }

  my %this;

  my $curC1;
  my $curE0;

  while(my $line = <$fh>)
  {
    next unless $line=~/^([A-Z]\d)/;
    my $code = $1;
    my $class = "CL2::$code";

    croak "First record must be A0\n" unless exists $this{A0} || $code eq 'A0';
    croak "Only one A0 record allowed\n" if exists $this{A0} && $code eq 'A0';
    croak "Only one B1 record allowed\n" if exists $this{B1} && $code eq 'B1';

    my $rec = $class->new($line);

    croak "Internal Error:: Record code ($rec->{code}) does not match object class($code)\n"
      unless $rec->{code} eq $code;

    if($code eq 'A0')
    {
      $this{A0} = $rec;
    }
    elsif($code eq 'B1')
    {
      $this{B1} = $rec;
      $this{num}{B}++;
    }
    elsif($code eq 'B2')
    {
      push @{$this{B2}}, $rec;
      $this{num}{B}++;
    }
    elsif($code eq 'C1')
    {
      my $tc = $rec->{team_code};
      croak "Only one C1 record allowed per team ($tc)\n" if exists $this{team}{$tc}{C1};
      $this{team}{$tc} = $rec;
      $curC1 = $rec;
      $this{num}{C}++;
    }
    elsif($code eq 'C2')
    {
      croak "C2 record requirs prior C1 record\n" unless defined $curC1;
      croak "C2 and C1 records have different team codes ($rec->{team_code} vs $curC1->{team_code})\n"
        unless $rec->{team_code} eq $curC1->{team_code};
      $curC1->{C2} = $rec;
      $this{num}{C}++;
    }
    elsif($code eq 'D0')
    {
      croak "D0 record requires prior C1 record\n" unless defined $curC1;
      my $sid = $rec->{ussid};
      my $evt = $rec->{evt_number};
      croak "Only one D0 per swimmer/event\n" if exists $curC1->{swimmer}{$sid}{$evt};
      croak "Only one D0 per swimmer/event\n" if exists $curC1->{event}{$evt}{$sid};

      $curC1->verifyRoster($rec);

      $curC1->{swimmer}{$sid}{$evt} = $rec;
      $curC1->{event}{$evt}{$sid}   = $rec;
      push @{$this{D0}{$evt}}, $rec;
      $this{num}{D}++;
    }
    # skip D3
    elsif($code eq 'E0')
    {
      croak "E0 record requires prior C1 record\n" unless defined $curC1;
      my $rid = $rec->{relay_team};
      my $evt = $rec->{evt_number};
      croak "Only one E0 per relay team/event\n" if exists $curC1->{relay}{$evt}{$rid};
      $curC1->{relay}{$evt}{$rid} = $rec;
      push @{$this{E0}{$evt}},$rec;
      $curE0 = $rec;
      $this{num}{E}++;
    }
    elsif($code eq 'F0')
    {
      croak "F0 record requires prior E0 record\n" unless defined $curE0;
      my $evt = $curE0->{evt_number};
      my $leg = $rec->{prelim_leg} || $rec->{swimoff_leg} || $rec->{finals_leg};
      croak "Only one F0 per leg of a relay team\n" if exists $curE0->{F0}{$leg};

      $curC1->verifyRoster($rec);

      $curE0->{F0}{$leg} = $rec;
      $this{num}{F}++;
    }
    #skip G0
    elsif($code eq 'Z0')
    {
      croak "File type inconsistent between A0 and Z0 records\n"
        unless $rec->{file} eq $this{A0}{file};
      foreach (qw/B C D E F/)
      { 
        my $n1 = $rec->{"num_$_"} || 0;
        my $n2 = $this{num}{$_} || 0;
        croak "Number of $_ records in Z0 ($n1) does not match content of file($n2)\n"
          unless $n1==$n2;
      }
      croak "Sorry:: This module only works with single meet files\n" unless $rec->{num_meets}==1;
    }

    $curE0 = undef unless $code=~/^[EFG]/;
  }

  bless \%this, ref($proto)||$proto;
}

1
