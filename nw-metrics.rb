#!/usr/bin/env /usr/bin/ruby

require 'resolv'
require 'socket'
require 'pp'
require 'optparse'
require 'timeout'
require 'syslog/logger'

# static vars
host = Socket.gethostname

# default options
options = {
    :ping_count    =>  10,
    :dns_count     =>  5,
    :verbose       =>  false,
    :timewait      =>  30,
    :ping_host     =>  nil,
    :dns_resolver  =>  '8.8.8.8', # default to Google
    :dns_lookup    =>  nil,
    :ghost         =>  nil,
    :gport         =>  2003,
    :timeout       =>  55,
    :fping_cmd     =>  '/usr/bin/fping',
    :ping          =>  true,
    :dns           =>  true
}

optparse = OptionParser.new do |opts|
  script_name = File.basename($0)
  opts.banner = "Usage: #{script_name} [options]"
  opts.on("-h","--help","Display this message") do
    puts opts
    exit
  end
  opts.on("-v","--verbose","Detailed Output") do
    options[:verbose] = true
  end
  opts.on("-t","--timewait TIMEWAIT",Integer,"Wait Time (s)") do |timewait|
    options[:timewait] = timewait
  end
  opts.on("-c","--ping-count PINGCOUNT",Integer,"# of Pings") do |ping_count|
    options[:ping_count] = ping_count
  end
  opts.on("-d","--dns-count DNSCOUNT",Integer,"# of Lookups") do |dns_count|
    options[:dns_count] = dns_count
  end
  opts.on("-h","--ping-host PINGHOST",String,"Host to Ping") do |ping_host|
    options[:ping_host] = ping_host
  end
  opts.on("-r","--dns-resolver DNSRESOLVER",String,"Name Server") do |dns_resolver|
    options[:dns_resolver] = dns_resolver
  end
  opts.on("-l","--dns-lookup DNSLOOKUP",String,"DNS Lookup") do |dns_lookup|
    options[:dns_lookup] = dns_lookup
  end
  opts.on("-g","--ghost GRAPHITEHOST",String,"Graphite Host") do |ghost|
    options[:ghost] = ghost
  end
  opts.on("-p","--gport GRAPHITEPORT",Integer,"GRAPHITE Port") do |gport|
    options[:gport] = gport
  end
  opts.on("-f","--fping FPING",String,"Fping Command") do |fping|
    options[:fping] = fping
  end
  opts.on("-P","--ping PING",String,"Run Ping Test?") do |ping|
    options[:ping] = ping
  end
  opts.on("-D","--dns DNS",String,"Run DNS Test?") do |dns|
    options[:dns] = dns
  end
end

# parse options / set variables
begin
  optparse.parse!

 # mandatory = [:ping_host, :dns_lookup]
 mandatory = [:ping_host]
 missing = mandatory.select{ |param| options[param].nil? }
 if not missing.empty?
   puts "Missing options: #{missing.join(', ')}"
   puts optparse
   exit 1
 end
rescue OptionParser::InvalidArgument, OptionParser::MissingArgument => opterror
 puts $!.to_s
 puts optparse
 exit 1
end

# logs
# errors
$stderr.reopen '/var/tmp/nwmetrics-error.log', 'a'
# flush
$stderr.sync = true
# log stdout to resend to graphite
if options[:ghost] == true
  # output
  $stdout.reopen '/var/tmp/nwmetrics-out.log', 'a'
  # flush
  $stdout.sync = true
end

# Graphite Metric Paths
host_rec = host.sub('.','-')
resolver_rec = options[:dns_resolver].gsub('.', '-')
ping_rec = options[:ping_host].gsub('.','-')
# network.latency.fromhost.tohost
nwmetric = "network.latency.#{host_rec}.#{ping_rec}"
# dns.latency.fromhost.toresolver
dnsmetric = "dns.latency.#{host_rec}.#{resolver_rec}"

