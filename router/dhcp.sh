#!/bin/bash

# load variables
. /opt/backup/config.sh
. /opt/router/config.sh

config_lan_br(){
   /opt/router/interfaces.sh
}

config_reserved_hw(){
  NAME=$1
  HW=$2
  IP=$3
  echo "
  host $NAME {
    hardware ethernet $HW;
    fixed-address $IP;
  }
  " >> "$DHCP_CONFIG"
}

config_dhcp(){

  # config reserved IPs
  while IFS='' read -r line; do
        # skip comments and empty lines
        if echo $line | grep '^[ \t]*\#' -q  || \
           echo $line | grep '^[ \t\r\n]*$' -q
        then
           continue;
        fi
 
        NAME=$(echo $line | cut -d' ' -f1)
        HW=$(echo $line | cut -d' ' -f2)
        IP=$(echo $line | cut -d' ' -f3)
        if [ -n "$NAME" ] && [ -n "$HW" ] && [ -n "$IP" ] 
        then
           config_reserved_hw "$NAME" "$HW" "$IP"
        fi
  done < "$DHCP_RESERVED_FILE"

  # configure DHCP server
  sed -i -e "s/^[ \t]*option domain-name .*/option domain-name \"$DOMAIN_NAME\";/g" "$DHCP_CONFIG"
  sed -i -e "s/^[ \t]*option domain-name-servers .*/option domain-name-servers $SERVER;/g" "$DHCP_CONFIG" 
  sed -i -e "s/^[ \t]*subnet .*/subnet $LAN_NETWORK netmask $LAN_NETMASK \{/g" "$DHCP_CONFIG"
  sed -i -e "s/^[ \t]*range .*/range $DHCP_RANGE_BEGIN $DHCP_RANGE_END;/g" "$DHCP_CONFIG" 
  sed -i -e "s/^[ \t]*option routers .*/option routers $SERVER;/g" "$DHCP_CONFIG"
}

config_lan_br &&
config_dhcp &&
systemctl restart isc-dhcp-server

