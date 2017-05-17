#!/usr/bin/perl -w

use strict;

my $wirelessInt = `./get-config.rb -I`;
chomp($wirelessInt);
my $iwconfigCommand="/sbin/iwconfig ${wirelessInt}";
my $loggerCommand='/usr/bin/logger ';

&get_iwconfig;

sub get_iwconfig() {
  open(CMD,"$iwconfigCommand |") || die "Can't run $iwconfigCommand:$!\n";
  my @data = <CMD>;

  my ($ssid,$frequency,$frequency_unit,$access_point,$bit_rate,$bit_rate_unit,$sensitivity,$link_quality,$signal_level,$noise_level,$rx_invalid_nwid,$rx_invalid_crypt,$rx_invalid_frag,$tx_excess_retries,$invalid_misc,$missed_beacon);
  
  foreach my $line (@data) {
    chomp($line);
    $ssid = $1 if ($line =~ m/${wirelessInt}.*ESSID:(.*?)\sNick/);
    $ssid =~ s/"//g;
    if ($line =~ m/^\s+Mode:Managed\s+Frequency:(.*?)\s+(\w+)\s+Access\s+Point:\s+(.*?)$/) {
      $frequency = $1;
      $frequency_unit = $2;
      $access_point = $3;
    } elsif ($line =~ m/^\s+Bit\s+Rate:(.*?)\s+(\w+\/\w+)\s+Sensitivity:(.*?)$/) {
      $bit_rate = $1;
      $bit_rate_unit = $2;
      $sensitivity = $3;
    } elsif ($line =~ m/^\s+Link\s+Quality=(.*?)\s+Signal\s+level=(.*?)\s+Noise\s+level=(.*?)$/) {
      $link_quality = $1;
      $signal_level = $2;
      $noise_level = $3;
    } elsif ($line =~ m/^\s+Rx\s+invalid\s+nwid:(.*?)\s+Rx\s+invalid\s+crypt:(.*?)\s+Rx\s+invalid\s+frag:(.*?)$/) {
      $rx_invalid_nwid = $1;
      $rx_invalid_crypt = $2;
      $rx_invalid_frag = $3;
    }
    if ($line =~ m/^\s+Tx\s+excessive\s+retries:(.*?)\s+Invalid\s+misc:(.*?)\s+Missed\s+beacon:(.*?)$/) {
      $tx_excess_retries = $1;
      $invalid_misc = $2;
      $missed_beacon = $3;
    }
  }
  $link_quality =~ s/\/\d+// if ($link_quality);
  $signal_level =~ s/\/\d+// if ($signal_level);
  $noise_level =~ s/\/\d+// if ($noise_level);
  $sensitivity =~ s/\/\d+// if ($sensitivity);
  my $outString = "ssid=\"$ssid\",freq=\"$frequency\",freq_unit=\"$frequency_unit\",ap=\"$access_point\",bit_rate=\"$bit_rate\",bit_rate_unit=\"$bit_rate_unit\",sensitivity=\"$sensitivity\",link_quality=\"$link_quality\",signal_level=\"$signal_level\",noise_level=\"$noise_level\",rx_invalid_nwid=\"$rx_invalid_nwid\",rx_invalid_crypt=\"$rx_invalid_crypt\",rx_invalid_frag=\"$rx_invalid_frag\",tx_excess_retries=\"$tx_excess_retries\",invalid_misc=\"$invalid_misc\",missed_beacon=\"$missed_beacon\"";
  $outString =~ s/\s+//g;
  $outString =~ s/,/ /g;
  print "$outString\n";
  system "${loggerCommand} $outString";
}
