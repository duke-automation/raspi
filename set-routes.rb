#!/usr/bin/env /usr/bin/ruby

require 'yaml'
require 'socket'

HOST = Socket.gethostname
CONFIG = YAML.load_file('/home/raspi/wireless-test/configuration.yml')
wired_ips = CONFIG["#{HOST}"]['hosts']['wired_ips']
wireless_ips = CONFIG["#{HOST}"]['hosts']['wireless_ips']
WIREDINT = CONFIG["#{HOST}"]['interfaces']['wired']
WIFIINT = CONFIG["#{HOST}"]['interfaces']['wireless']
WIFIGW=`grep 'option routers' /var/lib/dhcp/dhclient.#{WIFIINT}.leases | tail -1 | awk '{ print $3 }' | sed -e 's/;//' | sort | uniq`.chomp
WIREDGW=`grep 'option routers' /var/lib/dhcp/dhclient.#{WIREDINT}.leases | tail -1 | awk '{ print $3 }' | sed -e 's/;//' | sort | uniq`.chomp

# set static routes (wired)
wired_ips.each do |wdip|
  puts "#{wdip} #{WIREDGW} #{WIREDINT}"
  system("sudo ip route del #{wdip} via #{WIREDGW} dev #{WIREDINT}")
  system("sudo ip route add #{wdip} via #{WIREDGW} dev #{WIREDINT}")
end

# restart rsyslog after setting routes
system("sudo /etc/init.d/rsyslog restart")

# set static routes (wireless)
wireless_ips.each do |wlip|
  system("sudo ip route del #{wlip} via #{WIFIGW} dev #{WIFIINT}")
  system("sudo ip route add #{wlip} via #{WIFIGW} dev #{WIFIINT}")
end

