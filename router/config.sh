#!/bin/bash

# load auxiliary functions
. /opt/router/.functions.sh

 #######################
 ####               ####
 ####   INTERFACES  ####
 ####               ####
 #######################

BRIDGES=$(brctl show | tail -n +2)
IFACES=$(ip link list | sed -n 'p;n' | grep -v lo | cut -d':' -f2 | xargs)

WAN_IFACE=enp0s3
LAN_BRIDGE='lan-br'
LAN_IFACES=$(echo $IFACES | sed -e "s/$LAN_BRIDGE//g" -e "s/$WAN_IFACE//g" | xargs)

 #####################
 ####             ####
 ####   NETWORK   ####
 ####             ####
 #####################

DOMAIN_NAME='home.lan'
LOCAL_LAN=192.168.56.0/24

LAN_NETWORK=$(echo $LOCAL_LAN | cut -d'/' -f1)
LAN_NETMASK=$(cdr2mask $(echo $LOCAL_LAN | cut -d'/' -f2))

# this router
SERVER=192.168.56.1        
DHCP_RANGE_BEGIN=192.168.56.2
DHCP_RANGE_END=192.168.56.254
LAN_BROADCAST=192.168.56.255


 ######################
 ####              ####
 ####   FIREWALL   ####
 ####              ####
 ######################

# this is the list of ports the router will NOT allow direct 
# communication with the Internet ( WAN )
FORWARD_DENY_TCP='53,63:64,80,443'
FORWARD_DENY_UDP='53,63:64'

# this lists all the services the router provides
SERVICE_TCP='22,53,63:64,80,443,3127:3129'
SERVICE_UDP='53,63:64'

# this is all the possible LAN addrs
LAN="192.168.0.0/16,172.16.0.0/12,10.0.0.0/8"

