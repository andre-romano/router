#!/bin/bash

# load variables
. /opt/backup/config.sh

PWD=$(pwd)

start_firewall(){
   "$IPT_SERVICE" defaults 
   update-rc.d `basename "$IPT_SERVICE"` enable 
   "$IPT_SERVICE" start
   iptables -n nat -L
   iptables -n filter -L
}

config_dhcp(){
   /opt/router/dhcp.sh
}

cd / &&
tar -xzvf "$BACKUP" &&
start_firewall &&
config_dhcp &&
cd "$PWD"

