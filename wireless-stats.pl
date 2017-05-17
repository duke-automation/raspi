#!/usr/bin/perl -w

use strict;

my $host = `/bin/hostname -s`;
chomp($host);

my $wirelessInt = `./get-config.rb -I`;
chomp($wirelessInt);
my $loggerCommand='/usr/bin/logger';
my $statsPath = "/sys/class/net/${wirelessInt}/statistics";

my @tmpArray;
my @statsArray = (
'collisions',
'rx_errors',
'rx_packets',
'tx_errors',
'multicast',
'rx_fifo_errors',
'tx_aborted_errors',
'tx_fifo_errors',
'rx_bytes',
'rx_frame_errors',
'tx_bytes',
'tx_heartbeat_errors',
'rx_compressed',
'rx_length_errors',
'tx_carrier_errors',
'tx_packets',
'rx_crc_errors',
'rx_missed_errors',
'tx_compressed',
'tx_window_errors',
'rx_dropped',
'rx_over_errors',
'tx_dropped',
);

sub get_wireless_stats() {

  foreach my $stat (@statsArray) {
    my $statFile = $statsPath . "/" . $stat;
    open(S,"<$statFile") || warn "Can't open file $statFile:$!\n";
    my $statValue = <S>;
    chomp($statValue);
    my $statEntry = $stat . "=\"" . $statValue . "\"";
    push(@tmpArray,$statEntry);
  }
  return @tmpArray;
}

my @getArray = &get_wireless_stats();
my @outArray = join(" ", @getArray);
system "${loggerCommand} @outArray";
print "@outArray\n";

