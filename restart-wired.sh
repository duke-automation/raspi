#!/bin/bash

# check eth interface connectivity and reset if not connected

H=$(/bin/hostname -s)
HISTORYFILE="wired_history.txt"
LOGCMD='/usr/bin/logger'
LOGDATE=$(date "+%m-%d-%Y_%H:%M:%S")
DEBUGFILE="/tmp/wired-debug.txt"
MAILDATE=`date "+%m/%d/%Y"`
TRACECMD='/usr/sbin/traceroute -w 1 '
NETSTAT=$(/bin/netstat -nr)
wiredint=$(./get-config.rb -i)
debugRecipients=$(./get-config.rb -d)
processRecipients=$(./get-config.rb -p)
ip_string=$(./get-config.rb -w)

function send_debug() {
  file=$1
  cat ${file} | /usr/bin/mailx -s "Wired Restart Debug: ${H}" ${debugRecipients}
}

echo -e "$(date) debug info\n\n" > ${DEBUGFILE}

ips=($ip_string)
fails=0
for ip in ${ips[@]}
do
  typeset -i retstat; let retstat=0
  ping -W 1 -c 1 ${ip} > /dev/null ; retstat=$?
  if [[ $retstat != 0 ]]; then
    fails=$(( $fails + 1 ))
    echo -e "\ntrace to ip ${ip}:" >> ${DEBUGFILE}
    ${TRACECMD} ${ip} >> ${DEBUGFILE}
  fi
done

if [[ $fails -eq 3 ]]; then
  ${LOGCMD} "${H} event=wired_restart type=bounce_${wiredint}"
  echo "restarting wired on ${H}" | mailx -s "${H} wired restart" ${processRecipients}
  echo -e "\nrouting table:" >> ${DEBUGFILE}
  /bin/netstat -nr >> ${DEBUGFILE}
  send_debug "$DEBUGFILE"
  rm ${DEBUGFILE}
else
  if [[ -f ${DEBUGFILE} ]]; then
    rm ${DEBUGFILE}
  fi
fi
