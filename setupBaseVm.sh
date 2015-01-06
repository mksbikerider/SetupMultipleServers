#!/bin/bash

sed 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed 's/BOOTPROTO=dhcp/BOOTPROTO=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed 's/ONBOOT=no/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth1
echo IPADDR=10.1.2.179 /etc/sysconfig/network-scripts/ifcfg-eth0


iptables -F
iptables -A INPUT  -p tcp --dport 22 -j ACCEPT

iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

iptables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

service iptables save
service iptables restart

vi /etc/ssh/sshd_config
sed 's/#PermitRootLogin yes/PermitRootLogin yes/' /etc/ssh/sshd_config

service network restart
service sshd restart
