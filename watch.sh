#!/bin/bash

H=$(/bin/hostname -s)
HISTORYFILE="nwmetrics_history.txt"
LOGCMD='/usr/bin/logger'
LOGDATE=$(date "+%m-%d-%Y_%H:%M:%S")
MAILDATE=`date "+%m/%d/%Y"`
processRecipients=$(./get-config.rb -p)
ping_string=$(./get-config.rb -P)
dns_string=$(./get-config.rb -D)

# toggle between these two or run both by setting ping_sites and/or dns_sites
# in configuration.yml
ping_sites=($ping_string)
dns_sites=($dns_string)

function send_notify() {
  /usr/bin/mailx -s "Wired Restart Debug: ${H}" ${debugRecipients}
}

# ping only (-D false)
if [ -n ${ping_sites} ]; then
  for h in ${ping_sites[@]}
  do
    typeset -i nwpid ; let nwpid=0
    nwpid=$(/bin/ps auxwww|/bin/grep nw-metrics|/bin/grep ${h}|/bin/grep -v /bin/grep|/usr/bin/awk '{ print $2}')
    if [ $nwpid -gt 0 ]; then
      echo $nwpid
    else
      /usr/bin/nohup ./nw-metrics.rb -h ${h} -D false &
      echo "nwmetrics ${h} stopped, restarting..." | /usr/bin/mailx -s "nwmetrics restart $(/bin/hostname -s)" ${processRecipients}
      echo $!
    fi
  done
fi

# ping & DNS (-D true)
if [ -n ${dns_sites} ]; then
  for h in ${dns_sites[@]}
  do
    typeset -i nwpid ; let nwpid=0
    nwpid=$(/bin/ps auxwww|/bin/grep nw-metrics|/bin/grep ${h}|/bin/grep -v /bin/grep|/usr/bin/awk '{ print $2}')
    if [ $nwpid -gt 0 ]; then
      echo $nwpid
    else
      /usr/bin/nohup ./nw-metrics.rb -h ${h} -D true &
      echo "nwmetrics ${h} stopped, restarting..." | /usr/bin/mailx -s "nwmetrics restart $(/bin/hostname -s)" ${processRecipients}
      echo $!
    fi
  done
fi
