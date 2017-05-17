
## Introduction

Scripts for monitoring/trending wireless connectivity using Raspberry PIs.

## Features
* Record wireless stats to Splunk (via syslog)
* Monitor wireless connectivity and reset wireless interface when needed
* Record wireless interface reset events to Splunk (via syslog)
* Record ping response time and DNS lookup times to Splunk (via syslog)
* Central configuration (configuration.yml) with per host override
* (optional) Notification for network initialization and changes in IPs
* (future) HTTP response time and speedtest metrics using Selenium

## Server/Network
* Raspberry PI 2/3 (Raspbian OS)
* Syslog server with Splunk forwarder
* Wired and wireless connectivity
* (optional) 5ghz Wireless USB Adapter

## Setup / Configuration
* Create user 'raspi' and create directory '/home/raspi/wireless-test'
* Copy files from this repo into the '/home/raspi/wireless-test' directory
* Configure preferences in 'configuration.yml'
  * wired and wireless interfaces
  * wireless_ips
  * wired_ips
  * ping_sites 
  * dns_sites
  * (optional) email recipients
* Configure rsyslog to forward messages to your Splunk forwarding server
* Setup user 'raspi' crontab using entries in the 'crontab.txt' file in repo
* Create Splunk dashboard referencing 'splunk-dashboard.xml' file in repo

## Operation
* Static routes are setup for wired and wireless IPs (set-routes.rb)
* Pings sent to routed IPs across wired and wireless interfaces to test connectivity (restart-wired.sh restart-wireless.sh)
* Continual capturing of wireless interface metrics (iwconfig-stats.pl wireless-stats.pl)
* Continual capturing of ping response time and dns lookup time metrics

### License

[MIT License](https://github.com/duke-automation/raspi/blob/master/LICENSE)
