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

init(){
    echo ""
    echo ""
    echo "========================================="
    echo "======== KS Rocky 9 Installation ========"
    echo "========================================="
    echo ""
}

read_hostname(){
    read -p "Enter new server's Hostname: (ex: host.domain.com) : " HOSTNAME
    if [[ -z "$HOSTNAME" ]]; then
            echo "[error] HOSTNAME cannot be empty, Failed.. Exiting..."
            exit 1
    fi
    HOSTNAME1="${HOSTNAME%%.*}"
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

detect_boot_mode(){
    if [ -d /sys/firmware/efi ] && [ -d /sys/firmware/efi/efivars ]; then
        BOOT_MODE="UEFI"
        LINUX_VAR="linuxefi "
        INITRD_VAR="initrdefi "
    else
        BOOT_MODE="BIOS"
        LINUX_VAR="linux "
        INITRD_VAR="initrd "
    fi
    echo "[info] Boot mode: $BOOT_MODE"
}

detect_disk(){
    if lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,PARTUUID,UUID,PTTYPE >/dev/null 2>&1; then 
        echo "[info] Disk Partition TYPE: GPT"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,PARTUUID,UUID,PTTYPE
    else
        echo "[info] Disk Partition TYPE: MBR"
        lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,PARTUUID,UUID
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

prefix_to_netmask() {
    local prefix=$1

    # Validate input is an integer between 0 and 32
    if [[ ! "$prefix" =~ ^[0-9]+$ ]] || [ "$prefix" -lt 0 ] || [ "$prefix" -gt 32 ]; then
        echo "Error: Prefix must be an integer between 0 and 32." >&2
        return 1
    fi

    # Calculate 32-bit mask value and shift mask into position
    local mask=$(( 0xffffffff << (32 - prefix) ))

    # Extract the 4 individual octets using bitwise AND and right shifts
    local o1=$(( (mask >> 24) & 255 ))
    local o2=$(( (mask >> 16) & 255 ))
    local o3=$(( (mask >> 8)  & 255 ))
    local o4=$((  mask        & 255 ))

    echo "${o1}.${o2}.${o3}.${o4}"
}

prepare_network() {
    NETWORK_INTERFACE_NAME="$(ip -o -4 route show to default | awk '{print $5}' | head -1)"
    IPADDR=$(ip a s "$NETWORK_INTERFACE_NAME" | grep "inet " | awk '{print $2}' | awk -F '/' '{print $1}' | head -1)
    PREFIX=$(ip a s "$NETWORK_INTERFACE_NAME" | grep "inet " | awk '{print $2}' | awk -F '/' '{print $2}' | head -1)
    NETMASK=$(prefix_to_netmask  "${PREFIX}")
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
        ROOT_DEV=`lsblk -lp -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $1}'`
        BOOT_PATH="/"
        # Check if empty
        if [[ -z "$ROOT_UUID" ]]; then
            echo "[warning] Mount $TARGET_PATH is not found, using Mount / and retrying..."
            ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $2}'`
            ROOT_DEV=`lsblk -lp -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $1}'`
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
    ROOT_DEV=`lsblk -lp -o "Name,UUID,MOUNTPOINT" | grep "/$" | head -1 | awk  '{print $1}'`
    BOOT_PATH="/"
        if [[ -z "$ROOT_UUID" ]]; then
            echo "[error] Partition with path / is not found, Failed.. Exiting..."
            exit 1
        fi
    fi

    echo "[info] DEV of Target path $TARGET_PATH is: $ROOT_DEV "
    echo "[info] UUID of Target path $TARGET_PATH is: $ROOT_UUID "

    ROOT_UUID_LINE="search --no-floppy --fs-uuid --set=root ${ROOT_UUID}"

    
    
    #if grep -nE "^[^#]*\\b${SEARCHWORD}\\b" ${grub_out_file}
    #then
    #echo "[info] net.ifnames found in grub2 config, updated CONFIG_APPEND_LINE.."
    #CONFIG_APPEND_LINE=" net.ifnames=0 biosdevname=0 "
    #else
    #echo "[info] net.ifnames not found in grub2 config, ignoring CONFIG_APPEND_LINE.."
    #fi

    IS_RAID=0
    mdadm --detail ${ROOT_DEV} > /dev/null 2>&1
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ]
    then
        IS_RAID=1
        ROOT_MDUUID="$(mdadm --detail ${ROOT_DEV} | grep -E '/dev/' | awk 'NR==2 {print $7}')"
        ROOT_MDUUID_CLEAN="${ROOT_MDUUID//-/}"
        ROOT_UUID_LINE="set root='mduuid/${ROOT_MDUUID_CLEAN}'";
        echo "[info] DEV of Target path $TARGET_PATH is RAID present: YES ";
        echo "[info] MDUUID of Target path $TARGET_PATH is: $ROOT_MDUUID "
        echo "[info] MDUUID of Target path $TARGET_PATH (clean) is: $ROOT_MDUUID_CLEAN "
    else
        echo "[info] DEV of Target path $TARGET_PATH is RAID present: NO ";
    fi

    echo "[info] final ROOT_UUID_LINE: $ROOT_UUID_LINE "
    

    # detect root via set root line in grub
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub2/grub.cfg | head -1`
    #ROOT_UUID_LINE=`grep "set root=" /boot/grub/grub.cfg | head -1`

    # detect root via uuid
    #if [[ -z "$ROOT_UUID_LINE" ]]; then
    #    ROOT_UUID=`lsblk -l -o "Name,UUID,MOUNTPOINT" | grep "/boot$" | head -1 | awk  '{print $2}'`
    #    ROOT_UUID_LINE="search --no-floppy --fs-uuid --set=root ${ROOT_UUID}"
    #    #ROOT_UUID_LINE="search --no-floppy --partuuid --set=root e93f4fe1-269b-40fe-9e68-2a4667321d86"
    #    #ROOT_UUID_LINE="search --label --set=root ROCKY-9-6-X86_64"
    #    #raid except mdraid is not supported much
    #    # uuid or partuuid info : blkid  or  lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,LABEL,PARTUUID,UUID,PTTYPE
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
        echo "[info] Installing basic tools via yum..."
        yum -y install nano wget curl net-tools lsof zip unzip sudo sed
        return 0
    fi
    if [[ "$os_type" == "apt" ]]; then
        echo "[info] Installing basic tools via apt..."
        apt-get -y install nano wget curl net-tools lsof zip unzip sudo sed
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
        chmod +x ${TARGET_PATH}vmlinuz
    fi

    status_code=$(curl -w "%{http_code}" -o ${TARGET_PATH}initrd.img ${MIRROR}images/pxeboot/initrd.img)
    if [ "$status_code" -ne 200 ]; then
        echo "[error] Downloading ${MIRROR}images/pxeboot/initrd.img failed, with status $status_code"
        exit 1
    else
        echo "[info] Downloaded ${MIRROR}images/pxeboot/initrd.img success, with status 200 OK. "
        echo "[info] File Saved to: ${TARGET_PATH}initrd.img"
    fi

    status_code=$(curl -w "%{http_code}" -L -o ${TARGET_PATH}${KSFName} ${KSURL})
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

    insmod part_gpt
    insmod part_msdos
    
    insmod fat
    insmod ext2
    insmod xfs
    
    insmod diskfilter
    
    #insmod mdraid
    insmod mdraid09
    insmod mdraid1x
    
    #insmod raid5rec
    #insmod raid6rec
    
    $ROOT_UUID_LINE
    #${LINUX_VAR} ${BOOT_PATH}vmlinuz ip=${IPADDR}::${GW}:${PREFIX}:${HOSTNAME}:${NETWORK_INTERFACE_NAME}:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=hd:UUID=${ROOT_UUID}:${BOOT_PATH}${KSFName} inst.lang=en_US inst.keymap=us inst.vnc ${CONFIG_APPEND_LINE}
    ${LINUX_VAR} ${BOOT_PATH}vmlinuz ip=${IPADDR}::${GW}:${NETMASK}:${HOSTNAME1}:${NETWORK_INTERFACE_NAME}:off nameserver=$DNS1 nameserver=$DNS2 inst.repo=$MIRROR inst.ks=hd:UUID=${ROOT_UUID}:${BOOT_PATH}${KSFName} inst.lang=en_US inst.keymap=us inst.vnc ${CONFIG_APPEND_LINE}
    ${INITRD_VAR} ${BOOT_PATH}initrd.img
}
# reinstall_menu_entry_end
EOF
    chmod +x /etc/grub.d/40_custom
    echo "[info] Grub2 Menu Entry 'reinstall' added..."
}

#--set root= must point to vmlinuz and initrd.img
#inst.ks=hd:md2:/ks.cfg
#inst.ks=hd:/dev/md2:/ks.cfg
#inst.ks=hd:UUID=c8c586d7-708c-4ae0-a07e-6d48e37584ad:/ks.cfg
#xfs_admin -L BOOT /dev/md2
#inst.ks=hd:LABEL=BOOT:/ks.cfg

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

        #grub2-set-default "My Custom Rocky Linux"

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
    sed -i "s|___MIRROR___|${MIRROR}|g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___NETWORK_INTERFACE_NAME___/${NETWORK_INTERFACE_NAME}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___GW___/${GW}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___IPADDR___/${IPADDR}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___DNS1___/${DNS1}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___DNS2___/${DNS2}/g" "${TARGET_PATH}${KSFName}"
    #sed -i "s/___PREFIX___/${PREFIX}/g" "${TARGET_PATH}${KSFName}"
    sed -i "s/___NETMASK___/${NETMASK}/g" "${TARGET_PATH}${KSFName}"
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

check_sudo
init
read_hostname
detect_os
detect_boot_mode
detect_disk
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

