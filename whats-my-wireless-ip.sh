#!/bin/bash

H=$(/bin/hostname -s)
WIFIINT=$(./get-config.rb -I)
LOGDATE=$(date "+%m-%d-%Y_%H:%M:%S")
UPTIMECMD='/usr/bin/uptime'
NOTIFYFILE="/tmp/myip-${WIFIINT}.$$"
HISTORYFILE="ip-history-${WIFIINT}.txt"
RESTARTFILE="ip-restart-${WIFIINT}.txt"
IPFILE="/tmp/myip-${WIFIINT}"
WIFIGW=`/bin/grep 'option routers' /var/lib/dhcp/dhclient.${WIFIINT}.leases | /usr/bin/tail -1 | /usr/bin/awk '{ print $3 }' | /bin/sed -e 's/;//' | sort | uniq`.chomp
IPADDR=$(/sbin/ifconfig ${WIFIINT} | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1 }')
MACADDR=$(/sbin/ifconfig ${WIFIINT} | /bin/grep 'HWaddr' | /usr/bin/awk '{ print $5 }')
ipRecipients=$(./get-config.rb -n)

function send_email() {
  file=$1
  /bin/cat ${file} | /usr/bin/mailx -s "Wireless IP Information: ${H}" ${ipRecipients}
}

if [[ -f ${IPFILE} ]]; then
  OLDIP=$(/bin/cat ${IPFILE})
  if [[ "$IPADDR" == "$OLDIP" ]]; then
    echo "match old=$IPADDR new=$OLDIP"
  else
    # send notification
    echo "Host: $H" > ${NOTIFYFILE}
    echo "Wireless IP: $IPADDR" >> ${NOTIFYFILE}
    echo "Wireless MAC: $MACADDR" >> ${NOTIFYFILE}
    echo "Wireless GW: $WIFIGW" >> ${NOTIFYFILE}
    echo >> ${NOTIFYFILE}
    ${UPTIMECMD} >> ${NOTIFYFILE}
    echo >> ${NOTIFYFILE}
    echo "IP History:" >> ${NOTIFYFILE}
    /usr/bin/tail -10 ${HISTORYFILE} >> ${NOTIFYFILE}
    echo >> ${NOTIFYFILE}
    echo "Restart History:" >> ${NOTIFYFILE}
    /usr/bin/tail -10 ${RESTARTFILE} >> ${NOTIFYFILE}
    send_email "$NOTIFYFILE"
    # write new ip
    echo "${LOGDATE} $IPADDR" >> ${HISTORYFILE}
    echo $IPADDR > ${IPFILE}
    /bin/rm ${NOTIFYFILE}
  fi
else
  # send notification
  echo "Host: $H" > ${NOTIFYFILE}
  echo "Wireless IP: $IPADDR" >> ${NOTIFYFILE}
  echo "Wireless MAC: $MACADDR" >> ${NOTIFYFILE}
  echo "Wireless GW: $WIFIGW" >> ${NOTIFYFILE}
  echo >> ${NOTIFYFILE}
  ${UPTIMECMD} >> ${NOTIFYFILE}
  echo >> ${NOTIFYFILE}
  echo "IP History:" >> ${NOTIFYFILE}
  /usr/bin/tail -10 ${HISTORYFILE} >> ${NOTIFYFILE}
  echo >> ${NOTIFYFILE}
  echo "Restart History:" >> ${NOTIFYFILE}
  /usr/bin/tail -10 ${RESTARTFILE} >> ${NOTIFYFILE}
  send_email "$NOTIFYFILE"
  # write new ip
  echo "${LOGDATE} $IPADDR" >> ${HISTORYFILE}
  echo $IPADDR > ${IPFILE}
  /bin/rm ${NOTIFYFILE}
fi

