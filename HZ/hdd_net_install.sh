#/bin/bash

# cd /tmp && yum install wget -y && wget https://github.com/munishgaurav5/ks/raw/master/HZ/hdd_net_install.sh && chmod 777 hdd_net_install.sh && ./hdd_net_install.sh 

echo ""
echo ""

if [ -e /etc/grub.d/40_custom ]
then
echo "Starting New CentOS 7 Installation Process"
else
echo "Grub2 not available. Aborting Process"
exit 0
fi

echo ""
echo ""

### NEW ###
os_type="NULL"

if [ -n "$(command -v yum)" ]
then
os_type="yum"
yum -y install nano wget curl net-tools lsof zip unzip sudo sed 
fi

if [ -n "$(command -v apt-get)" ]
then
os_type="apt"
sudo apt-get -y install nano wget curl net-tools lsof zip unzip sudo sed 
fi

NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}' | head -1)"
#NETWORK_INTERFACE_NAME="em22"
###########

# author: François Cami <fcami@fedoraproject.org>
# License: MIT

# see README.md

#export INSTALL_SRV="http://KICKSTART_SRV_FQDN/"

export KSURL="https://raw.githubusercontent.com/munishgaurav5/ks/master/HZ/hdd.cfg"
export KSFName="ks.cfg"
export ISOName="cos.iso"
export DNS1=8.8.8.8
export DNS2=8.8.4.4

#export MIRROR="http://mirror.ircam.fr/pub/CentOS/7.2.1511/os/x86_64/"
#export MIRROR="http://mirror.nl.leaseweb.net/centos/7/os/x86_64/"
#export MIRROR="http://mirror.inode.at/centos/7.3.1611/os/x86_64/"
#export MIRROR="http://mirror.imt-systems.com/centos/7/os/x86_64/"  
#export MIRROR="http://mirror.nl.leaseweb.net/centos-vault/7.2.1511/os/x86_64/"
#export MIRROR="http://mirror.nl.leaseweb.net/centos-vault/7.6.1810/os/x86_64/"

export MIN_ISO="http://mirror.nl.leaseweb.net/centos-vault/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso"

# yum -y install bind-utils
# ip route get $(dig +short google.com | tail -1)

export IPADDR=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $1}' | head -1)
export PREFIX=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $2}' | head -1)
export GW=$(ip route|grep default | awk '{print $3}' | head -1)

rm -rf /boot/{vmlinuz,initrd.img}
rm -rf /boot/${KSFName}
rm -rf /boot/${ISOName}

#curl -o /boot/vmlinuz ${MIRROR}images/pxeboot/vmlinuz
#curl -o /boot/initrd.img ${MIRROR}images/pxeboot/initrd.img
curl -o /boot/${KSFName} ${KSURL}
curl -o /boot/${ISOName} ${MIN_ISO}


#    linux /vmlinuz net.ifnames=0 biosdevname=0 ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):eth0:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=$KSURL
# inst.vncconnect=${IPADDR}:5500 # inst.vnc inst.vncpassword=changeme headless
# inst.vnc inst.vncpassword=changeme inst.headless  inst.lang=en_US inst.keymap=us

echo ""
echo ""

root_value="NULL"

if [ -e /boot/grub2/grub.cfg ]
then
root_value=`grep "set root=" /boot/grub2/grub.cfg | head -1` 
grub_out_file="/boot/grub2/grub.cfg"
fi

if [ -e /boot/grub/grub.cfg ]
then
root_value=`grep "set root=" /boot/grub/grub.cfg | head -1` 
grub_out_file="/boot/grub/grub.cfg"
fi

if [[ $root_value = "NULL" ]]
then
echo "Grub2 config file not found. Aborting Process"
exit 0
fi

echo ""
echo "$root_value"
echo ""
echo ""
sleep 5
echo ""




Boot_device=${NETWORK_INTERFACE_NAME}
#Boot_device="eth0"
#PREFIX=24



#menuentry "reinstall" {
#    set root=hd0,msdos1
#    insmod part_msdos
#    linux /boot/cos/images/pxeboot/vmlinuz inst.repo=http://mirror.nl.leaseweb.net/centos-vault/7.6.1810/os/x86_64/  inst.ks=hd:sda1:/boot/ks.cfg   inst.lang=en_US inst.keymap=us inst.headless
#    initrd /boot/cos/images/pxeboot/initrd.img
#}


###!/bin/sh
##exec tail -n +3 $0

     #boot_part=`df -h | grep -oP "/boot"`

     boot_part=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $3}'`
     if [[ $boot_part = "/boot" ]] 
     then
     boot_hd=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $1}'`
cat << EOF >> /etc/grub.d/40_custom
menuentry "reinstall" {
    insmod part_msdos
    $root_value
    set isofile=/\${ISOName}
    loopback loop $isofile
    probe --set isouuid --fs-uuid (loop)
    linux (loop)/isolinux/vmlinuz root=live:UUID=\${isouuid} iso-scan/filename=\${isofile} inst.repo=file:///images/install/squashfs.img quiet inst.ks=hd:${boot_hd}:/${KSFName} inst.lang=en_US inst.keymap=us inst.vnc
    initrd (loop)/isolinux/initrd.img
}
EOF
     else
     boot_hd=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $1}'`
cat << EOF >> /etc/grub.d/40_custom
menuentry "reinstall" {
    insmod part_msdos
    $root_value
    set isofile=/boot/${ISOName}
    loopback loop \$isofile
    probe --set isouuid --fs-uuid (loop)
    linux (loop)/isolinux/vmlinuz root=live:UUID=\${isouuid} iso-scan/filename=\${isofile} inst.repo=file:///images/install/squashfs.img quiet inst.ks=hd:${boot_hd}:/boot/${KSFName} inst.lang=en_US inst.keymap=us inst.vnc
    initrd (loop)/isolinux/initrd.img
}
EOF
     fi

#ip=dhcp nameserver=$DNS1 nameserver=$DNS2  
#ip=${IPADDR}
#ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):$Boot_device:off nameserver=$DNS1 nameserver=$DNS2 inst.vnc inst.vncconnect=${IPADDR}:1 inst.vncpassword=changeme inst.headless 
#sed -i -e "s/GRUB_DEFAULT.*/GRUB_DEFAULT=\"reinstall\"/g" /etc/default/grub

echo ""
echo ""
echo "Setting Up default Grub Entry ..."
echo ""

sleep 5
echo ""


if [[ $os_type = "yum" ]]
then

grub2-mkconfig
grub2-mkconfig --output=${grub_out_file}
grubby --info=ALL

#grub2-mkconfig --output=/boot/grub2/grub.cfg

grubby --default-index
grub2-reboot  "reinstall"
grubby --default-index

grub2-editenv list

fi

if [[ $os_type = "apt" ]]
then

sudo update-grub
grub-reboot  "reinstall"
grub-editenv list

fi

# install grub-customizer

### Permanent Boot Change
#grubby --default-index
#grub2-set-default 'reinstall'
#grubby --default-index

### Permanent Boot Change
#grubby --default-index
#grubby --set-default /boot/vmlinuz
#grubby --default-index

### One Time Boot Change
#grub-reboot 1
# boot our new menu entry for the next reboot. 
# We just need to use the menu entry title.

# verify the default menu entry.
# you can use grub2-set-default 'MenuEntry' 
# to change the default boot


echo ""
echo ""
echo " >>> Manually update 'IP, Gateway & Hostname' in kickstart config file .. <<<"
echo "IP : $IPADDR"
echo "Gateway : $GW"
echo "Network Interface : $Boot_device" 
echo ""
echo "DONE!"
