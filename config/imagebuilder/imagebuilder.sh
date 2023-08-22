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
# Copyright (C) 2021~ https://github.com/unifreq/openwrt_packit
# Copyright (C) 2021~ https://github.com/ophub/amlogic-s9xxx-openwrt
# Copyright (C) 2021~ https://downloads.openwrt.org/releases
# Copyright (C) 2023~ https://downloads.immortalwrt.org/releases
#
# Download from: https://downloads.openwrt.org/releases
#                https://downloads.immortalwrt.org/releases
#
# Documentation: https://openwrt.org/docs/guide-user/additional-software/imagebuilder
# Instructions:  Download OpenWrt firmware from the official OpenWrt,
#                Use Image Builder to add packages, lib, theme, app and i18n, etc.
#
# Command: ./config/imagebuilder/imagebuilder.sh <source:branch>
#          ./config/imagebuilder/imagebuilder.sh openwrt:21.02.3
#
#======================================== Functions list ========================================
#
# error_msg               : Output error message
# download_imagebuilder   : Downloading OpenWrt ImageBuilder
# adjust_settings         : Adjust related file settings
# custom_packages         : Add custom packages
# custom_config           : Add custom config
# custom_files            : Add custom files
# rebuild_firmware        : rebuild_firmware
#
#================================ Set make environment variables ================================
#
# Set default parameters
make_path="${PWD}"
openwrt_dir="GTwrt"
imagebuilder_path="${make_path}/${openwrt_dir}"
custom_files_path="${make_path}/config/imagebuilder/files"
custom_config_file="${make_path}/config/imagebuilder/config"

# Set default parameters
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
WARNING="[\033[93m WARNING \033[0m]"
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
    cd ${make_path}
    echo -e "${STEPS} Start downloading OpenWrt files..."

    # Determine the target system (Imagebuilder files naming has changed since 23.05.0)
    if [[ "${op_branch:0:2}" -ge "23" && "${op_branch:3:2}" -ge "05" ]]; then
        target_system="armsr/armv8"
        target_name="armsr-armv8"
        target_profile=""
    else
        target_system="armvirt/64"
        target_name="armvirt-64"
        target_profile="Default"
    fi

    # Downloading imagebuilder files
    download_file="https://downloads.openwrt.org/releases/23.05.0-rc3/targets/armvirt/64-imagebuilder-23.05.0-rc3-armvirt-64.Linux-x86_64.tar.xz"
    wget -q ${download_file}
    [[ "${?}" -eq "0" ]] || error_msg "Wget download failed: [ ${download_file} ]"

    # Unzip and change the directory name
    tar -xJf *-imagebuilder-* && sync && rm -f *-imagebuilder-*.tar.xz
    mv -f *-imagebuilder-* ${openwrt_dir}

    sync && sleep 3
    echo -e "${INFO} [ ${make_path} ] directory status: $(ls . -l 2>/dev/null)"
}

# Adjust related files in the ImageBuilder directory
adjust_settings() {
    cd ${imagebuilder_path}
    echo -e "${STEPS} Start adjusting .config file settings..."

    # For .config file
    if [[ -s ".config" ]]; then
        # Root filesystem archives
        sed -i "s|CONFIG_TARGET_ROOTFS_CPIOGZ=.*|# CONFIG_TARGET_ROOTFS_CPIOGZ is not set|g" .config
        # Root filesystem images
        sed -i "s|CONFIG_TARGET_ROOTFS_EXT4FS=.*|# CONFIG_TARGET_ROOTFS_EXT4FS is not set|g" .config
        sed -i "s|CONFIG_TARGET_ROOTFS_SQUASHFS=.*|# CONFIG_TARGET_ROOTFS_SQUASHFS is not set|g" .config
        sed -i "s|CONFIG_TARGET_IMAGES_GZIP=.*|# CONFIG_TARGET_IMAGES_GZIP is not set|g" .config
    else
        error_msg "There is no .config file in the [ ${download_file} ]"
    fi

    # For other files
    # ......

    sync && sleep 3
    echo -e "${INFO} [ openwrt ] directory status: $(ls -al 2>/dev/null)"
}

