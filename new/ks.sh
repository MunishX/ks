#!/bin/bash

# cd /tmp && rm -rf ks.sh && yum install wget -y && wget https://github.com/MunishX/ks/raw/refs/heads/master/new/ks.sh && chmod 777 ks.sh && ./ks.sh

###################
###  constants  ###
###################
HOSTNAME="host"
REQUIRED_SPACE_MB=700

###################
###  functions  ###
###################
read_hostname(){
    read -p "Enter new server's hostname: (ex: host.domain.com)" HOSTNAME
    if [[ -z "$HOSTNAME" ]]; then
            echo "[error] HOSTNAME cannot be empty, Failed.. Exiting..."
            exit 1
    fi
}
check_sudo(){
    if [ "$EUID" -ne 0 ]; then
      echo "Please run this script with sudo or as root."
      exit 1
    fi

    #sudo_prefix=""
    #if [ "$EUID" -eq 0 ]; then
    #    sudo_prefix=""
    #    echo "[info] Installer running from root user, so skipping sudo ...";
    #else
    #    sudo_prefix="sudo "
    #    echo "[info] Installer running from non-root user, so using sudo ...";
    #fi

}
detect_os(){
    os_type="NULL"

    if [ -n "$(command -v yum)" ]
    then
    os_type="yum"
    fi

    if [ -n "$(command -v apt-get)" ]
    then
    os_type="apt"
    fi

    if [[ $os_type = "NULL" ]]
    then
    echo "[error] Un-Supported OS found. Exiting.. Supported OS are: Ubuntu, Debian, CentOS, Rocky, AmlaLinux, Redhat and Fedora."
    exit 0
    else
    echo "[info] Supported OS found. OS_Type: $os_type"
    fi
}

prepare_grub2() {
    # check Grub2 update file present or not (required)
    if [ -e /etc/grub.d/40_custom ]
    then
    echo "[info] Grub2 update file found."
    else
    echo "[error] Grub2 not available. Exiting..."
    exit 0
    fi

    # get Grub2 config file path
    grub_out_file="NULL"
    #ROOT_UUID_LINE="NULL"

    if [ -e /boot/grub2/grub.cfg ]
    then
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub2/grub.cfg | head -1`
    grub_out_file="/boot/grub2/grub.cfg"
    fi

    if [ -e /boot/grub/grub.cfg ]
    then
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub/grub.cfg | head -1`
    grub_out_file="/boot/grub/grub.cfg"
    fi

    if [[ $grub_out_file = "NULL" ]]
    then
    echo "[error] Grub2 config file not found. Exiting..."
    exit 0
    else
    echo "[info] Grub2 config file found."
    fi

    #if [[ $ROOT_UUID_LINE = "NULL" ]]
    #then
    #echo "Grub2 config file not found. Aborting Process"
    #exit 0
    #fi

    # detect net.ifnames via uuid
    CONFIG_APPEND_LINE=""
    SEARCHWORD="net.ifnames=0"
    if grep -nE "^[^#]*\\b${SEARCHWORD}\\b" ${grub_out_file}
    then
    echo "[info] net.ifnames found in grub2 config, updated CONFIG_APPEND_LINE.."
    CONFIG_APPEND_LINE=" net.ifnames=0 biosdevname=0 "
    else
    echo "[info] net.ifnames not found in grub2 config, ignoring CONFIG_APPEND_LINE.."
    fi

}

prepare_network() {
    NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}' | head -1)"
    IPADDR=$(ip a s "$NETWORK_INTERFACE_NAME" | grep "inet " | awk '{print $2}' | awk -F '/' '{print $1}' | head -1)
    PREFIX=$(ip a s "$NETWORK_INTERFACE_NAME" | grep "inet " | awk '{print $2}' | awk -F '/' '{print $2}' | head -1)
    GW=$(ip route | grep default | awk '{print $3}' | head -1)
    DNS1=8.8.8.8
    DNS2=8.8.4.4
}

prepare_os(){
    # https://rockylinux.mirrors.ovh.net/9/isos/x86_64/
    # https://mirror.de.leaseweb.net/rockylinux/9/isos/x86_64/
    MIRROR="https://mirror.leaseweb.com/rockylinux/9.8/BaseOS/x86_64/os/"
    KSURL="https://github.com/MunishX/ks/raw/refs/heads/master/new/ks.cfg"
    KSFName="ks.cfg"
}

