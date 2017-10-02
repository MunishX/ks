#!/bin/bash

# VIRT-M

# cd /tmp && yum install wget && wget https://github.com/munishgaurav5/ks/raw/master/ins/virt.sh && chmod 777 virt.sh && ./virt.sh

egrep '(vmx|svm)' /proc/cpuinfo

yum groupinstall "Virtualization Host" -y
yum install -y qemu-kvm qemu-img libvirt virt-install libvirt-python virt-manager virt-install libvirt-client virt-viewer 

lsmod |grep kvm
modprobe kvm
lsmod |grep kvm

systemctl start libvirt-guests.service
systemctl start libvirtd

systemctl enable libvirt-guests.service
systemctl enable libvirtd

systemctl status libvirt-guests.service
systemctl status libvirtd

echo "Reboot manually Now !!"
# IN GUI
# virt-manager
# virt-install --name=ArkitRHEL7 --ram=1024 --vcpus=1 --cdrom=/var/lib/libvirt/images/rhel-server-7.3-x86_64-dvd.iso --os-type=linux --os-variant=rhel7  --network bridge=br0 --graphics=spice  --disk path=/var/lib/libvirt/images/rhel7.dsk,size=20