# Set ssid
sed -i "s/ImmortalWrt/KarnadiWrt/g" package/kernel/mac80211/files/lib/wifi/mac80211.sh

# Set timezone
sed -i -e "s/CST-8/WIB-7/g" -e "s/Shanghai/Jakarta/g" package/emortal/default-settings/files/99-default-settings-chinese

# Set hostname
sed -i "s/ImmortalWrt/KarnadiWrt/g" package/base-files/files/bin/config_generate

# Set Interface
sed -i "9 i\uci set network.wana=interface\nuci set network.wana.proto='3g'\nuci set network.wana.device='/dev/ttyUSB1'\nuci set network.wana.service='LTE'\nuci set network.wana.apn='internet'\nuci set network.wana.ipv6='auto'\nuci set network.wanb=interface\nuci set network.wanb.proto='dhcp'\nuci set network.wanb.device='eth0.10'\nuci set network.wanc=interface\nuci set network.wanc.proto='dhcp'\nuci set network.wanc.device='usb0'\nuci set network.@device[0].ports='eth0' 'eth0.100' 'eth0.200' 'eth0.300'\nuci commit network" package/emortal/default-settings/files/99-default-settings
sed -i "23 i\uci add_list firewall.@zone[1].network='wana'\nuci add_list firewall.@zone[1].network='wanb'\nuci add_list firewall.@zone[1].network='wanc'\nuci commit firewall\n" package/emortal/default-settings/files/99-default-settings

# Set shell zsh
sed -i "s/\/bin\/ash/\/usr\/bin\/zsh/g" package/base-files/files/etc/passwd

# Set php7 max_size
# sed -i -e "s/upload_max_filesize = 2M/upload_max_filesize = 1024M/g" -e "s/post_max_size = 8M/post_max_size = 1024M/g" feeds/packages/lang/php7/files/php.ini

#=================================
# Utility App
#=================================
# Add luci-app-amlogic
svn co https://github.com/ophub/luci-app-amlogic/trunk/luci-app-amlogic package/luci-app-amlogic

# Add p7zip
svn co https://github.com/hubutui/p7zip-lede/trunk package/p7zip

# Add luci-app-tinyfilemanager
# svn co https://github.com/lynxnexy/luci-app-tinyfilemanager/trunk package/luci-app-tinyfilemanager
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-tinyfm package/luci-app-tinyfm
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-libernet-plus package/luci-app-libernet-plus
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-libernet-bin package/luci-app-libernet-bin
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-mulimiter package/luci-app-mulimiter
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-myxllite package/luci-app-myxllite
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-netmon package/luci-app-netmon
svn co https://github.com/helmiau/helmiwrt-packages/trunk/luci-app-openspeedtest package/luci-app-openspeedtest
svn co https://github.com/helmiau/helmiwrt-packages/trunk/badvpn package/badvpn
svn co https://github.com/helmiau/helmiwrt-packages/trunk/corkscrew package/corkscrew

rm -rf feeds/luci/applications/luci-app-filebrowser
svn co https://github.com/happy902/luci-app-filebrowser/trunk package/luci-app-filebrowser

# Add luci-app-adguardhome
svn co https://github.com/rufengsuixing/luci-app-adguardhome/trunk package/luci-app-adguardhome

