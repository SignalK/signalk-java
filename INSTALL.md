Complete fresh manual install
=============================

Download fresh raspbian lite

Follow instructions on https://www.raspberrypi.org/documentation/installation/installing-images/linux.md to load image to 8Gb SD card

Log in to console (using ssh)

pi@raspberrypi:~ $ raspi-config

	-"Interfacing Options" 
		setup remote ssh
		Set Overclock too high
	-"Advanced Settings"
		expand root filesystem
		set GPU ram to 16Mb
	- exit
	
Update to latest
----------------
```
pi@raspberrypi:~ $ sudo apt-get update
pi@raspberrypi:~ $ sudo apt-get upgrade
```

Install latest java 8
---------------------

Follow the instructions at https://gist.github.com/ribasco/fff7d30b31807eb02b32bcf35164f11f

Install helpful things
----------------------
```
pi@raspberrypi:~ $ sudo apt-get install -y curl git build-essential dialog
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
pi@raspberrypi:~ $ sudo apt install nodejs
pi@raspberrypi:~ $ sudo apt-get install libnss-mdns avahi-utils libavahi-compat-libdnssd-dev
pi@raspberrypi:~ $ sudo apt-get install libaio1
pi@raspberrypi:~ $ sudo apt-get install oracle-java8-jdk
pi@raspberrypi:~ $ sudo apt-get install influxdb
pi@raspberrypi:~ $ sudo apt-get install maven
pi@raspberrypi:~ $ sudo apt-get install dnsmasq hostapd
```
Configure services
------------------
```
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
Install signalk-java
--------------------
```
pi@raspberrypi:~ $ git clone https://github.com/SignalK/signalk-java.git
pi@raspberrypi:~ $ cd signalk-java
pi@raspberrypi:~ $ git checkout artemis
pi@raspberrypi:~ $ mvn exec:java
	If it fails,
  pi@raspberrypi:~ $ rm -rf ~/.m2/repository/com/github/SignalK/artemis-server/
	and try 'mvn exec:java' again
```
Adding apps can be done via the ui at http://[rpi_ip_address]:8080
