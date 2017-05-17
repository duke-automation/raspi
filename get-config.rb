#!/usr/bin/env /usr/bin/ruby

require 'yaml'
require 'socket'
require 'optparse'

# default args
options = {
    :host               =>  nil, # -h
    :debug_recipients   =>  nil, # -d
    :process_recipients =>  nil, # -p
    :ip_recipients      =>  nil, # -n
    :ping_sites         =>  nil, # -P
    :http_sites         =>  nil, # -H
    :dns_sites          =>  nil, # -D
    :wired_int          =>  'eth0', # -i
    :wireless_int       =>  'wlan0', # -I
    :wired_ips          =>  nil, # -w
    :wireless_ips       =>  nil  # -W
}

# parse args
optparse = OptionParser.new do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: #{script_name} [options]"
  opts.on("--help","Display this message") do
    puts opts
    exit
  end
  opts.on("-h","--host","Display hostname") do
    options[:host] = true
  end
  opts.on("-d","--debugr","Debug Recipients") do
    options[:debugr] = true
  end
  opts.on("-p","--processr","Process Recipients") do
    options[:processr] = true
  end
  opts.on("-n","--ipr","IP Recipients") do
    options[:ipr] = true
  end
  opts.on("-P","--pingip","Ping sites") do
    options[:pingip] = true
  end
  opts.on("-H","--httpn","HTTP sites") do
    options[:httpn] = true
  end
  opts.on("-D","--dnsn","DNS sites") do
    options[:dnsn] = true
  end
  opts.on("-i","--wiredint","Wired Interface") do
    options[:wiredint] = true
  end
  opts.on("-I","--wirelessint","Wireless Interface") do
    options[:wirelessint] = true
  end
  opts.on("-w","--wiredips","Wired IPs") do
    options[:wiredips] = true
  end
  opts.on("-W","--wirelessips","Wireless IPs") do
    options[:wirelessips] = true
  end
end

# parse options
begin
  optparse.parse!
rescue OptionParser::InvalidArgument, OptionParser::MissingArgument => opterror
 puts $!.to_s
 puts optparse
 exit 1
end

# constants
HOST = Socket.gethostname
CONFIG = YAML.load_file('./configuration.yml')
DEBUGRECIP = CONFIG["#{HOST}"]['recipients']['debug_recipients']
PROCESSRECIP = CONFIG["#{HOST}"]['recipients']['process_recipients']
IPRECIP = CONFIG["#{HOST}"]['recipients']['ip_recipients']
WIREDINT = CONFIG["#{HOST}"]['interfaces']['wired']
WIRELESSINT = CONFIG["#{HOST}"]['interfaces']['wireless']
WIRELESSIPS = CONFIG["#{HOST}"]['hosts']['wireless_ips']
WIREDIPS = CONFIG["#{HOST}"]['hosts']['wired_ips']
PINGSITES = CONFIG["#{HOST}"]['hosts']['ping_sites']
HTTPSITES = CONFIG["#{HOST}"]['hosts']['http_sites']
DNSSITES = CONFIG["#{HOST}"]['hosts']['dns_sites']

puts HOST if options[:host] == true && HOST
puts DEBUGRECIP.join(" ") if options[:debugr] == true && DEBUGRECIP
puts PROCESSRECIP.join(" ") if options[:processr] == true && PROCESSRECIP
puts IPRECIP.join(" ") if options[:ipr] == true && IPRECIP
puts PINGSITES.join(" ") if options[:pingip] == true && PINGSITES
puts HTTPSITES.join(" ") if options[:httpn] == true && HTTPSITES
puts DNSSITES.join(" ") if options[:dnsn] == true && DNSSITES
puts WIREDINT if options[:wiredint] == true && WIREDINT
puts WIRELESSINT if options[:wirelessint] == true && WIRELESSINT
puts WIREDIPS.join(" ") if options[:wiredips] == true && WIREDIPS
puts WIRELESSIPS.join(" ") if options[:wirelessips] == true && WIRELESSIPS

