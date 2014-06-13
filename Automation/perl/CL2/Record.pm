package CL2::Record;
use strict;
use warnings;
use Carp;

our %Templates;
our $Codes;

sub new
{
  my($proto,$line,$tmpl) = @_;
  my $class = ref($proto) || $proto;

  $Templates{$class} = parse_template($tmpl) unless exists $Templates{$class};

  my $regex = $Templates{$class}{regex};
  my @keys  = @{$Templates{$class}{keys}};

  my(@v) = $line=~/^$regex/;
  unless(@v == @keys)
  {
    carp "Failed to parse $line as $class\n" unless @v;
    return undef;
  }

  my %rval;
  map { s/^\s+//g; s/\s+$//g; } @v;
  @rval{@keys} = @v;

  bless \%rval, $class;
}

sub parse_template
{
  my $tmpl = shift;
  my $n = @$tmpl / 2;
  
  my %rval;
  foreach my $i (0..$n-1)
  {
    push @{$rval{keys}}, $tmpl->[2*$i];
    my $pattern = '(' . "."x$tmpl->[2*$i+1] . ')';
    $rval{regex} .= $pattern; 
  }
  return \%rval;
}

sub decode
{
  return;
  my($this,$key,$block) = @_;
  &load_codes unless defined $Codes;

  my $code  = $this->{$key};
  return unless defined $code;
  return unless exists $Codes->{$block};
  return unless exists $Codes->{$block}{$code};

  $this->{$key} = $Codes->{$block}{$code};
}

sub load_codes
{
  my $block;
  while(<DATA>)
  {
    if(/^block=(\d+)/)
    {
      $block = $1;
    }
    elsif(/^(\w+)\s+(.*)$/)
    {
      my($key,$value) = ($1,$2);
      $value=~s/\s+$//;
      $Codes->{$block}{$key} = $value if defined $block;
    }
  }
}


1

__DATA__

1 1 USS 
1 2 Masters 
1 3 NCAA 
1 4 NCAA Div I 
1 5 NCAA Div II
1 6 NCAA Div III
1 7 YMCA
1 8 FINA
1 9 High School

2 AD Adirondack 
2 AK Alaska 
2 AM Allegheny Mountain 
2 AR Arkansas 
2 AZ Arizona 
2 BD Border 
2 CA Southern California 
2 CC Central California 
2 CO Colorado 
2 CT Connecticut 
2 FG Florida Gold Coast 
2 FL Florida 
2 GA Georgia 
2 GU Gulf 
2 HI Hawaii 
2 IA Iowa 
2 IE Inland Empire 
2 IL Illinois 
2 IN Indiana 
2 KY Kentucky 
2 LA Louisiana 
2 LE Lake Erie 
2 MA Middle Atlantic 
2 MD Maryland 
2 ME Maine 
2 MI Michigan 
2 MN Minnesota 
2 MR Metropolitan 
2 MS Mississippi 
2 MT Montana
2 MV Missouri Valley
2 MW Midwestern
2 NC North Carolina
2 ND North Dakota
2 NE New England
2 NI Niagara
2 NJ New Jersey
2 NM New Mexico
2 NT North Texas
2 OH Ohio
2 OK Oklahoma
2 OR Oregon
2 OZ Ozark
2 PC Pacific
2 PN Pacific Northwest
2 PV Potomac Valley
2 SC South Carolina
2 SD South Dakota
2 SE Southeastern
2 SI San Diego Imperial
2 SN Sierra Nevada
2 SR Snake River
2 ST South Texas
2 UT Utah
2 VA Virginia
2 WI Wisconsin
2 WT West Texas
2 WV West Virginia
2 WY Wyoming

3 01 Meet Registrations
3 02 Meet Results
3 03 OVC
3 04 National Age Group Record
3 05 LSC Age Group Record
3 06 LSC Motivational List
3 07 National Records and Rankings
3 08 Team Selection
3 09 LSC Best Times
3 10 USS Registration
3 16 Top 16
3 20 Vendor-defined code

4 AHO Antilles Netherlands (Dutch West Indies) 
4 ALB Albania 
4 ALG Algeria 
4 AND Andorra 
4 ANG Angola 
4 ANT Antigua 
4 ARG Argentina 
4 ARM Armenia 
4 ARU Aruba 
4 ASA American Samoa 
4 AUS Australia 
4 AUT Austria 
4 AZE Azerbaijan 
4 BAH Bahamas 
4 BAN Bangladesh 
4 BAR Barbados 
4 BEL Belgium 
4 BEN Benin 
4 BER Bermuda 
4 BHU Bhutan 
4 BIZ Belize 
4 BLS Belarus 
4 BOL Bolivia 
4 BOT Botswana 
4 BRA Brazil 
4 BRN Bahrain 
4 BRU Brunei 
4 BUL Bulgaria 
4 BUR Burkina Faso
4 CAF Central African Republic
4 CAN Canada
4 CAY Cayman Islands
4 CGO People's Rep. of Congo
4 CHA Chad 
4 CHI Chile 
4 CHN People's Rep. of China
4 CIV Ivory Coast 
4 CMR Cameroon 
4 COK Cook Islands
4 COL Columbia
4 CRC Costa Rica
4 CRO Croatia
4 CUB Cuba 
4 CYP Cyprus
4 DEN Denmark
4 DJI Djibouti
4 DOM Dominican Republic
4 ECU Ecuador
4 EGY Arab Republic of Egypt
4 ESA El Salvador 
4 ESP Spain
4 EST Estonia 
4 ETH Ethiopia 
4 FIJ Fiji 
4 FIN Finland 
4 FRA France 
4 GAB Gabon 
4 GAM Gambia 
4 GBR Great Britain 
4 GEO Georgia 
4 GEQ Equatorial Guinea 
4 GER Germany 
4 GHA Ghana 
4 GRE Greece 
4 GRN Grenada 
4 GUA Guatemala 
4 GUI Guinea 
4 GUM Guam 
4 GUY Guyana 
4 HAI Haiti 
4 HKG Hong Kong 
4 HON Honduras 
4 HUN Hungary 
4 INA Indonesia 
4 IND India 
4 IRI Islamic Rep. of Iran 
4 IRL Ireland 
4 IRQ Iraq 
4 ISL Iceland 
4 ISR Israel 
4 ISV Virgin Islands 
4 ITA Italy 
4 IVB British Virgin Islands 
4 JAM Jamaica 
4 JOR Jordan 
4 JPN Japan 
4 KEN Kenya 
4 KGZ Kyrghyzstan 
4 KOR Korea (South) 
4 KSA Saudi Arabia 
4 KUW Kuwait 
4 KZK Kazakhstan 
4 LAO Laos
4 LAT Latvia
4 LBA Libya
4 LBR Liberia
4 LES Lesotho
4 LIB Lebanon
4 LIE Liechtenstein
4 LIT Lithuania
4 LUX Luxembourg
4 MAD Madagascar
4 MAR Morocco
4 MAS Malaysia
4 MAW Malawi
4 MDV Maldives
4 MEX Mexico
4 MGL Mongolia
4 MLD Moldova
4 MLI Mali
4 MLT Malta
4 MON Monaco
4 MOZ Mozambique
4 MRI Mauritius
4 MTN Mauritania
4 MYA Union of Myanmar
4 NAM Namibia
4 NCA Nicaragua 
4 NED The Netherlands
4 NEP Nepal 
4 NGR Nigeria 
4 NIG Niger 
4 NOR Norway
4 NZL New Zealand
4 OMA Oman 
4 PAK Pakistan
4 PAN Panama 
4 PAR Paraguay 
4 PER Peru 
4 PHI Philippines
4 PNG Papau-New Guinea
4 POL Poland 
4 POR Portugal 
4 PRK Democratic People's Rep. of Korea 
4 PUR Puerto Rico 
4 QAT Qatar 
4 ROM Romania 
4 RSA South Africa 
4 RUS Russia 
4 RWA Rwanda 
4 SAM Western Samoa 
4 SEN Senegal 
4 SEY Seychelles 
4 SIN Singapore 
4 SLE Sierra Leone 
4 SLO Slovenia 
4 SMR San Marino 
4 SOL Solomon Islands 
4 SOM Somalia 
4 SRI Sri Lanka 
4 SUD Sudan
4 SUI Switzerland 
4 SUR Surinam 
4 SWE Sweden
4 SWZ Swaziland
4 SYR Syria
4 TAN Tanzania
4 TCH Czechoslovakia
4 TGA Tonga
4 THA Thailand
4 TJK Tadjikistan
4 TOG Togo
4 TPE Chinese Taipei
4 TRI Trinidad & Tobago
4 TUN Tunisia
4 TUR Turkey
4 UAE United Arab Emirates
4 UGA Uganda
4 UKR Ukraine
4 URU Uruguay
4 USA United States of America
4 VAN Vanuatu
4 VEN Venezuela
4 VIE Vietnam
4 VIN St. Vincent and the Grenadines
4 YEM Yemen
4 YUG Yugoslavia
4 ZAI Zaire
4 ZAM Zambia
4 ZIM Zimbabwe

5 0 Time Trials
5 1 Invitational 
5 2 Regional 
5 3 LSC Championship 
5 4 Zone 
5 5 Zone Championship 
5 6 National Championship 
5 7 Juniors
5 8 Seniors
5 9 Dual
5 A International
5 B Open
5 C League

7 1 Region 1 
7 2 Region 2 
7 3 Region 3 
7 4 Region 4 
7 5 Region 5 
7 6 Region 6 
7 7 Region 7 
7 8 Region 8
7 9 Region 9
7 A Region 10
7 B Region 11
7 C Region 12
7 D Region 13
7 E Region 14

9 2AL Dual: USA and other country
9 FGN Foreign

10 M Male
10 F Female

11 M Male
11 F Female
11 X Mixed

12 1 Freestyle
12 2 Backstroke
12 3 Breaststroke
12 4 Butterfly
12 5 Individual Medley
12 6 Freestyle Relay
12 7 Medley Relay

13 1 Short Course Meters
13 2 Short Course Yards
13 3 Long Course Meters
13 S Short Course Meters
13 Y Short Course Yards
13 L Long Course Meters
13 X Disqualified

14 U no lower limit (left character only)
14 O no upper limit (right character only)
14 1 Novice times
14 2 B standard times
14 P BB standard times
14 3 A standard times
14 4 AA standard times
14 5 AAA standard times
14 6 AAAA standard times
14 J Junior standard times
14 S Senior standard times

15 C Cumulative splits supplied
15 I Interval splits supplied

16 A Swimmer is attached to team
16 U Swimmer is swimming unattached

17 E Eastern Zone
17 S Southern Zone
17 C Central Zone
17 W Western Zone

18 GOLD Gold
18 SILV Silver
18 BRNZ Bronze
18 BLUE Blue
18 RED Red (note that fourth character is a space)
18 WHIT White

19 P Prelims
19 F Finals
19 S Swim-offs

block=20
NT No Time
NS No Swim (or No Show)
DNF Did Not Finish
DQ Disqualified
SCR Scratch

21 R Renew
21 N New
21 C Change
21 D Delete

22 1 Season 1
22 2 Season 2
22 N Year-round

24 0 Not on team for this swim
24 1 First leg
24 2 Second leg
24 3 Third leg
24 4 Fourth leg
24 A Alternate

26 Q African American
26 R Asian or Pacific Islander
26 S Caucasian
26 T Hispanic
26 U Native American
26 V Other
26 W Decline

