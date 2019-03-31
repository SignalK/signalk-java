Complete fresh manual install
=============================

See https://www.raspberrypi.org/documentation/installation/noobs.md

Download fresh raspbian lite (stretch)

Follow instructions on https://www.raspberrypi.org/documentation/installation/installing-images/ to load image to 8Gb SD card
Fit the SD card into the Raspberry Pi and boot it.

Log in to console (fit a screen and keyboard or remotely using ssh)

```
pi@raspberrypi:~ $ raspi-config
```
In the menu that appears use the arrow keys to select, and the [TAB] key to jump to the <ok> <cancel> options
Set the following:

```
      Localization>
	       Timezone: select your timezone
      Interfacing options>
	       Enable SSH: yes, you want ssh to start at boot time
      Advanced Options>	
	       Expand filesystem: yes
	       Memory split: 16
      Network>
		N2 WiFi>
			Country: Select your country (NZ for me, this must be set to something even if you dont have WiFi access)
			SSID: the name of your home wifi network, or blank
 	                Passphrase: the password for your wifi network, or blank
```
	
Update to latest
----------------
```
pi@raspberrypi:~ $ sudo apt-get update
pi@raspberrypi:~ $ sudo apt-get upgrade
```

Install helpful things
----------------------
```
pi@raspberrypi:~ $ sudo apt-get install -y curl git build-essential dialog wget
pi@raspberrypi:~ $ sudo apt-get install libnss-mdns avahi-utils libavahi-compat-libdnssd-dev
```

Install extra package sources
--------------------------
```
pi@raspberrypi:~ $ curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
pi@raspberrypi:~ $ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
pi@raspberrypi:~ $ echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

pi@raspberrypi:~ $ sudo apt update
```

Install essential packages
--------------------------
```
pi@raspberrypi:~ $ sudo apt-get install influxdb
pi@raspberrypi:~ $ sudo sed -i 's/store-enabled = true/store-enabled = false/' /etc/influxdb/influxdb.conf
pi@raspberrypi:~ $ sudo service influxdb start

pi@raspberrypi:~ $ sudo apt-get install maven

```

Install java jdk11  (this assumes a 32bit OS (eg Rasbian, you may want the 64bit image if you have a 64bit os)
-------------------------
```
pi@raspberrypi:~ $ wget -O /tmp/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb https://github.com/bell-sw/Liberica/releases/download/11.0.2/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb
pi@raspberrypi:~ $ sudo apt-get install  /tmp/bellsoft-jdk11.0.2-linux-arm32-vfp-hflt-lite.deb

```
Clone the signalk-java project
------------------------------
```
pi@raspberrypi:~ $ git clone https://github.com/SignalK/signalk-java.git
pi@raspberrypi:~ $ cd signalk-java
pi@raspberrypi:~ $ git checkout jdk11
```

Start signalk-java
--------------------
Use Cntrl-C to exit.
```
pi@raspberrypi:~/signalk-java $ export JAVA_HOME=/usr/lib/jvm/jdk-11-bellsoft-arm32-vfp-hflt
pi@raspberrypi:~/signalk-java $ mvn exec:exec
	If it fails,
  pi@raspberrypi:~/signalk-java $ rm -rf ~/.m2/repository/com/github/SignalK/artemis-server/
	and try 'mvn exec:exec' again
```
Adding apps can be done via the ui at https://[rpi_ip_address]:8443

Make it autostart at boot
-------------------------

pi@raspberrypi:~/signalk-java $ sudo cp systemd.signalk-java.environment /etc/default/signalk-java
pi@raspberrypi:~/signalk-java $ sudo cp systemd.signalk-java.service /etc/systemd/system/signalk-java.service
pi@raspberrypi:~/signalk-java $ sudo systemctl daemon-reload
pi@raspberrypi:~/signalk-java $ sudo systemctl enable signalk-java

Configure wifi hotspot and other services (optional)
------------------
```
pi@raspberrypi:~/signalk-java $ cd ~
pi@raspberrypi:~ $ sudo apt-get install dnsmasq hostapd
pi@raspberrypi:~ $ sudo systemctl stop dnsmasq
pi@raspberrypi:~ $ sudo systemctl stop hostapd

pi@raspberrypi:~ $ sudo nano /etc/dhcpcd.conf

	Enter:
		interface wlan0
				static ip_address=192.168.0.1/24
			nohook wpa_supplicant
	Cnrtl-X to save

pi@raspberrypi:~ $ sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig  
pi@raspberrypi:~ $ sudo nano /etc/dnsmasq.conf
	Enter:
		interface=wlan0      # Use the require wireless interface - usually wlan0
			dhcp-range=192.168.0.2,192.168.0.20,255.255.255.0,24h
	Cnrtl-X to save

pi@raspberrypi:~ $ sudo nano /etc/hostapd/hostapd.conf
	Enter:
		interface=wlan0
		driver=nl80211
		ssid=freeboard
		hw_mode=g
		channel=10
		wmm_enabled=0
		macaddr_acl=0
		auth_algs=1
		ignore_broadcast_ssid=0
		wpa=2
		wpa_passphrase=freeboard
		wpa_key_mgmt=WPA-PSK
		wpa_pairwise=TKIP
		rsn_pairwise=CCMP
	Cnrtl-X to save

pi@raspberrypi:~ $ sudo nano /etc/default/hostapd
	Find the line with #DAEMON_CONF, and replace it with this:
		DAEMON_CONF="/etc/hostapd/hostapd.conf"
	Cnrtl-X to save

pi@raspberrypi:~ $ sudo nano /etc/sysctl.conf 

	uncomment (remove #) for this line:

		net.ipv4.ip_forward=1
```

Add a masquerade for outbound traffic on eth0:
```
pi@raspberrypi:~ $ sudo iptables -t nat -A  POSTROUTING -o eth0 -j MASQUERADE
```
Save the iptables rule.
```
pi@raspberrypi:~ $ sudo sh -c "iptables-save > /etc/iptables.ipv4.nat"
```
Make it permanant at boot time
```
pi@raspberrypi:~ $ sudo nano /etc/rc.local
	Add this just above "exit 0" to install these rules on boot.
		iptables-restore < /etc/iptables.ipv4.nat
```

