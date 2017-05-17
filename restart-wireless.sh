#!/bin/bash

# check wlan interface connectivity and reset if not connected

H=$(/bin/hostname -s)
HISTORYFILE="wireless_history.txt"
LOGCMD='/usr/bin/logger'
LOGDATE=$(date "+%m-%d-%Y_%H:%M:%S")
DEBUGFILE="/tmp/wireless-debug.txt"
MAILDATE=`date "+%m/%d/%Y"`
TRACECMD='/usr/sbin/traceroute -w 1 '
IWCMD='/sbin/iwconfig'
NETSTAT=$(/bin/netstat -nr)
CAPFILE='/tmp/radio.pcap'
wirelessint=$(./get-config.rb -I)
debugRecipients=$(./get-config.rb -d)
processRecipients=$(./get-config.rb -p)
ip_string=$(./get-config.rb -W)
WIFIGW=$(/sbin/ip route show | grep ${wirelessint} | grep default |  grep -v metric | awk '{ print $3 }')

function send_debug() {
  file=$1
  cat ${file} | /usr/bin/mailx -s "Wireless Restart Debug: ${H}" ${debugRecipients}
}

# start debug file
echo -e "$(date) debug info\n\n" > ${DEBUGFILE}
${IWCMD} ${wirelessint} >> ${DEBUGFILE}

# wifi running?
WIFIOK=$(ifconfig ${wirelessint} |grep RUNNING)

# set routes to insure test accuracy
./set-routes.rb

ips=($ip_string)
# iterate through IPs and trigger if all fail ping
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

# if all fail capture debugging info and reset interface
if [[ $fails -eq ${#ips[@]} || ! $WIFIOK ]]; then
  # log to syslog
  ${LOGCMD} "${H} event=wifi_restart type=bounce_${wirelessint}"
  # record history
  echo "${LOGDATE} event=wifi_restart type=bounce_${wirelessint}" >> ${HISTORYFILE}
  # arping to check layer 2 connectivity to gateway
  echo -e "\narping to wireless gateway (${WIFIGW}):" >> ${DEBUGFILE}
  sudo arping -c 3 ${WIFIGW} >> ${DEBUGFILE}
  # show routing table
  echo -e "\nrouting table:" >> ${DEBUGFILE}
  /bin/netstat -nr >> ${DEBUGFILE}
  # show wpa status (if applicable)
  echo -e "\nwpa_cli status (verbose):" >> ${DEBUGFILE}
  wpa_cli status verbose >> ${DEBUGFILE}
  # check radio connectivity to AP
  sudo iwconfig ${wirelessint} mode monitor 
  sudo echo > ${CAPFILE}
  timeout 10.0s sudo tcpdump -y ieee802_11_radio -i wlan0 -c 200 -w ${CAPFILE}
  lines=$(timeout 10.0s sudo tcpdump -r ${CAPFILE} | wc -l)
  if [[ $lines -gt 100 ]]; then
    echo -e "\nadapter connected to access point" >> ${DEBUGFILE}
  else
    echo -e "\nadapter not connected to access point" >> ${DEBUGFILE}
  fi
  # reset interface
  sudo iwconfig wlan0 mode managed 
  sudo ifdown wlan0
  sleep 2
  sudo ifup wlan0
  sleep 2
  # reset routes after ifup
  ./set-routes.rb
  send_debug "$DEBUGFILE"
  rm ${DEBUGFILE}
else
  if [[ -f ${DEBUGFILE} ]]; then
    rm ${DEBUGFILE}
  fi
fi
