



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
root_value=`grep "set root=" /boot/grub2/grub.cfg | head -1`
echo "$root_value"
echo ""
echo ""
sleep 2
echo ""