# main
log = Syslog::Logger.new 'nwmetrics'
loop do
  # connect to Graphite
  if options[:ghost] == true
    s = TCPSocket.open(options[:ghost], options[:gport])
  end
  ## PING
  p = IO.popen("#{options[:fping_cmd]} -B 1 -r0 -O 0 -q -p 1000 -c #{options[:ping_count]} #{options[:ping_host]} 2>&1")
  f = p.readlines
  p.close
  @D = Time.now.to_i
  res = f.to_s.split(" ")
  loss = res[4].match(/\/\d+%/).to_s
  loss = loss.gsub('/','').gsub('%','')
  min, avg, max = res[7].split('/')
  max = max.gsub('\n"]','')
  # fix 'signed integer overflow' or 'time alignmnent' fping issue
  # e.g.
  # network.latency.mojo.www-google-com.loss 40 1443669791
  # network.latency.mojo.www-google-com.min -1.1e+03 1443669791
  # network.latency.mojo.www-google-com.avg -1.6e+02 1443669791
  # network.latency.mojo.www-google-com.max 39.1 1443669791
  # any negative values...?
  omin = min
  omax = max
  oavg = avg
  min = 0 if min.to_i < 0
  max = 0 if max.to_i < 0
  avg = 0 if avg.to_i < 0
  if min.to_i==0 or avg.to_i==0 or max.to_i==0
    $stderr.puts "#{@D}: fping negative values encountered min: #{omin} avg: #{oavg} max: #{omax}"
    #next
  end
  # write to graphite
  if options[:ghost] == true
    s.write("#{nwmetric}.loss #{loss} #{@D}\n")
    s.write("#{nwmetric}.min #{min} #{@D}\n")
    s.write("#{nwmetric}.avg #{avg} #{@D}\n")
    s.write("#{nwmetric}.max #{max} #{@D}\n")
    s.write("#{nwmetric}.count #{options[:ping_count]} #{@D}\n")
    # log results for recovery
    puts "#{nwmetric}.loss #{loss} #{@D}\n"
    puts "#{nwmetric}.min #{min} #{@D}\n"
    puts "#{nwmetric}.avg #{avg} #{@D}\n"
    puts "#{nwmetric}.max #{max} #{@D}\n"
    puts "#{nwmetric}.count #{options[:ping_count]} #{@D}\n"
  end
  # log to syslog
  log.info "#{ping_rec}_ping=#{avg} #{ping_rec}_ping_min=#{min} #{ping_rec}_ping_max=#{max} #{ping_rec}_ping_loss=#{loss} #{ping_rec}_ping_count=#{options[:ping_count]}"
  ## DNS
  if options[:dns] == 'true'
    count = 0
    rttotal = 0
    rtarr = Array.new
    if options[:ghost] == true
      s.flush
    end
    dhosts = Array.new
    dhosts = ['duke.edu','www.google.com']
  #  while count < options[:dns_count]
    dhosts.each do |site|
      st = Time.now
      dnsobj = Resolv::DNS.new(:nameserver => [options[:dns_resolver]])
      # res = @dnsobj.getresources 'duke.edu', Resolv::DNS::Resource::IN::A
      # lh = options[:dns_lookup].to_s.strip
      # dnsobj.getaddress(lh)
      # dnsobj.getresources "#{options[:dns_lookup]}", Resolv::DNS::Resource::IN::A
      dnsobj.getaddress(site)
      # pp res
      et = Time.now
      # rt = ((et - st)*1000).round(0)
      rt = ((et - st)*1000).to_i
      rttotal = rttotal + rt
      rtarr << rt
      dnsobj.close
      count+=1
    end
  # rtavg = rttotal.to_f / options[:dns_count]
    rtavg = rttotal.to_f / dhosts.count
    rtmin = rtarr.min
    rtmax = rtarr.max
    if options[:ghost] == true
      s.write("#{dnsmetric}.min #{rtmin} #{@D}\n")
      s.write("#{dnsmetric}.avg #{rtavg} #{@D}\n")
      s.write("#{dnsmetric}.max #{rtmax} #{@D}\n")
      s.write("#{dnsmetric}.count #{options[:dns_count]} #{@D}\n")
      # logging
      puts "#{dnsmetric}.min #{rtmin} #{@D}"
      puts "#{dnsmetric}.avg #{rtavg} #{@D}"
      puts "#{dnsmetric}.max #{rtmax} #{@D}"
      puts "#{dnsmetric}.count #{options[:dns_count]} #{@D}"
    # DEBUG puts "#{rttotal}/#{options[:dns_count]} #{rtmin} #{rtavg} #{rtmax}"
    end
    rtarr.clear
  end
  # buffer between runs
  sleep options[:timewait]
  # disconnect from Graphite
  if options[:ghost] == true
    s.close
  end
end

