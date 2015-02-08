# This is a guide to setting up a local multiple server development environment using VirtualBox CentOS 6.5 and Ansible.

I wrote this as I needed a development environment to test software that required multiple servers.
Initially I set up a base VM and then altered it for each server I needed but quickly found I needed to update each server individually 
when I found I'd missed something in the setup. So I looked into using Ansible and thought I'd publish this in case it's of use to anyone 
else or more likely I accidentally delete these files. This isn't finished yet as I need to test it a few more times.

Begin by downloading the [CentOS 6.5 minimal install](http://isoredirect.centos.org/centos/6.5/isos/x86_64/) iso and [VirtualBox](https://www.virtualbox.org/wiki/Downloads). Follow the VirtualBox install guide for your host.

## Set up a base VirtualBox VM

Once you have VirtualBox installed create a new VM with a HostOnly network on the first network card and NAT on the second.

On the command line of your host PC

    vboxmanage createvm --name "MinimalCentOS" --register --ostype RedHat_64
    vboxmanage modifyvm "MinimalCentOS" --memory 512 --rtcuseutc on --nic1 hostonly --nic2 nat --hostonlyadapter1 vboxnet0

    VBoxManage storagectl MinimalCentOS --name "IDE" --add IDE --controller PIIX4 --portcount 2 --bootable on
    VBoxManage storagectl MinimalCentOS --name "SATA" --add SATA --controller IntelAhci --portcount 1 --bootable on


    VBoxManage storageattach  MinimalCentOS --storagectl IDE --type dvddrive --medium /Volumes/ExternalDrive/Work/downloads/CentOS-6.5-x86_64-minimal.iso --device 1 --port 0
    VBoxManage createhd  --filename MainHd --size 40960

    VBoxManage storageattach  MinimalCentOS --storagectl SATA --type hdd  --medium /Volumes/ExternalDrive/Work/VirtualMachines/VirtualBox\ VMs/MainHD.vdi --mtype normal --device 0 --port 0

    VBoxManage startvm MinimalCentOS

Follow the on screen prompts to install CentOS. 

Again on the command line of the host PC

    VBoxManage controlvm MinimalCentOS poweroff

    VBoxManage snapshot MinimalCentOS take CentOSInstalled

    VBoxManage startvm MinimalCentOS

Login to the new VM using the VirtualBox terminal



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

Or you can download a shell script directly from GitHub and save typing if you have a github account

    ifup eth1
    curl -u <Github user name/> -o setup.sh https://raw.githubusercontent.com/mksbikerider/SetupMultipleServers/master/setupBaseVM/setup.sh
    chmod 700 setup.sh
    ./setup.sh

Back at the host PC Terminal

    VBoxManage snapshot MinimalCentOS take BasicNetworking

    VBoxManage clonevm MinimalCentOS --snapshot BasicNetworking --mode machine --options link --name ansible --register

    VBoxManage startvm ansible --type headless
    
    ssh-keygen -t rsa -C "your_email@example.com"

    scp id_rsa.pub root@10.1.2.3:host_rsa.pub

    ssh root@10.1.2.3

install Ansible using yum (see ansible website)

    yum install epel-release

    yum install ansible

## Now use Ansible to secure and setup the VM
This VM will become the control server that all instructions will be pushed out from it will also become the DHCP 
and DNS server so that we don't have to manually control IP addresses for every new server.

Get this Git Repo

    yum install git

    git clone https://github.com/mksbikerider/SetupMultipleServers.git
    cd SetupMultipleServers/
    ansible-playbook -i newserver firstServer.yaml --ask-pass
    cd ../
    rm -rf SetupMultipleServers

You'd better now add your public key to the authorized keys file or you'll lose access to the server

    cat host_rsa.pub >> /home/ansible/.ssh/authorized_keys

    su ansible

    echo [defaults] >> ~/.ansible.cfg
    echo 'host_key_checking = False' >> ~/.ansible.cfg

    ssh-agent bash
    ssh-add

    git clone https://github.com/mksbikerider/SetupMultipleServers.git
    cd SetupMultipleServers/
    ansible-playbook -i newserver all.yaml

    ansible-playbook -i newserver setStaticIp.yaml

Move this server to 10.1.2.4, when you do this you will lose your ssh connection as you've just changed the ip address.
ssh into ansible@10.1.2.4

    ansible-playbook -i devServers all.yaml


At this point you now have a control server and it's time to start creating the other servers you need.

## Create a managed server

At your host PC terminal 

    VBoxManage clonevm MinimalCentOS --snapshot BasicNetworking --mode machine --options link --name managed1 --register

    VBoxManage startvm slave1 --type headless
    
At your ssh session to the Control server

    ansible-playbook -i newserver newServer.yaml --ask-pass
    ansible-playbook -i newserver setHostName.yaml
    ansible-playbook -i all all.yaml

You should now have a new server configured by Ansible to be secure (limited SSH, IP tables) and use DHCP. You can repeat
the instructions from 'Create a managed server' as many times as you need.