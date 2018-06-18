#!/bin/bash
IPT="/sbin/iptables"
SERVPORTS="80,7022"
SSHPORT="41296,7022,22"

# Server IP
SERVER_IP="$(ip addr show eth0 | grep 'inet ' | cut -f2 | awk '{ print $2}')"
echo  "Server IP: '$SERVER_IP'"
# Your DNS servers you use: cat /etc/resolv.conf
DNS_SERVER="8.8.4.4 8.8.8.8"
# Allow connections to this package servers
PACKAGE_SERVER="ftp.us.debian.org security.debian.org" 

echo "flush iptable rules" 
$IPT -F 
$IPT -X 
$IPT -t nat -F 
$IPT -t nat -X 
$IPT -t mangle -F 
$IPT -t mangle -X 
echo "Set default policy to 'DROP'" 
$IPT -P INPUT DROP 
$IPT -P FORWARD DROP 
$IPT -P OUTPUT DROP

## This should be one of the first rules. so dns lookups are 
## already allowed for your other rules
#for ip in $DNS_SERVER do
	echo "Allowing DNS lookups (tcp, udp port 53) to server '$ip'"
#	$IPT -A OUTPUT -p udp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
#	$IPT -A INPUT -p udp -s $ip --sport 53 -m state --state ESTABLISHED -j ACCEPT
#	$IPT -A OUTPUT -p tcp -d $ip --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
#	$IPT -A INPUT -p tcp -s $ip --sport 53 -m state --state ESTABLISHED -j ACCEPT 	
	$IPT -A OUTPUT -p udp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
	$IPT -A OUTPUT -p tcp --dport 53 -m state --state NEW,ESTABLISHED -j ACCEPT
	$IPT -A INPUT -p tcp --sport 53 -m state --state ESTABLISHED -j ACCEPT 
#done 
echo "allow all and everything on localhost" 
$IPT -A INPUT -i lo -j ACCEPT 
$IPT -A OUTPUT -o lo -j ACCEPT 
#for ip in $PACKAGE_SERVER do
#	echo "Allow connection to '$ip' on port 21"
#	$IPT -A OUTPUT -p tcp -d "$ip" --dport 21 -m state --state NEW,ESTABLISHED -j ACCEPT
#	$IPT -A INPUT -p tcp -s "$ip" --sport 21 -m state --state ESTABLISHED -j ACCEPT
#	echo "Allow connection to '$ip' on port 80"
#	$IPT -A OUTPUT -p tcp -d "$ip" --dport 80 -m state --state NEW,ESTABLISHED -j ACCEPT
#	$IPT -A INPUT -p tcp -s "$ip" --sport 80 -m state --state ESTABLISHED -j ACCEPT
#	echo "Allow connection to '$ip' on port 443"
#	$IPT -A OUTPUT -p tcp -d "$ip" --dport 443 -m state --state NEW,ESTABLISHED -j ACCEPT
#	$IPT -A INPUT -p tcp -s "$ip" --sport 443 -m state --state ESTABLISHED -j ACCEPT 

	echo "Allow connection to '$ip' on port 21"
	$IPT -A OUTPUT -p tcp --dport 21 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	$IPT -A INPUT -p tcp --sport 21 -m state --state RELATED,ESTABLISHED -j ACCEPT
	echo "Allow connection to '$ip' on port 80"
	$IPT -A OUTPUT -p tcp --dport 80 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	$IPT -A INPUT -p tcp --sport 80 -m state --state RELATED,ESTABLISHED -j ACCEPT
	echo "Allow connection to '$ip' on port 443"
	$IPT -A OUTPUT -p tcp --dport 443 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
	$IPT -A INPUT -p tcp --sport 443 -m state --state RELATED,ESTABLISHED -j ACCEPT 

#done
#######################################################################################################
## Global iptable rules. Not IP specific
echo "Allowing new and established incoming connections to $SERVPORTS ports" 
$IPT -A INPUT -p tcp -m multiport --dports $SERVPORTS -m state --state NEW,ESTABLISHED -j ACCEPT 
$IPT -A OUTPUT -p tcp -m multiport --sports $SERVPORTS -m state --state ESTABLISHED -j ACCEPT 
echo "Allow all outgoing connections to port $SSHPORT" 
$IPT -A OUTPUT -p tcp -m multiport --dports $SSHPORT -m state --state NEW,ESTABLISHED -j ACCEPT 
$IPT -A INPUT -p tcp -m multiport --sports $SSHPORT -m state --state ESTABLISHED -j ACCEPT 
echo "Allow all outgoing connections to email" 
$IPT -A OUTPUT -p tcp -m multiport --dports 25,465,587 -m state --state NEW,ESTABLISHED -j ACCEPT 
$IPT -A INPUT -p tcp -m multiport --sport 25,465,587 -m state --state ESTABLISHED -j ACCEPT 


echo "Allow outgoing icmp connections (pings,...)" 
$IPT -A OUTPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
$IPT -A INPUT -p icmp -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT 
echo "Allow outgoing connections to port 123 (ntp syncs)" 
$IPT -A OUTPUT -p udp --dport 123 -m state --state NEW,ESTABLISHED -j ACCEPT 
$IPT -A INPUT -p udp --sport 123 -m state --state ESTABLISHED -j ACCEPT
# Log before dropping
$IPT -A INPUT -j LOG -m limit --limit 12/min --log-level 4 --log-prefix 'IP INPUT drop: ' 
$IPT -A INPUT -j DROP 
$IPT -A OUTPUT -j LOG -m limit --limit 12/min --log-level 4 --log-prefix 'IP OUTPUT drop: ' 
$IPT -A OUTPUT -j DROP

exit 0
