#!/bin/sh

######################## IP START ###########################

        MAIN_IP="$(hostname -I)"
        MAIN_IP=${MAIN_IP//[[:blank:]]/}
        echo ""
        echo ""

   while [[ $IP_CORRECT = "" ]]; do # to be replaced with regex  
       read -p "(1/3) SERVER MAIN IP is ${MAIN_IP} (y/n) : " IP_CORRECT
       #$MAIN_IP
    done

if [ $IP_CORRECT != "y" ]; then
   read -p "SERVER IP : " MAIN_IP
   #exit 1
   
      IP_CORRECT=
      while [[ $IP_CORRECT = "" ]]; do # to be replaced with regex       
       read -p "SERVER IP is ${MAIN_IP} (y/n) : " IP_CORRECT
       #$MAIN_IP
      done
fi

if [ $IP_CORRECT != "y" ]; then
   #read -p "SERVER IP : " MAIN_IP
   echo "Error!... Try Again!"
   exit 1
fi

########
SET_ROOT=$2
   while [[ $SET_ROOT = "" ]]; do # to be replaced with regex
       read -p "(2/3) Enter GRUB Set_Root for /boot [lsblk] (md1) : " SET_ROOT
    done

VNC_PASS=$3
   while [[ $VNC_PASS = "" ]]; do # to be replaced with regex
       read -p "(3/3) Enter VNC_PASS (Info : VNC PORT : 5500): " VNC_PASS
    done

######################## IP END ###########################

# yum install system-config-kickstart
# ksvalidator kickstartfile.ks

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
## lsblk  (better)

##     set root=(hd0,0)

echo """
menuentry \"Install CentOS 7\" {
    set root=($SET_ROOT)
    linux /vmlinuz vncconnect=$MAIN_IP:5500 vncpassword=$VNC_PASS headless netmask=255.255.255.0 gateway=10.0.0.1 dns=8.8.8.8 ksdevice=eth0 ip=$MAIN_IP ks=https://github.com/munishgaurav5/ks/raw/master/centos7_4_.cfg ksdevice=eth0 lang=en_US keymap=us 
    initrd /initrd.img
}
""" >> /etc/grub.d/40_custom

# is grub is the boot loader or grub2 
# grub-install --version  or grub2-install --version

echo "### Setting grub default"
sed -i "s/GRUB_DEFAULT=\".*\"/GRUB_DEFAULT=\"Install CentOS 7\"/g" /etc/default/grub

echo "### Make grub2 config ###"
grub2-mkconfig --output=/boot/grub2/grub.cfg

#reboot

