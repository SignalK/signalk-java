Signal K java
=================================================

A Signal K server setup for easy deployment onto an RPi, or any Debian based Linux PC. 

Other linux types should be simple, just use the appropriate package manager instead of apt.

Its also possible (and should be quite simple) on a windows PC, but you have to manually install java, git, and maven as Windows doesnt have the kind of package management common to linux.

Provided under an Apache 2 licence

New Artemis Server
==================
The old signalk-java server began long before signalk, and has changed so much its become too difficult to maintain. Its replaced by the Artemis server  (https://github.com/SignalK/artemis-server).

To install the new artemis server, you need to switch to the artemis branch (https://github.com/SignalK/signalk-java/tree/artemis and follow the README.)

The rest of this doc is for the old server install

Security
========
**NOTE:**This version starts implementing security features!. The impact so far is that you will need to be on the same local network to be able to use the web configuration features. This can be adjusted to suit by altering DENY, CONFIG and WHITE list ip addresses.

**NOTE:** There is now a admin login. Its hard-wired to "admin" and "s3cr3t" for now.

Install on RPi
--------------
See also https://github.com/SignalK/specification/wiki/Raspberry-Pi-Installation-(Java-Server)

Quickstart
----------

In summary we already have java jdk8 on the pi, so we will install  git and maven.

The pi must be connected to the internet for the install. This was tested with a std Raspbian Jessie image.
Open a console on the RPI, or ssh onto it. Log in as user pi. At the command prompt execute the following:

```shell
$ cd ~

$ sudo apt-get update
$ sudo apt-get install git maven
//make sure to select sun jdk8 here - its much faster
$ sudo update-alternatives --config java
$ git clone https://github.com/SignalK/signalk-java.git
$ cd signalk-java

[ARTEMIS]   $ git checkout artemis
		    $ sudo apt install apt-transport-https
		  
		    $ curl -sL https://repos.influxdata.com/influxdb.key | sudo apt-key add -
			$ lsb_release -a  
				This gives us the OS version could be wheezy, jessie, stretch..
				
			For jessie or Debian 8.0
				$ echo "deb https://repos.influxdata.com/debian jessie stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
							
			For wheezy or Debian 7.0
				$ echo "deb https://repos.influxdata.com/debian wheezy stable" | sudo tee /etc/apt/sources.list.d/influxdb.list
			
			Then
			$ sudo apt update
			$ sudo apt-get install influxdb
			
		You can start it immediately so we can continue setting up the server
			$ sudo service influxdb start
				
$ mvn exec:java

//there is a script that sets up your wifi, dns, and server auto-start.
//its a bit troublesome at present, so YMMV
$ chmod 755 setup_raspbian.sh
$ ./setup_raspbian.sh
```
Now open a modern web browser (eg not IE) to `http://[ip_address_of_the_pi]:8080`
You should get a pretty start page! 

Go to the 'server' tab and install the 3 apps (Freeboard-sk, Instrument Panel, Sailgauge)
Go to configuration and turn on the demo. (Click the 'Configuration' button, change the Demo mode Start option to true. Clicking anywhere out of the field will automatically save the change.)

Then stop the server, use Cntrl-C to stop the server, it takes 10 secs or so. On the RPi you can simply turn off the power.
Restart by rebooting or:

$ sudo systemctl start signalk-java

After the restart you should find:
* webserver on `http://localhost:8080` if you have a screen and keyboard on the pi, otherwise `http://[ip_address_of_the_pi]:8080` 
	* REST api on `http://localhost:8080/signalk/v1/api/`
	* Authentication on `http://localhost:8080/signalk/v1/auth` - but its a pass all for now so you dont need to login
* websockets server on `http://localhost:3000`. 
* signalk output streamed as TCP over port 55555. On linux you can watch this with `$ ncat localhost 55555` **see below for subscriptions
* signalk output streamed as UDP over port 55554.
* nmea output will be streamed as TCP over port 55557. On linux you can watch this with `$ ncat localhost 55557`, or use telnet to connect.
* nmea output will be streamed as UDP over port 55556.

Try the apps. (Sailgauge is broken at present, expect a fix shortly.)

It will be streaming a demo file of some sailing in San Francisco. The output includes AIS data.  It may take a few minutes to bring up the vessel, or you may need a second restart. If you edit the configuration and make demo=false (default=true), then it will stop doing that.

Control logging by using the 'Log Configuration' button on the index page, or editing conf/log4j2.json. 

Upload your charts using the 'Upload Charts' button. The format is the zip file output by the freeboard-installer (https://github.com/rob42/freeboard-installer)



Using the server for your own client
------------------------------------

Normally the server only sends output in signalk delta format to subscribed clients, so clients MUST subscribe or you see only the heartbeat message every 1000ms.
You can subscribe by sending the following json. It supports * and ? wildcards :
```
{"context":"vessels.self","subscribe":[{"path":"environment.depth.belowTransducer"},{"path":"navigation.position"}]}
``` 
Then you will see those values every 1000ms.

Try:
```
{"context":"vessels.366982320","subscribe":[{"path":"navigation.position"}]}
{"context":"vessels.366982320","unsubscribe":[{"path":"navigation.position"}]}

{"context":"vessels.*","subscribe":[{"path":"navigation.position"}]}

{"context":"vessels.366982320","subscribe":[{"path":"navigation.position"}]}
{"context":"vessels.366982320","unsubscribe":[{"path":"navigation.position"}]}

{"context":"vessels.*","subscribe":[{"path":"navigation.position.l*"}]}
{"context":"vessels.*","unsubscribe":[{"path":"navigation.position.l*"}]}

{"context":"vessels.*","subscribe":[{"path":"navigation.course*"}]}
{"context":"vessels.*","unsubscribe":[{"path":"navigation.course*"}]}

``` 

Devices (aka GPS) attached on serial>USB adaptors will be automatically found and used. The input can be NMEA0183 compatible, or signalk, and expects 38400 baud by default. The configuration can be changed by editing the configuration


Installation for Windows
------------------------

You will need Java 1.8+ installed, maven3 (https://maven.apache.org/install.html), and git (https://git-scm.com/downloads). 
You need to be able to type 'java' on the command line and get java responding, same for maven and git.

Thats all the prep, then open a command console:
```
C:\dev> git clone https://github.com/SignalK/signalk-java.git
C:\dev\> cd signalk-java
C:\dev\signalk-java> mvn exec:java
```

NOTE: Windows users - DONT put any of this in directories with spaces or anything but simple ascii names. Use something like eg C:\dev\signalk-server

You should now have a SignalK server running, on http://localhost:8080. There is a menu page there that allows you to access the following:

Development
-----------
The project is developed and built using maven and eclipse. 

You will need to clone the signalk-core-java project and build it with maven , then the signalk-server-java project. The default build uses the most recent jitpack.io builds, for dev you need to set the system property in maven as follows. This will cause the builds to use the dev dependencies, from your local repository.

```
mvn -Dsignalk.build=dev install
```

The signalk-core-java project is usable separately and contains the core model, and useful helpers.


See http://www.42.co.nz/freeboard and http://http://signalk.github.io/ for more.
