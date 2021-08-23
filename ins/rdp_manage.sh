#!/bin/bash
#action=$1 echo ""
#    while [[ $action = "" ]]; do # to be replaced with regex
#       read -p "(1/6) Enter Username (user): " User_Name done
if [ -z "$1" ]; then
    echo "Usages:"
    echo "For Info Only    : rdpproxy"
    echo "For Adding   RDP : rdpproxy add"
    echo "For Removing RDP : rdpproxy remove"
    echo ""
    rdpproxy_info();
else
    action=$1
    echo "action :" $1
fi

echo ""
dname="Ricardo"
#read -p "Enter your name [${dname}]: " name
read -e -i "$dname" -p "Enter your name: " name

if [ -z "${name}" ]; then
    name=${dname}
else
    echo ""
fi

echo ""
echo $name
echo ""

function rdpproxy_info() {
    echo "-----------------------------------"
    echo "-------------- INFO ---------------"
    echo ""
    echo "PORT -> RDP_IP:RDP_Port"
    ls /usr/lib/proxy/rdpproxy* | awk '{split($0,a,"_"); print a[2],"->",a[3]":"a[4]}'
}
