echo 'Remove the 70-persistent-net.rules file so when the VM is cloned the interface have the correct name, feels like there should be a better way of doing this but I'm not familiar enough with udev'
rm /etc/udev/rules.d/70-persistent-net.rules

echo 'Set up the interfaces so we can connect to them after clone'
sed '/^HWADDR.*$/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed '/^UUID.*$/d' /etc/sysconfig/network-scripts/ifcfg-eth0
sed '/^ONBOOT.*$/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth0
sed '/^BOOTPROTO.*$/BOOTPROTO=no/' /etc/sysconfig/network-scripts/ifcfg-eth0
echo 'IPADDR=10.1.2.3' >> /etc/sysconfig/network-scripts/ifcfg-eth0

sed '/^HWADDR.*$/d' /etc/sysconfig/network-scripts/ifcfg-eth1
sed '/^UUID.*$/d' /etc/sysconfig/network-scripts/ifcfg-eth1
sed '/^ONBOOT.*$/ONBOOT=yes/' /etc/sysconfig/network-scripts/ifcfg-eth1
sed '/^#PermitRootLogin=yes/PermitRootLogin=yes/' /etc/ssh/sshd_config

echo 'Turn off iptables, not very secure but only until Ansible sets up security later'
service iptables stop

echo 'Shutdown so we can snapshot the basic networking configuration'
shutdown -h 0