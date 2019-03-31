#!/bin/bash
#
# Copyright 2016 Philip J Freeman <elektron@halo.nu>
#
#
# This file is part of Signalk-java
#
#  FreeBoard is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  FreeBoard is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with FreeBoard.  If not, see <http://www.gnu.org/licenses/>.
#
#
# This is a setup script to automate the installation of Signalk-java
# On Raspbian stretch.
#

# Use bash "strict mode" - http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail
IFS=$'\n\t'

# Freeboard source location
#FREEBOARD_CLONE_URL="https://github.com/rob42/freeboard-server.git"
#FREEBOARD_BRANCH=""

# To test another fork and branch:
#FREEBOARD_CLONE_URL="https://github.com/ph1l/freeboard-server.git"
#FREEBOARD_BRANCH="raspbian_stretch"

# helper functions

function yesno()
{
    local PROMPT=${1}
    local RESPONSE
    local OK=0

    while true; do
        read -p "${PROMPT} (y/n)? " RESPONSE
        if [ "${RESPONSE}" == "y" ]; then
		return 0
        elif [ "${RESPONSE}" == "n" ]; then
		return 1
	fi
    done
}

HAVE_RUN_APT_UPDATE=N

function ensure_package_installed()
{
    DO_INSTALL=N
    if ! dpkg -s ${1} > /dev/null 2>&1; then
        DO_INSTALL=Y
    else
        STATUS=$(dpkg -s ${1} | grep ^Status: | head -1 | awk '{print $4}')
        if [ "${STATUS}" != "installed" ]; then
            DO_INSTALL=Y
        fi
        # TODO: handle minimum version argument?
        #    VERSION=$(dpkg -s ${1} | grep ^Version: | head -1 | awk '{print $2}')
        #    if dpkg --compare-versions ${VERSION} lt ${2}; then
    fi

    if [ "${DO_INSTALL}" == "Y" ]; then
        if [ "${HAVE_RUN_APT_UPDATE}" == "N" ]; then
            sudo apt-get update
            HAVE_RUN_APT_UPDATE=Y
        fi
        sudo apt-get --assume-yes install ${1}
    fi
}

function ensure_alternative()
{
    if  update-alternatives --query ${1} > /dev/null; then
        CUR_LINK=$( update-alternatives --query ${1} | \
            grep '^Value:' | awk '{print $2}')
        if [ "${CUR_LINK}" != "${2}" ]; then
            sudo update-alternatives --remove-all ${1}
            sudo update-alternatives --install /usr/bin/${1} ${1} \
                ${2} 100
        fi
    else
        sudo update-alternatives --install /usr/bin/${1} ${1} \
            ${2} 100
    fi
}

function git_head_ref()
{
    git reflog show -1 HEAD | awk '{print $1}'
}

function system_enable_service()
{
    if ! sudo systemctl is-enabled ${1}; then
        sudo systemctl enable ${1}
    fi
}

function system_disable_service()
{
    if sudo systemctl is-enabled ${1}; then
        sudo systemctl disable ${1}
    fi
}

function system_stop_service()
{
    if sudo systemctl is-active ${1}; then
        sudo systemctl stop ${1}
    fi
}

# Warn the user before modifying anything
cat << EOF

               !!!WARNING!!!

You're about to set up this raspbian server to run the Artemis signalk server. This script will
modify your system to do just that. It's developed and tested to work on a
vanilla 'Raspbian Stretch - Lite' image.

You should have already:

  1) Run raspi-config to:

    * Change the password for your rasbian install

    * Expand the filesystem to make entire SD card space available

	* Setup internet access

  2) rebooted (to apply the filesystem change.)

EOF

if ! yesno "do you want to continue"; then
    exit 0
fi

