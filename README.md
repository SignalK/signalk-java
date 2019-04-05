Signal K Java Artemis Server
============================
__Installer and Management Web-app__

A Signal K Artemis server installation for easy deployment onto an RPi, or any Debian based Linux PC. This project builds and install the java Artemis server (https://github.com/SignalK/artemis-server) and its associated web management application.

Other linux types should be simple, just use the appropriate package manager instead of apt.

Its also possible (and should be quite simple) on a windows PC, but you have to manually install java, git, and maven as Windows doesnt have the kind of package management common to linux.

Provided under an Apache 2 licence

Install on RPi
--------------

This version is easiest from a complete fresh RPi install. 

I strongly recommend adding an RTC module to the RPi as it keeps correct time even when off. This is important for the databse.
I used https://www.aliexpress.com/item/JunRoc-Raspberry-Pi-RTC-module-DS1307-IO-Pin-Connect-Compatible-With-Raspberry-Pi-3B-Pi-3B/32921678474.html

__The easiest install is the raspbian_setup.sh script__

To use the script, make sure your pi is on the internet, login to your pi (as user pi) and execute
```
pi@raspberrypi:~ $ source <(curl -s https://raw.githubusercontent.com/SignalK/signalk-java/jdk11/setup_raspbian.sh)

```

See details at https://github.com/SignalK/specification/wiki/Raspberry-Pi-Installation-(Java-Server)

A full manual install can also be done.

__Goto INSTALL.md (https://github.com/SignalK/signalk-java/blob/artemis/INSTALL.md)__

Now open a modern web browser (eg not IE or Edge) to `https://[ip_address_of_the_pi]:8443`
You should get a pretty start page! 

Install on PC
--------------

First do a standard installation for Java and Influxdb for your platform:

NOTE: WINDOWS users: no spaces in dir/file names, you will cause yourself pain :-(

* Java SE 11 : for x86: https://java.com/en/download/, or for Rpi: https://www.bell-sw.com/pages/java-11.0.2
* InfluxDb (1.6+): https://portal.influxdata.com/downloads#influxdb
* Apache Maven 3+: https://maven.apache.org/download.cgi
* Git: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

Follow the instructions for each to suit your platform.

You need to be able to type `java` on the command line and get java responding, same for maven (`mvn`) and git (`git`).
Check you are using java 11: `java -version`, should return something like:
```
openjdk version "11.0.2-BellSoft" 2018-10-16
OpenJDK Runtime Environment (build 11.0.2-BellSoft+7)
OpenJDK 64-Bit Server VM (build 11.0.2-BellSoft+7, mixed mode)

```
The `11.x.x` is important, you may get a variety of replacements for `Bellsoft`

Create a suitable directory to install signalk-java. eg C:\dev\

Thats all the prep, then open a command console:

```
C:\dev> git clone https://github.com/SignalK/signalk-java.git
C:\dev\> cd signalk-java
C:\dev\signalk-java> mvn exec:exec
```
Maven will install all the required components and start the server.  

You should now have a SignalK server running on https://localhost:8443

_This default install uses https with self-signed certificates._ 

Browsers will complain the connection is untrusted, 
you can safely continue for non-critical installations. You can also disable https in the configuration.

See [Security](./SECURITY.md)

Using Signalk-java
------------------

Login or you will only see 'public' data! See [Security](./SECURITY.md)

Go to the 'Manage Apps' tab and install the major apps (Freeboard-sk, Instrument Panel, SKWiz, and Kip)

Try the apps. 

Upload your charts using the 'Upload Charts' button in the 'Manage Server' tab. The format is the zip file output by the freeboard-installer (https://github.com/rob42/freeboard-installer)

The 'Manage Server' tab provides a number of options to manage the server configuration and logging, setup users and upload charts

The 'Signalk Api' tab gives you direct access to the raw signalk data.


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

Running under JDK11 with the Graal js compiler requires java options, already set by `mvn exec:exec`:
```
-Xmx256M -XX:+HeapDumpOnOutOfMemoryError -Dio.netty.leakDetection.level=ADVANCED -XX:+UnlockExperimentalVMOptions -XX:+EnableJVMCI --module-path=./target/compiler/graal-sdk.jar:./target/compiler/truffle-api.jar --upgrade-module-path=./target/compiler/compiler.jar
```

See https://www.42.co.nz/freeboard and https://signalk.github.io/ for more.
