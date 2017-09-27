



# Update
apt-get update -y
apt-get upgrade -y

# install apps
apt-get install -y nano wget curl net-tools lsof bzip2 zip unzip git sudo make cmake sed at

# configs
NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}')"


export KSURL="https://github.com/munishgaurav5/ks/raw/master/noraid_1disk_centos7_minimal.cfg"
export MIRROR="http://mirror.imt-systems.com/centos/7/os/x86_64/"  


export DNS1=8.8.8.8
export DNS2=8.8.4.4

export IPADDR=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $1}')
export PREFIX=$(ip a s $NETWORK_INTERFACE_NAME |grep "inet "|awk '{print $2}'| awk -F '/' '{print $2}')
export GW=$(ip route|grep default | awk '{print $3}')

##### SETUP

curl -o /boot/vmlinuz ${MIRROR}images/pxeboot/vmlinuz
curl -o /boot/initrd.img ${MIRROR}images/pxeboot/initrd.img