#CAT << EOF
#
#BOAT MODE ?
#
#YOU CAN CONFIGURE YOUR PI TO HOST A CAPTIVE WIFI NETWORK FOR FREEBOARD. THIS HAS
#BEEN TESTED ON THE RASPBERRY PI 3 WITH THE BUILTIN WIFI INTERFACE.
#
#BOAT_NETWORK_IFACE = ${BOAT_NETWORK_IFACE}
#BOAT_NETWORK_ADDRESS = ${BOAT_NETWORK_ADDRESS}
#BOAT_NETWORK_NETMASK = ${BOAT_NETWORK_NETMASK}
#BOAT_NETWORK_MIN_DHCP = ${BOAT_NETWORK_MIN_DHCP}
#BOAT_NETWORK_MAX_DHCP = ${BOAT_NETWORK_MAX_DHCP}
#BOAT_NETWORK_WIFI_SSID = ${BOAT_NETWORK_WIFI_SSID}
#BOAT_NETWORK_WIFI_PASS = ${BOAT_NETWORK_WIFI_PASS}
#BOAT_NETWORK_WIFI_CHAN = ${BOAT_NETWORK_WIFI_CHAN}
#
#EOF
#
#IF YESNO "DO YOU WANT YOUR PI IN BOAT MODE"; THEN
#    DO_BOAT_NETWORK=Y
#ELSE
#    DO_BOAT_NETWORK=N
#FI

set -x # Turn on debug output

DO_REBOOT_SYSTEM=Y

STATIC_HOSTS_ENTRIES="127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters"

# Verify our running environment

## Raspbian Lite does not have lsb-release installed by default
ensure_package_installed "lsb-release"

LSB_ID=$(lsb_release -is)
LSB_CODENAME=$(lsb_release -cs)

## check lsb_release for Raspbian stretch
if [ "${LSB_ID}" != "Raspbian" -o "${LSB_CODENAME}" != "stretch" ]; then
    echo "distro ${LSB_ID} ${LSB_CODENAME} is not supported."
    exit 1
fi

sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install -y curl git build-essential dialog wget
sudo apt-get install -y libnss-mdns avahi-utils libavahi-compat-libdnssd-dev

# add ntp
sudo systemctl stop systemd-timesyncd
sudo systemctl disable systemd-timesyncd
sudo apt-get install -y ntp
sudo service ntp start

# routing
sudo apt-get install -y ifmetric
	
curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo apt update

sudo apt-get install -y influxdb
sudo sed -i 's/store-enabled = true/store-enabled = false/' /etc/influxdb/influxdb.conf
sudo service influxdb restart

if [ ! -f /tmp/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb ]; then
	wget -O /tmp/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb
fi

sudo apt-get install -y /tmp/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb
	
sudo apt-get install -y maven

## check running user is 'pi'
if [ "$(id -nu)" != "pi" ]; then
    echo "ERROR: script must be run as the 'pi' user"
    exit 1
fi

## change to HOME
cd ${HOME}
if [ ! -d signalk-java ];then
	git clone https://github.com/SignalK/signalk-java.git
	cd signalk-java
	git checkout master
else
	cd signalk-java
	git pull
	git checkout master
fi
cd ${HOME}
touch first_start

# setup freeboard server as a systemd service
pushd signalk-java

if ! diff systemd.signalk-java.environment /etc/default/signalk-java; then
    sudo cp systemd.signalk-java.environment /etc/default/signalk-java
fi

if ! diff systemd.signalk-java.service /etc/systemd/system/signalk-java.service; then
    sudo cp systemd.signalk-java.service /etc/systemd/system/signalk-java.service
    sudo systemctl daemon-reload
fi

popd

system_enable_service "signalk-java"

# make setup script in homedir a symlink to script in source
if [ ! -L ~/setup_raspbian.sh ]; then
    # rm ~/setup_raspbian.sh
    ln -s ~/signalk-java/setup_raspbian.sh ~/setup_raspbian.sh
fi

set +x # Turn off debug output

echo "The script has completed successfully."

if [ "${DO_REBOOT_SYSTEM}" == "Y" ]; then
    echo
    echo "Press ENTER to reboot"

    read # wait for user to hit enter

    sudo shutdown -r now
fi
