This is a tutorial to setup a local multiple server development environment using VirtualBox CentOS 6.5 and Ansible.

Begin by downloading the CentOS minimal install iso and VirtualBox. Follow the VirtualBox install guide for your host.

Once you have VirtualBox installed create a new VM with a HostOnly network on the first network card and NAT on the second.

vboxmanage createvm --name "MinimalCentOS" --register --ostype RedHat_64
vboxmanage modifyvm "MinimalCentOS" --memory 512 --rtcuseutc on --nic1 hostonly --nic2 nat --hostonlyadapter1 vboxnet0

VBoxManage storagectl MinimalCentOS --name "IDE" --add IDE --controller PIIX4 --portcount 2 --bootable on
VBoxManage storagectl MinimalCentOS --name "SATA" --add SATA --controller IntelAhci --portcount 1 --bootable on


VBoxManage storageattach  MinimalCentOS --storagectl IDE --type dvddrive --medium /Volumes/ExternalDrive/Work/downloads/CentOS-6.5-x86_64-minimal.iso --device 1 --port 0
VBoxManage createhd  --filename MainHd --size 40960

VBoxManage storageattach  MinimalCentOS --storagectl SATA --type hdd  --medium /Volumes/ExternalDrive/Work/VirtualMachines/VirtualBox\ VMs/MainHD.vdi --mtype normal --device 0 --port 0

VBoxManage startvm MinimalCentOS

Follow the on screen prompts to install CentOS

Once it is installed and started login and shutdown.

VBoxManage snapshot MinimalCentOS take CentOSInstalled

So if we make a mistake we can return here

VBoxManage startvm MinimalCentOS

Login

vi  /etc/udev/rules.d/70-persistent-net.rules
Add net rules
vi /etc/udev/rules.d/75-persistent-net-generator.rules


cd /etc/sysconfig/network-scripts/
vi ifcfg-eth0 
Remove mac-address
Remove UUID
set onboot=yes
set bootproto=no
set ipaddr=10.1.2.3

vi ifcfg-eth0 
Remove mac-address
Remove UUID
set onboot=yes

vi /etc/ssh/sshd_config
uncomment PermitRootLogin=yes

service iptables stop

shutdown -h 0

VBoxManage snapshot MinimalCentOS take BasicNetworking

VBoxManage clonevm MinimalCentOS --snapshot BasicNetworking --mode machine --options link --name ansible --register

VBoxManage startvm ansible --type headless

ssh root@10.1.2.3

install ansible using yum (see ansible website)

yum install epel-release

yum install ansible

Now secure the server.

Get this Git Repo

