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

if [[ $# -lt 2 ]] ; then
   echo 'Correct usage is: setup_network.sh [HOSTNAME] [boat network (Y|N)] [Wifi SSID] [Wifi PASSWORD]'
   echo '    eg: setup_network.sh freeboard Y freeboard passit'
   exit 1
fi

HOSTNAME=${1}
DO_BOAT_NETWORK=${2}
BOAT_NETWORK_WIFI_SSID=${3:-${HOSTNAME}}
BOAT_NETWORK_WIFI_PASS=${4:-${BOAT_NETWORK_WIFI_SSID}}

# check the pass is > 8
if [ ${#BOAT_NETWORK_WIFI_PASS} -lt 8 ];then
	BOAT_NETWORK_WIFI_PASS=${BOAT_NETWORK_WIFI_PASS}${BOAT_NETWORK_WIFI_PASS}
fi
if [ ${#BOAT_NETWORK_WIFI_PASS} -lt 8 ];then
	BOAT_NETWORK_WIFI_PASS=${BOAT_NETWORK_WIFI_PASS}${BOAT_NETWORK_WIFI_PASS}
fi
#echo "    running: setup_network.sh $HOSTNAME $DO_BOAT_NETWORK $BOAT_NETWORK_WIFI_SSID $BOAT_NETWORK_WIFI_PASS"
#exit 1

# Boat Network Defaults
BOAT_NETWORK_IFACE=wlan0
BOAT_ROAM_IFACE=wlan1
BOAT_NETWORK_ADDRESS=192.168.0.1
BOAT_NETWORK_NETMASK=255.255.255.0
BOAT_NETWORK_MIN_DHCP=192.168.0.10
BOAT_NETWORK_MAX_DHCP=192.168.0.128
BOAT_NETWORK_WIFI_CHAN=10

# helper functions

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



# TODO: allow user to override the boat network settings, and cache the overrides
# for next time

set -x # Turn on debug output

DO_RESTART_SERVICE=N
#DO_REBOOT_SYSTEM=N
DO_REBOOT_SYSTEM=Y
DO_RESTART_DNSMASQ=N
DO_RESTART_HOSTAPD=N

STATIC_HOSTS_ENTRIES="127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters"

HOSTAPD_DEFAULT="DAEMON_CONF=\"/etc/hostapd/hostapd.conf\""

HOSTAPD_CONFIG="interface=${BOAT_NETWORK_IFACE}
driver=nl80211
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0
ssid=${BOAT_NETWORK_WIFI_SSID}
hw_mode=g
channel=${BOAT_NETWORK_WIFI_CHAN}
ieee80211n=1
wpa=1
wpa_passphrase=${BOAT_NETWORK_WIFI_PASS}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
beacon_int=100
auth_algs=3
wmm_enabled=1"

DNSMASQ_CONFIG="interface=wlan0
dhcp-range=${BOAT_NETWORK_MIN_DHCP},${BOAT_NETWORK_MAX_DHCP},12h"

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

# routing
sudo apt-get install -y ifmetric

## check running user is 'pi'
if [ "$(id -nu)" != "pi" ]; then
    echo "ERROR: script must be run as the 'pi' user"
    exit 1
fi

## change to HOME
cd ${HOME}

# change the system's hostname
sudo cp /etc/hostname /etc/hostname.bak
echo "${HOSTNAME}" | sudo tee /etc/hostname > /dev/null
if ! diff /etc/hostname.bak /etc/hostname > /dev/null; then
	sudo hostname ${HOSTNAME}
    sudo hostnamectl set-hostname ${HOSTNAME}
	sudo systemctl restart avahi-daemon
    DO_REBOOT_SYSTEM=Y
fi

# Optionally Setup Boat Network
if [ "${DO_BOAT_NETWORK}" == "Y" ]; then

    ## TODO: validate wifi device supports master mode
	
    ## setup hosts file
    sudo cp /etc/hosts /etc/hosts.bak
    sudo tee /etc/hosts << EOF
# This file is managed by ${0}
${STATIC_HOSTS_ENTRIES}
${BOAT_NETWORK_ADDRESS} ${HOSTNAME} a.${HOSTNAME} b.${HOSTNAME} c.${HOSTNAME} d.${HOSTNAME} 

127.0.1.1 ${HOSTNAME} 
EOF

    if ! diff /etc/hosts.bak /etc/hosts > /dev/null; then
        DO_RESTART_DNSMASQ=Y
    fi

	## save a backup original rc.local file
    if [ ! -e /etc/rc.local.orig ]; then
        sudo cp /etc/rc.local /etc/rc.local.orig
    fi
    ## save a backup original interfaces file
    if [ ! -e /etc/network/interfaces.orig ]; then
        sudo cp /etc/network/interfaces /etc/network/interfaces.orig
    fi

	## Add rc.local
    if ! grep "^# This file is managed by signalk-java" /etc/rc.local > /dev/null; then
        echo '
#!/bin/sh -e
# This file is managed by signalk-java
# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
  printf \"My IP address is %s\n\" \"\$_IP\"
fi
#setup routing
sudo sh -c \"echo 1 > /proc/sys/net/ipv4/ip_forward\"
sudo iptables-restore < /etc/iptables.ipv4.nat
exit 0
' | sudo tee /etc/rc.local
	
	fi
	
    ## Add interface config
    if ! grep "^# This file is managed by signalk-java" /etc/network/interfaces > /dev/null; then
        sudo tee /etc/network/interfaces << EOF
# This file is managed by signalk-java

auto lo
iface lo inet loopback

allow-hotplug eth0
iface eth0 inet dhcp
    metric 20

allow-hotplug ${BOAT_NETWORK_IFACE}
iface ${BOAT_NETWORK_IFACE} inet static
    address ${BOAT_NETWORK_ADDRESS}
    netmask ${BOAT_NETWORK_NETMASK}
    
allow-hotplug ${BOAT_ROAM_IFACE}
iface ${BOAT_ROAM_IFACE} inet manual
   wpa-roam /etc/wpa_supplicant/wpa_supplicant.conf
   metric 10
iface default inet dhcp
EOF
    fi

    ## ensure required packages are installed
    ensure_package_installed dnsmasq
    ensure_package_installed hostapd

    ## configure dnsmasq
    if [ "${DNSMASQ_CONFIG}" != "$(cat /etc/dnsmasq.d/signalk-java.conf)" ]; then
        echo "${DNSMASQ_CONFIG}" | sudo tee /etc/dnsmasq.d/signalk-java.conf
        DO_RESTART_DNSMASQ=Y
    fi

    ## configure hostapd
    if [ "${HOSTAPD_CONFIG}" != "$(cat /etc/hostapd/hostapd.conf)" ]; then
        echo "${HOSTAPD_CONFIG}" | sudo tee /etc/hostapd/hostapd.conf
        DO_RESTART_HOSTAPD=Y
    fi

    if [ "${HOSTAPD_DEFAULT}" != "$(cat /etc/default/hostapd)" ]; then
        echo "${HOSTAPD_DEFAULT}" | sudo tee /etc/default/hostapd
        DO_RESTART_HOSTAPD=Y
    fi
	# setup routing
	sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
	
	sudo iptables -t nat -A POSTROUTING -o wlan1 -j MASQUERADE  
	sudo iptables -A FORWARD -i wlan1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT  
	sudo iptables -A FORWARD -i wlan0 -o wlan1 -j ACCEPT
		
	sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
		# insert into rclocal
		#iptables-restore < /etc/iptables.ipv4.nat 
		
    ## enable network daemons
    sudo systemctl unmask hostapd.service
    system_enable_service "hostapd" # Note: Due to a bug in debian stretch, this
                                    # enable service triggers each time you run
                                    # the script. This does not cause a failure
                                    # other than the output:
                                    #
                                    # + sudo systemctl is-enabled hostapd
                                    # Failed to get unit file state for hostapd.service: No such file or directory
                                    # - https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=751638

    system_enable_service "dnsmasq"
    ## do network daemon restarts, if requested
    if [ "${DO_RESTART_DNSMASQ}" == "Y" ]; then
        sudo systemctl restart dnsmasq
    fi
    if [ "${DO_RESTART_HOSTAPD}" == "Y" ]; then
        sudo systemctl restart hostapd
    fi

else

    ## bring down wireless
    if sudo ifquery --state ${BOAT_NETWORK_IFACE} > /dev/null; then
        sudo ifdown ${BOAT_NETWORK_IFACE}
    fi

    ## disable and stop network daemons
    system_stop_service "hostapd" # Note: see note above ^^ near
                                  # system_enable_service "hostapd"
    system_disable_service "hostapd"
    system_stop_service "dnsmasq"
    system_disable_service "dnsmasq"

	if [ -e /etc/rc.local.orig ]; then
        sudo mv /etc/rc.local.orig /etc/rc.local
    fi
    ## Revert to default network settings
    if [ -e /etc/network/interfaces.orig ]; then
        sudo mv /etc/network/interfaces.orig /etc/network/interfaces
    fi

    ## setup hosts file
    sudo cp /etc/hosts /etc/hosts.bak
    sudo tee /etc/hosts << EOF
# This file is managed by ${0}
${STATIC_HOSTS_ENTRIES}
 
127.0.1.1 ${HOSTNAME}
EOF

fi # End if DO_BOAT_NETWORK

# make setup script in homedir a symlink to script in source
if [ ! -L ~/setup_network.sh ]; then
    # rm ~/setup_raspbian.sh
    ln -s ~/signalk-java/setup_network.sh ~/setup_network.sh
fi

set +x # Turn off debug output

echo "The script has completed successfully."

if [ "${DO_REBOOT_SYSTEM}" == "Y" ]; then
    echo
    echo "Press ENTER to reboot or CTRL-c to cancel"

    read -t 10# wait for user to hit enter

    sudo shutdown -r now

fi
