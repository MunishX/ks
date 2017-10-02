#!/bin/bash

# TIGER-VNC install and start

yum groupinstall "GNOME Desktop" -y

unlink /etc/systemd/system/default.target
ln -sf /lib/systemd/system/graphical.target /etc/systemd/system/default.target

yum install sudo tigervnc-server xorg-x11-fonts-Type1 -y


# adduser vnc
# passwd vnc

# gpasswd -a vnc sudo
# su - vnc

echo "start vnc server command : vncserver"
echo "rebooting now!!!"

reboot
