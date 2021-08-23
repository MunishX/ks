#!/bin/bash

proxy_list_path="/usr/lib/proxy/"

rdpproxy_info() {
    echo ""
    mkdir -p ${proxy_list_path}
    echo "-----------------------------------"
    echo "-------------- INFO ---------------"
    echo ""
    echo "PORT -> RDP_IP:RDP_Port"
    echo "-----------------------"
    ls ${proxy_list_path}rdpproxy* | awk '{split($0,a,"_"); print a[2],"->",a[3]":"a[4]}'
    echo "-----------------------"
    echo ""
}

rdpproxy_usages() {
    echo ""
    echo "Usages:"
    echo "For Info Only    : rdpproxy"
    echo "For Adding   RDP : rdpproxy add"
    echo "For Removing RDP : rdpproxy remove"
    echo ""
}

rdpproxy_remove() {
    echo ""
    echo "-----------------------------------"
    echo "-------- Remove RDP Proxy ---------"
    echo ""
}

rdpproxy_add() {
    echo ""
    echo "-----------------------------------"
    echo "---------- Add RDP Proxy ----------"
    echo ""
}

#action=$1 echo ""
#    while [[ $action = "" ]]; do # to be replaced with regex
#       read -p "(1/6) Enter Username (user): " User_Name done
if [ -z "$1" ]; then
    rdpproxy_usages
    rdpproxy_info
else
    action=$1
    echo "action :" $1 #########
    
 if [ $action = "remove" ]; then
   local_port=$2
   while [[ $local_port = "" ]]; do # to be replaced with regex
       rdpproxy_info
       rdpproxy_remove
       read -p "Enter Port number to remove: " local_port
   done
 # stop, disable, remove intl, remove list file.
 # show list
 rdpproxy_info
 exit 
 fi
 
 if [ $action = "add" ]; then
   
   local_port=$2
   while [[ $local_port = "" ]]; do # to be replaced with regex
       rdpproxy_info
       rdpproxy_add
       read -p "Enter unused Port for RDP proxy : " local_port
    done
  
   rdp_ip=$3
   echo ""
   while [[ $rdp_ip = "" ]]; do # to be replaced with regex
       read -p "RDP IP : " rdp_ip
    done

   rdp_port=$4
   drdp_port="3389"
   echo ""
   while [[ $rdp_port = "" ]]; do # to be replaced with regex
       read -e -i "$drdp_port" -p  "RDP Port : " rdp_port
    done

  ## copy intl , replace data , make list file, reload intl, start enable,
  ## show status done.
  ## show list
  rdpproxy_info
  exit
 fi
 
rdpproxy_usages
rdpproxy_info
exit

fi

####################
echo ""
dname="Ricardo"
#read -p "Enter your name [${dname}]: " name
#read -e -i "$dname" -p "Enter your name: " name

if [ -z "${name}" ]; then
    name=${dname}
else
    echo ""
fi

echo ""
echo $name
echo ""


