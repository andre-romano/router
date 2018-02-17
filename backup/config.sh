#!/bin/bash

BACKUP="/opt/backup/backup.tar.gz"

VIRTUAL_SERVER_FILE='/opt/router/virtual_servers.conf'
DHCP_IFACE_CONFIG='/etc/default/isc-dhcp-server'

IPT_SERVICE="/etc/init.d/iptables"

DHCP_CONFIG='/etc/dhcp/dhcpd.conf'
DHCP_RESERVED_FILE='/opt/router/dhcp_reserved.conf'

INTERFACES_CONFIG_NETWORK='/etc/network/interfaces.d/ifaces'
INTERFACES_CONFIG='/etc/network/interfaces /etc/network/interfaces.d/'

BACKUP_FILES="/opt/ /etc/modules $DHCP_IFACE_CONFIG $DHCP_CONFIG $INTERFACES_CONFIG $IPT_SERVICE"
