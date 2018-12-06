Signal K java 
=================================================


A Signal K server setup for easy deployment onto an RPi, or any Debian based Linux PC. 

Other linux types should be simple, just use the appropriate package manager instead of apt.

Its also possible (and should be quite simple) on a windows PC, but you have to manually install java, git, and maven as Windows doesnt have the kind of package management common to linux.

Provided under an Apache 2 licence

Install on PC
--------------

NOTE: this now installs the new Artemis server by default.

First do a standard installation fo Java and Influxdb for your platform:

NOTE: WINDOWS users: no spaces in dir/file names, you will cause yourself pain :-(

* Java SE 8 : https://java.com/en/download/
* InfluxDb (1.6+): https://portal.influxdata.com/downloads#influxdb
* Apache Maven 3+: https://maven.apache.org/download.cgi
* Git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

Follow the instructions for each to suit your platform.

You need to be able to type 'java' on the command line and get java responding, same for maven and git.

Create a suitable directory to install signalk-java. eg C:\dev\

Thats all the prep, then open a command console:
```
C:\dev> git clone https://github.com/SignalK/signalk-java.git
C:\dev\> cd signalk-java
C:\dev\signalk-java> git checkout artemis
C:\dev\signalk-java> mvn exec:java
```
Maven will install all the required components and start the application.  

You should now have a SignalK server running, on http://localhost:8080
See ![](./SECURITY.md)


Install on RPi
--------------

__The various *.sh scripts are untried with raspbian jessie and the artemis server. Mods welcome.__

See also https://github.com/SignalK/specification/wiki/Raspberry-Pi-Installation-(Java-Server)

This new version is easiest from a complete fresh RPi install.

__Goto INSTALL.md (https://github.com/SignalK/signalk-java/blob/artemis/INSTALL.md)__

Now open a modern web browser (eg not IE) to `http://[ip_address_of_the_pi]:8080`
You should get a pretty start page! 

Login or you will only see 'public' data! See ![](./SECURITY.md)

Go to the 'server' tab and install the 4 apps (Freeboard-sk, Instrument Panel, Sailgauge. Kip)

Try the apps. (Sailguage and Kip are broken at present, expect a fix for Kip shortly.)

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

Devices (aka GPS) attached on serial>USB adaptors will be automatically found and used. The input can be NMEA0183 compatibleor signalk, and expects 38400 baud by default. The configuration can be changed by editing the configuration


Development
-----------
The project is developed and built using maven and eclipse. 

You will need to clone the artemis-server project and build it with maven. The default build uses the most recent jitpack.io builds, for dev you need to set the system property in maven as follows. This will cause the builds to use the dev dependencies, from your local repository.

```
mvn -Dsignalk.build=dev install
```

See http://www.42.co.nz/freeboard and http://http://signalk.github.io/ for more.
