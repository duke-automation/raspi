#!/bin/bash

H=$(/bin/hostname -s)
WIREDINT=$(./get-config.rb -I)
LOGDATE=$(date "+%m-%d-%Y_%H:%M:%S")
UPTIMECMD='/usr/bin/uptime'
NOTIFYFILE="/tmp/myip-${WIREDINT}.$$"
HISTORYFILE="ip-history-${WIREDINT}.txt"
RESTARTFILE="ip-restart-${WIREDINT}.txt"
IPFILE="/tmp/myip-${WIREDINT}"
WIFIGW=`/bin/grep 'option routers' /var/lib/dhcp/dhclient.${WIREDINT}.leases | /usr/bin/tail -1 | /usr/bin/awk '{ print $3 }' | /bin/sed -e 's/;//' | sort | uniq`.chomp
IPADDR=$(/sbin/ifconfig ${WIREDINT} | /bin/grep 'inet addr:' | /usr/bin/cut -d: -f2 | /usr/bin/awk '{ print $1 }')
MACADDR=$(/sbin/ifconfig ${WIREDINT} | /bin/grep 'HWaddr' | /usr/bin/awk '{ print $5 }')
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

