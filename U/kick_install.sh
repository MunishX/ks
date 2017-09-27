



# Update
apt-get update -y
apt-get upgrade -y

# install apps
apt-get install -y nano wget curl net-tools lsof bzip2 zip unzip git sudo make cmake sed at

# configs

export KSURL="https://github.com/munishgaurav5/ks/raw/master/U/kick_tmp.cfg"
export MIRROR="http://fastserver.me/admin/iso/"  


NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}')"
Boot_device="eth0"

export DNS1=8.8.8.8
export DNS2=8.8.4.4

export IPADDR=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $1}')
export PREFIX=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $2}')
export GW=$(ip route|grep default | awk '{print $3}')

##### SETUP

curl -o /boot/ubuntu_vmlinuz ${MIRROR}install/vmlinuz
curl -o /boot/ubuntu_initrd.gz ${MIRROR}install/initrd.gz

echo ""
echo ""
# root_value=`grep "set root=" /boot/grub2/grub.cfg | head -1`
# root_value=`grep "set root=" /boot/grub/grub.cfg | head -2`
root_value="set root='hd0,msdos1'"
echo "$root_value"
echo ""
echo ""
sleep 2
echo ""

cat << EOF >> /etc/grub.d/40_custom
menuentry "reinstall" {
    $root_value
    linux /ubuntu_vmlinuz ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):$Boot_device:off nameserver=$DNS1 nameserver=$DNS2 repo=$MIRROR vga=788 file=${MIRROR}preseed/ubuntu-server.seed ks=$KSURL preseed/file=${MIRROR}ks.preseed vnc vncconnect=${IPADDR}:1 vncpassword=changeme headless 
    initrd /ubuntu_initrd.gz
}
EOF


#cat << EOF >> /etc/grub.d/40_custom
#menuentry "reinstall" {
#    $root_value
#    linux /ubuntu_vmlinuz net.ifnames=0 biosdevname=0 ip=${IPADDR}::${GW}:${PREFIX}:$(hostname):$Boot_device:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=$KSURL inst.vnc inst.vncconnect=${IPADDR}:1 inst.vncpassword=changeme inst.headless inst.lang=en inst.keymap=us 
#    initrd /ubuntu_initrd.gz
#}
#EOF


sed -i -e "s/GRUB_DEFAULT.*/GRUB_DEFAULT=\"reinstall\"/g" /etc/default/grub
sudo update-grub

#grub2-mkconfig
#grub2-mkconfig --output=/boot/grub2/grub.cfg

#grubby --info=ALL

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
#grubby --default-index
#grub-reboot 1
#grub2-reboot  "reinstall"
#grubby --default-index

echo ""
echo ""
echo " >>> Manually update 'IP, Gateway & Hostname' in kickstart config file .. <<<"
echo "IP : $IPADDR"
echo "Gateway : $GW"
echo "Network Interface : $NETWORK_INTERFACE_NAME" 
echo ""
echo "DONE!"
