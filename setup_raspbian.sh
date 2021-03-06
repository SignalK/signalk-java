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

# NOTE WELL: The date Must be correct of various commands fail!
echo "The date MUST be correct or failures will occur"
echo "Current System Time:"
date

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
else
	NOW=`date`
	if ! yesno "Is the system time correct (note timezone): ${NOW} ?"; then
		read -p "Enter current date/time as (YYYY-MM-DDTHH:MM:SS), eg 2019-04-07T15:35:00 : " DATE_TIME	
		sudo date -s ${DATE_TIME}
		NOW=`date`
		if ! yesno "Is the system time correct (note timezone): ${NOW} ?"; then
			echo "The date MUST be correct to install successfully, please try again"
    		exit 0
    	fi
    fi

fi


if yesno "Do you have a hardware (RTC) clock module"; then
	DO_RTC=Y
	cat << EOF
	RTC chip type selection. 
	
	The chip type will be on the documentation with the RTC module
	or on the module itself (on the chip).
	
EOF
	PS3='Enter selection: '
	options=("ds1307" "pcf8523" "ds3231" "Quit")
	select opt in "${options[@]}"
	do
	    case $opt in
	        "ds1307")
	        	RTC_CHIP=ds1307
	        	break
	            ;;
	        "pcf8523")
	            RTC_CHIP=pcf8523
	            break
	            ;;
	        "ds3231")
	            RTC_CHIP=ds3231
	            break
	            ;;
	        "Quit")
	            break
	            ;;
	        *) echo "invalid option $REPLY";;
	    esac
	done
   echo "Selected ${RTC_CHIP}";
else
    DO_RTC=N
fi

set -x # Turn on debug output

DO_REBOOT_SYSTEM=Y

########
STATIC_HOSTS_ENTRIES="127.0.0.1       localhost
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters"
########

########
HW_CLOCK_SET="
#!/bin/sh
# Reset the System Clock to UTC if the hardware clock from which it
# was copied by the kernel was in localtime.

dev=\$1

#if [ -e /run/systemd/system ] ; then
#    exit 0
#fi

if [ -e /run/udev/hwclock-set ]; then
    exit 0
fi

if [ -f /etc/default/rcS ] ; then
    . /etc/default/rcS
fi

# These defaults are user-overridable in /etc/default/hwclock
BADYEAR=no
HWCLOCKACCESS=yes
HWCLOCKPARS=
HCTOSYS_DEVICE=rtc0
if [ -f /etc/default/hwclock ] ; then
    . /etc/default/hwclock
fi

if [ yes = \"\$BADYEAR\" ] ; then
    /sbin/hwclock --rtc=\$dev --systz --badyear
    /sbin/hwclock --rtc=\$dev --hctosys --badyear
else
    /sbin/hwclock --rtc=\$dev --systz
    /sbin/hwclock --rtc=\$dev --hctosys
fi

# Note 'touch' may not be available in initramfs
> /run/udev/hwclock-set
"
########

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
#force time sync
sudo service ntp stop
sudo ntpd -gq
sudo service ntp start

# routing
sudo apt-get install -y ifmetric
	
if [ "${DO_RTC}" == "Y" ]; then
    # setup hwclock
    sudo apt-get install python-smbus i2c-tools
	# Add one of these to /boot/config.txt
	# remove any current drivers
	sudo sed -i 's/dtoverlay=i2c-rtc,ds1307//' /boot/config.txt
	sudo sed -i 's/dtoverlay=i2c-rtc,pcf8523//' /boot/config.txt
	sudo sed -i 's/dtoverlay=i2c-rtc,ds3231//' /boot/config.txt	 
    echo "dtoverlay=i2c-rtc,${RTC_CHIP}" >> /boot/config.txt
    
    sudo apt-get -y remove fake-hwclock
    sudo update-rc.d -f fake-hwclock remove
    
    # rewrite /lib/udev/hwclock-set
    if [ ! -e /lib/udev/hwclock-set.orig ]; then
    	sudo cp /lib/udev/hwclock-set /lib/udev/hwclock-set.orig
 	fi
    echo "${HW_CLOCK_SET}" | sudo tee /lib/udev/hwclock-set

    #set RTC time
    sudo hwclock -w
else
	# remove any current drivers
	sudo sed -i 's/dtoverlay=i2c-rtc,ds1307//' /boot/config.txt
	sudo sed -i 's/dtoverlay=i2c-rtc,pcf8523//' /boot/config.txt
	sudo sed -i 's/dtoverlay=i2c-rtc,ds3231//' /boot/config.txt
	sudo apt-get -y install fake-hwclock
	if [ -e /lib/udev/hwclock-set.orig ]; then
		sudo cp /lib/udev/hwclock-set.orig /lib/udev/hwclock-set
	fi
fi

curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

sudo apt update

sudo apt-get install -y influxdb=1.7.6-1

sudo sed -i 's/store-enabled = true/store-enabled = false/' /etc/influxdb/influxdb.conf
sudo sed -i 's/log-enabled = true/log-enabled = false/' /etc/influxdb/influxdb.conf
sudo sed -i 's/# log-enabled = false/log-enabled = false/' /etc/influxdb/influxdb.conf
	#max-connection-limit = 0
	#max-enqueued-write-limit = 0
	#enqueued-write-timeout = 3s
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
