#/bin/bash

# cd /tmp && wget https://raw.githubusercontent.com/munishgaurav5/ks/master/raid0_4disk_centos7_minimal_install.sh && chmod 777 raid0_4disk_centos7_minimal_install.sh && ./raid0_4disk_centos7_minimal_install.sh 


# author: François Cami <fcami@fedoraproject.org>
# License: MIT

# see README.md

#export INSTALL_SRV="http://KICKSTART_SRV_FQDN/"
 

### NEW ###
yum -y install nano wget curl net-tools lsof bzip2 zip unzip rar unrar epel-release git sudo make cmake GeoIP sed at
NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}')"
###########

export KSURL="https://github.com/munishgaurav5/ks/raw/master/raid0_4disk_centos7_minimal.cfg"
export DNS1=8.8.8.8
export DNS2=8.8.4.4

#export MIRROR="http://mirror.ircam.fr/pub/CentOS/7.2.1511/os/x86_64/"
export MIRROR="http://mirror.nl.leaseweb.net/centos/7/os/x86_64/"

export IPADDR=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $1}')
export PREFIX=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $2}')
export GW=$(ip route|grep default | awk '{print $3}')

curl -o /boot/vmlinuz ${MIRROR}images/pxeboot/vmlinuz
curl -o /boot/initrd.img ${MIRROR}images/pxeboot/initrd.img


#    linux /vmlinuz net.ifnames=0 biosdevname=0 ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):eth0:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=$KSURL
# inst.vncconnect=${IPADDR}:5500 # inst.vnc inst.vncpassword=changeme headless
# inst.vnc inst.vncpassword=changeme inst.headless  inst.lang=en_US inst.keymap=us


echo ""
echo ""
root_value=`grep "set root=" /boot/grub2/grub.cfg | head -1`
echo "$root_value"
echo ""
echo ""
sleep 5
echo ""

#Boot_device=${NETWORK_INTERFACE_NAME}
Boot_device="eth0"

cat << EOF >> /etc/grub.d/40_custom
menuentry "reinstall" {
    $root_value
    linux /vmlinuz net.ifnames=0 biosdevname=0 ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):$Boot_device:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=$KSURL inst.vnc inst.vncconnect=${IPADDR}:1 inst.vncpassword=changeme inst.headless inst.lang=en_US inst.keymap=us 
    initrd /initrd.img
}
EOF


#sed -i -e "s/GRUB_DEFAULT.*/GRUB_DEFAULT=\"reinstall\"/g" /etc/default/grub

grub2-mkconfig
grub2-mkconfig --output=/boot/grub2/grub.cfg

grubby --info=ALL

echo ""
echo ""
echo "Setting Up default Grub Entry ..."
echo ""

sleep 5
echo ""

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
grubby --default-index
#grub-reboot 1
grub2-reboot  "reinstall"
grubby --default-index

echo ""
echo ""
echo " >>> Manually update 'IP, Gateway & Hostname' in kickstart config file .. <<<"
echo "IP : $IPADDR"
echo "Gateway : $GW"
echo "Network Interface : $NETWORK_INTERFACE_NAME" 
echo ""
echo "DONE!"