# Set adguardhome-core
mkdir -p files/usr/bin/AdGuardHome
AGH_CORE=$(curl -sL https://api.github.com/repos/AdguardTeam/AdGuardHome/releases | grep /AdGuardHome_linux_arm64 | awk -F '"' '{print $4}' | sed -n '1p')
wget -qO- $AGH_CORE | tar xOvz > files/usr/bin/AdGuardHome/AdGuardHome
chmod +x files/usr/bin/AdGuardHome/AdGuardHome

# Set yt-dlp
mkdir -p files/bin
curl -sL https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o files/bin/yt-dlp
chmod +x files/bin/yt-dlp

# Set speedtest
mkdir -p files/bin
wget -qO- https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz | tar xOvz > files/bin/speedtest
chmod +x files/bin/speedtest

#================================
# Injek/Vpn/Bypass App
#================================
# Add luci-app-openclash
rm -rf feeds/luci/applications/luci-app-openclash
svn co https://github.com/vernesong/OpenClash/trunk/luci-app-openclash package/luci-app-openclash
pushd package/luci-app-openclash/tools/po2lmo
make && sudo make install
popd

# Set clash-core
mkdir -p files/etc/openclash/core
# VERNESONG_CORE=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/Clash | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
# VERNESONG_TUN=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/TUN-Premium | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
# VERNESONG_GAME=$(curl -sL https://api.github.com/repos/vernesong/OpenClash/releases/tags/TUN | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
DREAMACRO_CORE=$(curl -sL https://api.github.com/repos/Dreamacro/clash/releases | grep /clash-linux-armv8 | awk -F '"' '{print $4}' | sed -n '1p')
DREAMACRO_TUN=$(curl -sL https://api.github.com/repos/Dreamacro/clash/releases/tags/premium | grep /clash-linux-armv8 | awk -F '"' '{print $4}')
META_CORE=$(curl -sL https://api.github.com/repos/MetaCubeX/Clash.Meta/releases | grep /Clash.Meta-linux-arm64-v | awk -F '"' '{print $4}' | sed -n '1p')
# wget -qO- $VERNESONG_CORE | tar xOvz > files/etc/openclash/core/clash_vernesong
# wget -qO- $VERNESONG_TUN | gunzip -c > files/etc/openclash/core/clash_tun_vernesong
# wget -qO- $VERNESONG_GAME | tar xOvz > files/etc/openclash/core/clash_game_vernesong
wget -qO- $DREAMACRO_CORE | gunzip -c > files/etc/openclash/core/clash
wget -qO- $DREAMACRO_TUN | gunzip -c > files/etc/openclash/core/clash_tun
wget -qO- $META_CORE | gunzip -c > files/etc/openclash/core/clash_meta
chmod +x files/etc/openclash/core/clash*

# Set v2ray-rules-dat
mkdir -p files/etc/openclash
curl -sL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geosite.dat -o files/etc/openclash/GeoSite.dat
curl -sL https://github.com/Loyalsoldier/v2ray-rules-dat/releases/latest/download/geoip.dat -o files/etc/openclash/GeoIP.dat

#================================
# Monitoring
#================================
# User online cek

svn co https://github.com/haiibo/openwrt-packages/trunk/luci-app-onliner package/luci-app-onliner
svn co https://github.com/brvphoenix/luci-app-wrtbwmon/trunk/luci-app-wrtbwmon package/luci-app-wrtbwmon
svn co https://github.com/brvphoenix/wrtbwmon/trunk/wrtbwmon package/wrtbwmon
#cat
# rm -rf feeds/luci/applications/luci-app-netdata
sed -i 's/10.*/10.* 11.* 192.168.* 172.16.* 172.17.* 172.18.* 172.19.* 172.20.* 172.21.* 172.22.* 172.23.* 172.24.* 172.25.* 172.26.* 172.27.* 172.28.* 172.29.* 172.30.* 172.31.*/g' package/feeds/packages/netdata/files/netdata.conf
# git clone --depth 1 https://github.com/karnadii/luci-app-netdata feeds/luci/applications/luci-app-netdata

#================================
## Modem Tool
#================================
# Rooter Support untuk modem rakitan
svn co https://github.com/karnadii/rooter/trunk/package/rooter-builds/0protocols/luci-proto-3x package/luci-proto-3x
svn co https://github.com/karnadii/rooter/trunk/package/rooter-builds/0protocols/luci-proto-mbim package/luci-proto-mbim
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0drivers/rmbim package/rmbim
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0drivers/rqmi package/rqmi
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0basicsupport/ext-sms package/ext-sms
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0basicsupport/ext-buttons package/ext-buttons
svn co https://github.com/karnadii/rooter/trunk/package/rooter/ext-rooter-basic package/ext-rooter-basic
# Rooter splash
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0splash/status package/status
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0splash/splash package/splash
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0splash/ext-splashconfig package/ext-splashconfig
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0splash/ext-splash package/ext-splash
# Rooter Bandwith monitor
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0optionalapps/bwallocate package/bwallocate
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0optionalapps/bwmon package/bwmon
svn co https://github.com/karnadii/rooter/trunk/package/rooter/0optionalapps/ext-throttle package/ext-throttle

# disable banner from rooter
sudo chmod -x package/ext-rooter-basic/files/etc/init.d/bannerset
sed -i 's/luci-theme-openwrt-2020/luci-theme-argon/g' package/ext-rooter-basic/Makefile
# Add luci-app-3ginfo
# svn co https://github.com/lynxnexy/luci-app-3ginfo/trunk package/luci-app-3ginfo
# Add luci-app-atinout-mod
svn co https://github.com/lynxnexy/luci-app-atinout-mod/trunk package/luci-app-atinout-mod

# internet detector
svn co https://github.com/gSpotx2f/luci-app-internet-detector/trunk/luci-app-internet-detector package/luci-app-internet-detector
svn co https://github.com/gSpotx2f/luci-app-internet-detector/trunk/internet-detector package/internet-detector

# git clone https://github.com/tmn505/openwrt-dvb package/openwrt-dvb

# iStore
svn co https://github.com/linkease/istore-ui/trunk/app-store-ui package/app-store-ui
svn co https://github.com/linkease/istore/trunk/luci package/istore

#================================
## MISC
#================================
# Set oh-my-zsh
mkdir -p files/root
pushd files/root
git clone https://github.com/robbyrussell/oh-my-zsh ./.oh-my-zsh
git clone https://github.com/zsh-users/zsh-autosuggestions ./.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ./.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions ./.oh-my-zsh/custom/plugins/zsh-completions
cp ${GITHUB_WORKSPACE}/amlogic-s9xxx/common-files/patches/zsh/.zshrc .
cp ${GITHUB_WORKSPACE}/amlogic-s9xxx/common-files/patches/zsh/example.zsh ./.oh-my-zsh/custom/example.zsh
popd

# Set modemmanager to disable
mkdir -p feeds/luci/protocols/luci-proto-modemmanager/root/etc/uci-defaults
cat << EOF > feeds/luci/protocols/luci-proto-modemmanager/root/etc/uci-defaults/70-modemmanager
[ -f /etc/init.d/modemmanager ] && /etc/init.d/modemmanager disable
exit 0
EOF

# Openclash Config Editor by Tiny File Manager
# Copyright 2022 by lynxnexy <https://github.com/lynxnexy/immortalwrt>
# 

cat << EOF > package/luci-app-openclash/luasrc/view/openclash/editor.htm
<%+header%>
<div class="cbi-map">
<iframe id="editor" style="width: 100%; min-height: 100vh; border: none; border-radius: 2px;"></iframe>
</div>
<script type="text/javascript">
document.getElementById("editor").src = "http://" + window.location.hostname + "/tinyfm/tinyfm.php?p=etc/openclash";
</script>
<%+footer%>
EOF

sed -i "s/yacd/Yet Another Clash Dashboard/g" package/luci-app-openclash/root/usr/share/openclash/ui/yacd/manifest.webmanifest
sed -i '94s/80/90/g' package/luci-app-openclash/luasrc/controller/openclash.lua
sed -i '94 i\	entry({"admin", "services", "openclash", "editor"}, template("openclash/editor"),_("Config Editor"), 80).leaf = true' package/luci-app-openclash/luasrc/controller/openclash.lua
# All process completed
wait
