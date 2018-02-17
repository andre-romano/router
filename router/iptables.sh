#!/bin/bash

IPT=/sbin/iptables
IPT6=/sbin/ip6tables

# load global config variables
. /opt/backup/config.sh
. /opt/router/config.sh

lan_forwarding(){
   PROTOCOL=$1
   IN_PORT=$2
   OUT_IP=$3
   OUT_PORT=$4
   
   # redirect the incoming pkt to internal server
   $IPT -t nat -A PREROUTING ! -i $WAN_IFACE -s $LOCAL_LAN -p $PROTOCOL --dport $IN_PORT -j DNAT --to $OUT_IP:$OUT_PORT
}

wan_forwarding(){
   PROTOCOL=$1
   IN_PORT=$2
   OUT_IP=$3
   OUT_PORT=$4
   
   # redirect the incoming pkt to internal server
   $IPT -t nat -A PREROUTING -i $WAN_IFACE -p $PROTOCOL --dport $IN_PORT -j DNAT --to $OUT_IP:$OUT_PORT
   # allow forwarded packet
   $IPT -A VIRTUAL_SERVER -i $WAN_IFACE --destination $OUT_IP -p $PROTOCOL --dport $OUT_PORT -j ACCEPT
}


# load required modules
echo 1 > /proc/sys/net/ipv4/ip_forward  # allow IP forwarding
modprobe ip_tables
modprobe ip_conntrack
modprobe iptable_filter
modprobe iptable_mangle
modprobe iptable_nat
modprobe ipt_LOG
modprobe ipt_limit
modprobe ipt_state
modprobe ipt_REDIRECT
modprobe ipt_owner
modprobe ipt_REJECT
modprobe ipt_MASQUERADE
modprobe ip_conntrack_ftp
modprobe ip_nat_ftp

# define policies

  # IPv4
  $IPT -t nat -P PREROUTING ACCEPT  
  $IPT -t nat -P POSTROUTING ACCEPT  
  $IPT -P INPUT DROP
  $IPT -P FORWARD DROP
  $IPT -P OUTPUT ACCEPT

  # IPv6
  $IPT6 -P INPUT DROP
  $IPT6 -P FORWARD DROP
  $IPT6 -P OUTPUT ACCEPT

# clear iptables
$IPT -F
$IPT -X
$IPT -t raw -F
$IPT -t raw -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X

# create custom chains
$IPT -N SAFETY
$IPT -N VIRTUAL_SERVER

# establish order of custom chain passing
$IPT -A INPUT -j SAFETY
$IPT -A FORWARD -j SAFETY
$IPT -A FORWARD -j VIRTUAL_SERVER


#####    SAFETY FIRST    #####

   ##  TCP ATTACKS  ##

      # wierd SYN pkts
      $IPT -A SAFETY -p tcp ! --syn -m state --state NEW -j DROP

      # XMAS pkts
      $IPT -A SAFETY -p tcp --tcp-flags ALL ALL -j DROP

      # NULL pkts
      $IPT -A SAFETY -p tcp --tcp-flags ALL NONE -j DROP

   # incoming fragments (Linux Panics with this!) 
   $IPT -A SAFETY -f -j DROP

   # spoofed localhost  
   $IPT -A SAFETY ! -i lo -s 127.0.0.0/8 -j DROP

   # spoofed local LAN
   $IPT -A SAFETY -i $WAN_IFACE -s $LOCAL_LAN -j DROP

#####      ALLOW      #####

  # allow localhost comms (this router RULESSSS....)
  $IPT -I INPUT -i lo -j ACCEPT
  $IPT -I FORWARD -i lo -j ACCEPT

  # allow connections ESTABLISHED or RELATED
  $IPT -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
  $IPT -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT

  # allow LAN hosts to communicate with each other and with the Internet
  # (the internet comms is restricted, some ports will be blocked ! )
  #$IPT -A FORWARD ! -i $WAN_IFACE -o $WAN_IFACE -p tcp -m multiport --dports $FORWARD_DENY_TCP -j REJECT
  #$IPT -A FORWARD ! -i $WAN_IFACE -o $WAN_IFACE -p udp -m multiport --dports $FORWARD_DENY_UDP -j REJECT
  $IPT -A FORWARD ! -i $WAN_IFACE -j ACCEPT

  # allow SERVER
  $IPT -A INPUT -s $LAN -p tcp -m multiport --dports $SERVICE_TCP -j ACCEPT
  $IPT -A INPUT -s $LAN -p udp -m multiport --dports $SERVICE_UDP -j ACCEPT
  $IPT -A INPUT -s $LAN -m icmp -p icmp --icmp-type any -j ACCEPT



#####     ROUTING     #####

  ###   NAT implementation   ###

    # redirect local pkt to the required router service

      # force dns to go throught this router     
      lan_forwarding udp 53 8.8.8.8 53 
      #lan_forwarding udp 53 $SERVER 53 
      #lan_forwarding tcp 53 $SERVER 53
 
      # force HTTP through squid 
      #lan_forwarding tcp 80 $SERVER 3127  

    # allow WAN access to services (Port Forwarding / Virtual Servers)
    # (we will parse a config file to allow more flexibility to the user)
    while IFS='' read -r line; do
       # skip comments and empty lines
       if echo $line | grep '^[ \t]*\#' -q  || \
          echo $line | grep '^[ \t\r\n]*$' -q
       then 
          continue; 
       fi

       PROTOCOL=$(echo $line | cut -d' ' -f1)
       IN_PORT=$(echo $line | cut -d' ' -f2)
       OUT_IP=$(echo $line | cut -d' ' -f3)
       OUT_PORT=$(echo $line | cut -d' ' -f4)
       if ( [ "$PROTOCOL" == udp ] || [ "$PROTOCOL" == tcp ] ) && \
          ( [ "$IN_PORT" -ge 1 ] && [ "$IN_PORT" -lt 65535 ] ) && \
          ( [ "$OUT_PORT" -ge 1 ] && [ "$OUT_PORT" -lt 65535 ] ) && \
          ( [ -n "$OUT_IP" ] )
       then
          wan_forwarding "$PROTOCOL" "$IN_PORT" "$OUT_IP" "$OUT_PORT"        
       fi
    done < "$VIRTUAL_SERVER_FILE"

    # allow masquerading for WAN interface
    $IPT -t nat -A POSTROUTING -o $WAN_IFACE -j MASQUERADE   