prepare_target_cleanup(){
    echo "[info] Cleanup for Target path $TARGET_PATH has started..."
    ls ${TARGET_PATH}
    rm -rf ${TARGET_PATH}{vmlinuz,initrd.img}
    rm -rf ${TARGET_PATH}${KSFName}
    ls  ${TARGET_PATH}
    echo "[info] Cleanup for Target path $TARGET_PATH has ended..."
}

prepare_target(){
    TARGET_PATH="/boot/"
    prepare_target_cleanup

    AVAILABLE_SPACE_MB="$(df --block-size=1048576  ${TARGET_PATH}  | awk 'NR==2 {print $4}')"
    # Compare the values
    if [ "$AVAILABLE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
        echo "[warning] Target path $TARGET_PATH has less than $REQUIRED_SPACE_MB MB, Switching path to /, trying again..."
    else
        echo "[info] Target path $TARGET_PATH has more than $REQUIRED_SPACE_MB MB, proceeding..."
        return 0
    fi


    TARGET_PATH="/"
    prepare_target_cleanup

    AVAILABLE_SPACE_MB="$(df --block-size=1048576  ${TARGET_PATH}  | awk 'NR==2 {print $4}')"
    # Compare the values
    if [ "$AVAILABLE_SPACE_MB" -lt "$REQUIRED_SPACE_MB" ]; then
        echo "[error] Target path $TARGET_PATH has less than $REQUIRED_SPACE_MB MB, Setup Failed.., Exiting..."
        exit 1
    else
        echo "[info] Target path $TARGET_PATH has more than $REQUIRED_SPACE_MB MB, proceeding..."
        return 0
    fi

}

prepare_uuid(){
    # detect root via uuid new updated
    # target_path = /boot/
    if [[ "$TARGET_PATH" == "/boot/" ]]; then
        ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $2}'`
        BOOT_PATH="/"
        # Check if empty
        if [[ -z "$ROOT_UUID" ]]; then
            echo "[warning] Mount $TARGET_PATH is not found, using Mount / and retrying..."
            ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $2}'`
            BOOT_PATH="/boot/"
            if [[ -z "$ROOT_UUID" ]]; then
                echo "[error] Partition with path / is not found, Failed.. Exiting..."
                exit 1
            fi
        fi
    fi

    # target_path = /
    if [[ "$TARGET_PATH" == "/" ]]; then
    ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $2}'`
    BOOT_PATH="/"
        if [[ -z "$ROOT_UUID" ]]; then
            echo "[error] Partition with path / is not found, Failed.. Exiting..."
            exit 1
        fi
    fi

    ROOT_UUID_LINE="search --no-floppy --fs-uuid --set=root ${ROOT_UUID}"
    echo "[info] UUID of Target path $TARGET_PATH is: $ROOT_UUID "
    echo "[info] final ROOT_UUID_LINE: $ROOT_UUID_LINE "

    # detect root via set root line in grub
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub2/grub.cfg | head -1`
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub/grub.cfg | head -1`

    # detect root via uuid
    #if [[ -z "$ROOT_UUID_LINE" ]]; then
    #    ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $2}'`
    #    ROOT_UUID_LINE="search --no-floppy --fs-uuid --set=root ${ROOT_UUID}"
    #    echo "ROOT_UUID_LINE: $ROOT_UUID_LINE"
    #else
    #    echo "root_line = $ROOT_UUID_LINE"
    #fi

}

validate_all(){
    echo "[info] Validating all variables..."
}

install_required_tools(){

    if [[ "$os_type" == "yum" ]]; then
        yum -y install nano wget curl net-tools lsof zip unzip sudo sed
        echo "[info] Installing basic tools via yum..."
        return 0
    fi
    if [[ "$os_type" == "apt" ]]; then
        apt-get -y install nano wget curl net-tools lsof zip unzip sudo sed
        echo "[info] Installing basic tools via apt..."
        return 0
    fi

    echo "[error] OS type is unsupported. Exiting..."
    exit 0
}

