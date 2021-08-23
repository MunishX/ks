#!/bin/bash
#action=$1 echo ""
#    while [[ $action = "" ]]; do # to be replaced with regex
#       read -p "(1/6) Enter Username (user): " User_Name done
if [ -z "$1" ]; then
    echo "info"
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
