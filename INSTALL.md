Complete fresh manual install
=============================

Download fresh raspbian lite (stretch)

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

Install helpful things
----------------------
```
pi@raspberrypi:~ $ sudo apt-get install -y curl git build-essential dialog
pi@raspberrypi:~ $ sudo apt-get install libnss-mdns avahi-utils libavahi-compat-libdnssd-dev
```
Clone the signalk-java project
------------------------------
```
pi@raspberrypi:~ $ git clone https://github.com/SignalK/signalk-java.git
pi@raspberrypi:~ $ cd signalk-java
pi@raspberrypi:~/signalk-java $ git checkout artemis
```

Install extra package sources
--------------------------
```
pi@raspberrypi:~/signalk-java $ curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
pi@raspberrypi:~/signalk-java $ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
pi@raspberrypi:~/signalk-java $ echo "deb https://repos.influxdata.com/debian stretch stable" | sudo tee /etc/apt/sources.list.d/influxdb.list

pi@raspberrypi:~/signalk-java $ sudo apt-key add webupd8-key.txt 
pi@raspberrypi:~/signalk-java $ sudo echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | sudo tee /etc/apt/sources.list.d/webupd8team-java.list
pi@raspberrypi:~/signalk-java $ echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | sudo tee -a /etc/apt/sources.list.d/webupd8team-java.list

pi@raspberrypi:~/signalk-java $ sudo apt update
```

Install essential packages
--------------------------
```
pi@raspberrypi:~/signalk-java $ sudo apt-get install oracle-java8-jdk
pi@raspberrypi:~/signalk-java $ sudo apt-get install influxdb
pi@raspberrypi:~/signalk-java $ sudo apt-get install maven

```

Start signalk-java
--------------------
Use Cntrl-C to exit.
```
pi@raspberrypi:~/signalk-java $ mvn exec:java
	If it fails,
  pi@raspberrypi:~/signalk-java $ rm -rf ~/.m2/repository/com/github/SignalK/artemis-server/
	and try 'mvn exec:java' again
```
Adding apps can be done via the ui at http://[rpi_ip_address]:8080


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

