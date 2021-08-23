#!/bin/bash

proxy_list_path="/usr/lib/proxy/"
systemd_list_path="/usr/lib/systemd/"

rdpproxy_info() {
    echo ""
    mkdir -p ${proxy_list_path}
    echo "-----------------------------------"
    echo "------------- INFO ----------------"
    echo "---- Current RDP Port Forwards ----"
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
   
PNAME=rdpproxy_${local_port}   
FNAME=${proxy_list_path}${PNAME}_*
SNAME=${systemd_list_path}system/${PNAME}.service
listcount=$(ls -1q $FNAME 2> /dev/null | wc -l)
#if test -f "$FILE"; then
#    echo "$FILE exists."
#fi
#if [[ $numprocesses -gt 15 ]] ; then
#  echo "Done."
#else
#  echo "Not Complete."
#fi
if [[ $listcount -eq 1 ]]; then
  #echo "found 1";
  systemctl stop ${PNAME} > /dev/null  2>&1
  systemctl disable ${PNAME} > /dev/null  2>&1
  rm -rf ${SNAME} > /dev/null  2>&1
  rm -rf ${FNAME} > /dev/null  2>&1
  sleep 1
    if test -f "$SNAME"; then
        #echo "Service file still exists."
        echo ""
    else
        #echo "Service file removed successfully."
        echo ""
    fi
  echo "------------------------------"
  echo "---------- Status ------------"
  echo ""
  echo "Status: SUCCESS! RDP proxy with port ${local_port} removed successfully."
  echo ""
  echo "------------------------------"
  rdpproxy_info
  exit;
else
  echo "------------------------------"
  echo "---------- Status ------------"
  echo ""
  echo "Status: ERROR! RDP proxy with port ${local_port} does not exist."
  echo ""
  echo "------------------------------"
  exit;
fi
#echo "count: $listcount"



 # stop, disable, remove intl, remove list file.
 # show status
 #rdpproxy_info
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
  #rdpproxy_info
  
PNAME=rdpproxy_${local_port}   
FNAME=${proxy_list_path}${PNAME}_*
SNAME=${systemd_list_path}system/${PNAME}.service
LNAME=${proxy_list_path}${PNAME}_${rdp_ip}_${rdp_port}

listcount=$(ls -1q $FNAME 2> /dev/null | wc -l)
#if test -f "$FILE"; then
#    echo "$FILE exists."
#fi
#if [[ $numprocesses -gt 15 ]] ; then
#  echo "Done."
#else
#  echo "Not Complete."
#fi
if [[ $listcount -eq 0 ]]; then
  #echo "found 0";
  systemctl stop ${PNAME}  > /dev/null  2>&1
  systemctl disable ${PNAME} > /dev/null  2>&1
  rm -rf ${SNAME} > /dev/null  2>&1
  rm -rf ${FNAME} > /dev/null  2>&1
  sleep 1
  cp /usr/lib/systemd/system/rdptunnel.sample ${SNAME}
  sed -i "s%rdplport%$local_port%" ${SNAME}
  sed -i "s%rdprport%$rdp_port%" ${SNAME}
  sed -i "s%rdprhost%$rdp_ip%" ${SNAME}
  touch ${LNAME}
  
    if test -f "$SNAME"; then
        #echo "Service file copied successfully."
        echo ""
        systemctl daemon-reload
        sleep 1
        systemctl enable ${PNAME} 
        systemctl start ${PNAME} 
        systemctl status ${PNAME} 

        if test -f "$LNAME"; then
           #echo "List file added successfully."
  echo "------------------------------"
  echo "---------- Status ------------"
  echo ""
  echo "Status: SUCCESS! RDP proxy with port ${local_port} added successfully."
  echo ""
  echo "------------------------------"
  rdpproxy_info
  exit;
    else
            #echo "List file not exist."
            echo "Error Occured!"
            #ls -alh ${LNAME}
        fi

    else
        #echo "Service file not exist."
        echo "Error Occured!"
    fi

  echo "------------------------------"
  echo "---------- Status ------------"
  echo ""
  echo "Status: ERROR! RDP proxy forwarding setup caused error.."
  echo ""
  echo "------------------------------"
  exit;

else
  echo "------------------------------"
  echo "---------- Status ------------"
  echo ""
  echo "Status: ERROR! RDP proxy with port ${local_port} forwarding already exist. Choose unused port.."
  echo ""
  echo "------------------------------"
  exit;
fi


  exit
 fi
 
rdpproxy_usages
rdpproxy_info
exit

fi

####################
#echo ""
#dname="Ricardo"
#read -p "Enter your name [${dname}]: " name
#read -e -i "$dname" -p "Enter your name: " name

#if [ -z "${name}" ]; then
#    name=${dname}
#else
#    echo ""
#fi

#echo ""
#echo $name
#echo ""


