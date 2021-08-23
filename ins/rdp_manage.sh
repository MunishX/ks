#!/bin/bash

action=$1
echo ""

#    while [[ $action = "" ]]; do # to be replaced with regex
#       read -p "(1/6) Enter Username (user): " User_Name
#    done

if [ -z "${action}" ];
then
    echo "true"
else
    echo "false"
fi

echo ""
dname="Ricardo"
read -p "Enter your name [${dname}]: " name
#read -e -i "$name" -p "Enter your name: " input
name="${name:-$dname}"

echo ""
echo $name 
echo ""

