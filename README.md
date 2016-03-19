Signal K java server
=================================================

An Signal K server setup for easy deployment onto an RPi, or any Debian based Linux PC. 
**NOTE: 19-Mar-2016 - this is incomplete! Ive pushed it up so I can test the deployment to my Pi. Feel free to try it, if it works great, but probably you will need to raise an issue. Try to include all the info you can, and exactly what you did, and any screen output

Other linux types should be simple, just use the appropriate package manager instead of apt.

Its also possible (and should be quite simple) on a windows PC, but you have to manually install java, git, and maven as Windows doesnt have the kind of package management common to linux.

Provided under an Apache 2 licence


Install on RPi
--------------

In summary we already have java jdk8 on the pi, so we will install  git, maven, and node. The server doesnt need nodejs, but the client installs do use `npm` which comes with it. . I expect to stabilise it quite quickly.

The pi must be connected to the internet for the install.
Open a console on the RPI, or ssh onto it. Log in as user pi. At the command prompt execute the following:

```shell
$ cd ~
$ curl -sLS https://apt.adafruit.com/add | sudo bash
$ sudo apt-get update
$ sudo apt-get install git maven node
$ git clone https://github.com/SignalK/signalk-java.git
$ cd signalk-java
$ mvn exec:java
```
Now open a modern web browser (eg not IE) to `http://[ip_address_of_the_pi]:8080`
You should get a pretty start page! Go to configuration and turn on the demo. Then stop start the server, use Cntrl-C to stop the server, it takes 10 secs or so.

After the restart you should find:
* webserver on `http://localhost:8080` if you have a screen and keyboard on the pi, otherwise `http://[ip_address_of_the_pi]:8080` 
	* REST api on `http://localhost:8080/signalk/v1/api/`
	* Authentication on `http://localhost:8080/signalk/v1/auth` - but its a pass all for now so you dont need to login
* websockets server on `http://localhost:3000`. 
* signalk output streamed as TCP over port 55555. On linux you can watch this with `$ ncat localhost 55555` **see below for subscriptions
* signalk output streamed as UDP over port 55554.
* nmea output will be streamed as TCP over port 55557. On linux you can watch this with `$ ncat localhost 55557`, or use telnet to connect.
* nmea output will be streamed as UDP over port 55556.

It will be streaming a demo file and dumping logging to screen. Control logging by editing conf/log4j.properties.

It currently streams out a demo file taken from a boat sailing in a race in San Francisco. The output includes AIS data. 
If you edit the configuration and make demo=false (default=true), then it will stop doing that.
Normally it only sends output in signalk delta format to subscribed clients, so clients MUST subscribe or you see only the heartbeat message every 1000ms.
You can subscribe by sending the following json. It supports * and ? wildcards In linux you can paste it into the screen you opened earlier and press [Enter]. :
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

Devices (aka GPS) attached on serial>USB adaptors will be automatically found and used. The input can be NMEA0183 compatible, or signalk, and expects 38400 baud by default. The configuration can be changed by editing conf/signalk.cfg


Installation for Windows
------------------------

You will need Java 1.7+ installed, maven3 (https://maven.apache.org/install.html), and git (https://git-scm.com/downloads). 
You need to be able to type 'java' on the command line and get java responding, same for maven and git.
Same for `npm`, so install `nodejs` from https://nodejs.org/ The server doesnt need nodejs, but the client installs do use `npm` which comes with it.


Thats all the prep, then:

NOTE: Windows users - DONT put any of this in directories with spaces or anything but simple ascii names. Use something like eg C:\dev\signalk-server

You should now have a SignalK server running, on http://localhost:8080. There is a menu page there that allows you to access the following:

Development
-----------
The project is developed and built using maven and eclipse. You will need to clone the signalk-core-java project and build it with maven , then the signalk-server-java project.
The signalk-core-java project is usuable separately and contains the core model, and useful helpers.


See http://www.42.co.nz/freeboard and http://http://signalk.github.io/ for more.