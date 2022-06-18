#!/bin/bash
#================================================================================================
#
# This file is licensed under the terms of the GNU General Public
# License version 2. This program is licensed "as is" without any
# warranty of any kind, whether express or implied.
#
# This file is a part of the make OpenWrt for Amlogic s9xxx tv box
# https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Description: Build OpenWrt with Image Builder
# Copyright (C) 2021- https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021- https://github.com/ophub/amlogic-s9xxx-openwrt
#
# Instructions: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Download options: https://downloads.openwrt.org/releases
# Command: ./imagebuilder.sh
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# custom_packages         : Add custom packages
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
imagebuilder_path="${make_path}/openwrt"
custom_files_path="${make_path}/router-config/openwrt-imagebuilder/files"
# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
OPTIONS="[\033[93m OPTIONS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"
#
#================================================================================================

# Encountered a serious error, abort the script execution
error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

# Downloading OpenWrt ImageBuilder
download_imagebuilder() {
    # Downloading imagebuilder files
    echo -e "${STEPS} Start downloading OpenWrt files..."
    # # Download example: https://downloads.openwrt.org/releases/21.02.3/targets/armvirt/64/openwrt-imagebuilder-21.02.3-armvirt-64.Linux-x86_64.tar.xz
    download_file="https://downloads.openwrt.org/releases/${rebuild_branch}/targets/armvirt/64/openwrt-imagebuilder-${rebuild_branch}-armvirt-64.Linux-x86_64.tar.xz"
    wget -q ${download_file}
    [[ "$?" -eq "0" ]] || error_msg "Wget download failed: ${download_file}"

    # Unzip and change the directory name
    tar -xJf openwrt-imagebuilder-* && sync && rm -f openwrt-imagebuilder-*.tar.xz
    mv -f openwrt-imagebuilder-* openwrt

    sync && sleep 3
    echo -e "${INFO} Current directory status: $(ls . -l 2>/dev/null)"
}

# Add custom packages
# If there is a custom package or ipk you would prefer to use create a [ packages ] directory,
# If one does not exist and place your custom ipk within this directory.
custom_packages() {
    cd ${imagebuilder_path}

    # Create a [ packages ] directory
    echo -e "${STEPS} Start adding custom packages..."
    [[ -d "packages" ]] || mkdir packages

    # Download luci-app-amlogic
    amlogic_api="https://api.github.com/repos/ophub/luci-app-amlogic/releases"
    #
    amlogic_file="luci-app-amlogic"
    amlogic_file_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_name}.*.ipk" | head -n 1)"
    wget -q ${amlogic_file_down} -O packages/${amlogic_file_down##*/}
    [[ "$?" -eq "0" ]] && echo -e "${INFO} The [ ${amlogic_file} ] is downloaded successfully."
    #
    amlogic_i18n="luci-i18n-amlogic"
    amlogic_i18n_down="$(curl -s ${amlogic_api} | grep "browser_download_url" | grep -oE "https.*${amlogic_i18n}.*.ipk" | head -n 1)"
    wget -q ${amlogic_i18n_down} -O packages/${amlogic_i18n_down##*/}
    [[ "$?" -eq "0" ]] && echo -e "${INFO} The [ ${amlogic_i18n} ] is downloaded successfully."

    # Download other luci-app-xxx
    #

    sync && sleep 3
    echo -e "${INFO} Packages directory status: $(ls packages -l 2>/dev/null)"
}

# Add custom files
# The FILES variable allows custom configuration files to be included in images built with Image Builder.
# The [ files ] directory should be placed in the Image Builder root directory where you issue the make command.
custom_files() {
    cd ${imagebuilder_path}

    # Copy custom files
    [[ -d "${custom_files_path}" ]] && {
        echo -e "${STEPS} Start adding custom files..."
        [[ -d "files" ]] || mkdir -p files
        cp -rf ${custom_files_path}/* files

        sync && sleep 3
        echo -e "${INFO} files directory status: $(ls files -l 2>/dev/null)"
    }
}

# Rebuild OpenWrt firmware
rebuild_firmware() {
    cd ${imagebuilder_path}

    echo -e "${STEPS} Start building OpenWrt with Image Builder..."

    # Selecting packages
    my_packages="\
        perl-http-date perlbase-getopt perlbase-time perlbase-unicode perlbase-utf8 blkid fdisk \
        lsblk parted attr btrfs-progs chattr dosfstools e2fsprogs f2fs-tools f2fsck lsattr mkf2fs \
        xfs-fsck xfs-mkfs bash gawk getopt losetup pv uuidgen coremark coreutils uclient-fetch wwan \
        coreutils-base64 coreutils-nohup kmod-brcmfmac kmod-brcmutil kmod-cfg80211 kmod-mac80211 \
        hostapd-common wpa-cli wpad-basic iw subversion-client subversion-libs wget curl whereis \
        base-files bind-server block-mount blockd busybox usb-modeswitch tini lscpu mount-utils \
        ziptool zstd iconv jq docker docker-compose dockerd containerd dumpe2fs e2freefrag exfat-mkfs \
        resize2fs tune2fs ttyd zoneinfo-asia zoneinfo-core bc iwinfo jshn libjson-script libnetwork \
        openssl-util rename runc which liblucihttp bsdtar pigz gzip bzip2 unzip xz-utils xz tar \
        liblucihttp-lua ppp ppp-mod-pppoe proto-bonding cgi-io uhttpd uhttpd-mod-ubus comgt comgt-ncm uqmi \
        luci luci-app-firewall luci-app-opkg luci-base luci-lib-base luci-i18n-base-en luci-i18n-base-zh-cn \
        luci-lib-ip luci-lib-ipkg luci-lib-jsonc luci-lib-nixio luci-mod-admin-full \
        luci-mod-network luci-proto-3g luci-proto-bonding luci-proto-ipip luci-proto-ncm luci-proto-openconnect \
        luci-mod-status luci-mod-system luci-proto-ipv6 luci-proto-ppp luci-proto-qmi luci-proto-relay \
        luci-theme-material luci-theme-bootstrap luci-compat luci-lib-docker \
        luci-app-amlogic luci-app-ddns luci-app-dockerman luci-app-firewall luci-app-frpc luci-app-frps \
        luci-app-opkg luci-app-samba4 luci-app-transmission luci-app-ttyd luci-app-upnp luci-app-wol \
        "

    # Rebuild firmware
    make image PROFILE="Default" PACKAGES="${my_packages}"

    sync && sleep 3
    echo -e "${INFO} The rebuild result: $(ls bin/targets/*/* -l 2>/dev/null)"
    echo -e "${SUCCESS} The rebuild is successful, the current path: [ ${PWD} ]"
}

# Show welcome message
echo -e "${STEPS} Welcome to Rebuild OpenWrt Using the Image Builder."
[[ -x "${0}" ]] || error_msg "Please give the script permission to run: [ chmod +x $0 ]"
[[ -z "${1}" ]] && error_msg "Please specify the OpenWrt Branch, such as [ 21.02.3 ]"
rebuild_branch="${1}"
echo -e "${INFO} Rebuild path: [ ${PWD} ]"
echo -e "${INFO} Rebuild branch: [ ${rebuild_branch} ]"
#
# Perform related operations
download_imagebuilder
custom_packages
custom_files
rebuild_firmware
