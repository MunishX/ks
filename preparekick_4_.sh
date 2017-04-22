#!/bin/sh

echo "### Getting vmlinux and initrd.img ###"
mkdir -p /boot/
rm -rf /boot/vmlinuz
rm -rf /boot/initrd.img

curl -o /boot/vmlinuz http://mirror.nl.leaseweb.net/centos/7/os/x86_64/isolinux/vmlinuz
curl -o /boot/initrd.img http://mirror.nl.leaseweb.net/centos/7/os/x86_64/isolinux/initrd.img

#http://mirror.nl.leaseweb.net/centos/7/os/x86_64/isolinux/

echo "### Setting content in /etc/grub.d/40_custom ###"
##  ip=10.0.0.10
## ip=dhcp
## nano /etc/fstab  for hd serial for /boot/

echo """
menuentry \"Install CentOS 7\" {
    set root=(hd0,0)
    linux /vmlinuz vncconnect=81.2.240.249:5500 vncpassword=password headless netmask=255.255.255.0 gateway=10.0.0.1 dns=8.8.8.8 ksdevice=eth0 ip=81.2.240.249 ks=https://github.com/munishgaurav5/kickstart/raw/master/centos7minimal.cfg ksdevice=eth0 lang=en_US keymap=us 
    initrd /initrd.img
}
""" >> /etc/grub.d/40_custom

# is grub is the boot loader or grub2 
# grub-install --version  or grub2-install --version

echo "### Setting grub default"
sed -i "s/GRUB_DEFAULT=\".*\"/GRUB_DEFAULT=\"Install CentOS 7\"/g" /etc/default/grub

echo "### Make grub2 config ###"
grub2-mkconfig --output=/boot/grub2/grub.cfg

