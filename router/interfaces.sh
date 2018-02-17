#!/bin/bash

# LOAD VARIABLES
. /opt/backup/config.sh
. /opt/router/config.sh

# configure WAN and LAN bridge 
echo "

# (automatically generated) config of wan interface

auto $WAN_IFACE
iface $WAN_IFACE inet dhcp
iface $WAN_IFACE inet6 auto

# config of LAN
auto $LAN_BRIDGE
iface $LAN_BRIDGE inet static
   bridge_ports $LAN_IFACES
       address $SERVER
       broadcast $LAN_BROADCAST
       netmask $LAN_NETMASK
" > "$INTERFACES_CONFIG_NETWORK" &&

ifconfig $LAN_BRIDGE 0.0.0.0 down &&
/etc/init.d/networking restart