download_boot_image_files(){
    status_code=$(curl -w "%{http_code}" -o ${TARGET_PATH}vmlinuz ${MIRROR}images/pxeboot/vmlinuz)
    if [ "$status_code" -ne 200 ]; then
        echo "[error] Downloading ${MIRROR}images/pxeboot/vmlinuz failed, with status $status_code"
        exit 1
    else
        echo "[info] Downloaded ${MIRROR}images/pxeboot/vmlinuz success, with status 200 OK. "
        echo "[info] File Saved to: ${TARGET_PATH}vmlinuz"
    fi

    status_code=$(curl -w "%{http_code}" -o ${TARGET_PATH}initrd.img ${MIRROR}images/pxeboot/initrd.img)
    if [ "$status_code" -ne 200 ]; then
        echo "[error] Downloading ${MIRROR}images/pxeboot/initrd.img failed, with status $status_code"
        exit 1
    else
        echo "[info] Downloaded ${MIRROR}images/pxeboot/initrd.img success, with status 200 OK. "
        echo "[info] File Saved to: ${TARGET_PATH}initrd.img"
    fi

    status_code=$(curl -w "%{http_code}" -o ${TARGET_PATH}${KSFName} ${KSURL})
    if [ "$status_code" -ne 200 ]; then
        echo "[error] Downloading ${KSURL} failed, with status $status_code"
        exit 1
    else
        echo "[info] Downloaded ${KSURL} success, with status 200 OK. "
        echo "[info] File Saved to: ${TARGET_PATH}${KSFName}"
    fi
}

cleanup_before_install(){
     # clear old reinstall entries if present
     sed -i '/reinstall_menu_entry_start/,$d' /etc/grub.d/40_custom
     sleep 1
}

add_reinstall_grub2_entry(){
cat << EOF >> /etc/grub.d/40_custom
# reinstall_menu_entry_start
menuentry "reinstall" {
    $ROOT_UUID_LINE
    linux ${BOOT_PATH}vmlinuz ip=${IPADDR}::${GW}:${PREFIX}:${HOSTNAME}:${NETWORK_INTERFACE_NAME}:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=hd:UUID=${ROOT_UUID}:${BOOT_PATH}${KSFName} inst.lang=en_US inst.keymap=us inst.vnc ${CONFIG_APPEND_LINE}
    #linux inst.repo=$MIRROR inst.ks=${KSURL} inst.lang=en_US inst.keymap=us inst.vnc
    initrd ${BOOT_PATH}initrd.img
}
# reinstall_menu_entry_end
EOF
    echo "[info] Grub2 Menu Entry 'reinstall' added..."
}


update_grub2_menu_list(){
    sleep 1

    if [[ $os_type = "yum" ]]
    then
        grub2-mkconfig
        grub2-mkconfig --output=${grub_out_file}
        #grubby --info=ALL
        #grub2-mkconfig --output=/boot/grub2/grub.cfg

        #grubby --default-index
        grub2-reboot  "reinstall"
        #grubby --default-index

        grub2-editenv list
    fi

    if [[ $os_type = "apt" ]]
    then
        update-grub
        grub-reboot  "reinstall"
        grub-editenv list
    fi

    echo "[info] Grub2 Menu Entry rebuild done, and 'reinstall' set for next reboot..."
}

update_ks_file(){
    sed -i "s/___MIRROR___/${MIRROR}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___NETWORK_INTERFACE_NAME___/${NETWORK_INTERFACE_NAME}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___GW___/${GW}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___IPADDR___/${IPADDR}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___DNS1___/${DNS1}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___DNS2___/${DNS2}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___PREFIX___/${PREFIX}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___HOSTNAME___/${HOSTNAME}/g" "${TARGET_PATH}${KSFName}"
    echo "[info] ks.cfg Variables replaced with their value..."
}

setup_complete(){
    echo ""
    echo ""


    echo ""
    echo ""
    echo " >>> Auto updated 'IP, Gateway, Network & Hostname' in kickstart config file .. <<<"
    echo "IP : $IPADDR"
    echo "Gateway : $GW"
    echo "Network Interface : ${NETWORK_INTERFACE_NAME}"
    echo "Hostname : ${HOSTNAME}"
    echo "CURRENT DNS : "
    ( nmcli dev list || nmcli dev show ) 2>/dev/null | grep DNS
    echo ""
    echo "DONE!  (reboot now, to start installation...)"
    echo ""

}

read_hostname
check_sudo
detect_os
prepare_grub2
prepare_network
prepare_os
prepare_target
prepare_uuid

validate_all

install_required_tools
download_boot_image_files

cleanup_before_install
add_reinstall_grub2_entry
update_grub2_menu_list
update_ks_file
setup_complete


