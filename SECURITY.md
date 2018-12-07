Securing your Artemis Server
============================

Overview
--------

This version enables very fine grained security down to the individual key level but it is not production ready yet. 
There are complex aspects of signalk security still developing, which will be incorporated in due course.

_This default install uses https with self-signed certificates._ 

Browsers will complain the connection is untrusted, 
you can safely continue for non-critical installations. You can also disable https in the configuration.

NOTE: the tcp/udp signalk streams are NOT encrypted (yet).
 
_If security is important, you need to get a real signed certificate (see https://letsencrypt.org)_

By default the security is set up as follows:

* One default user `admin` with the stupid password of `admin`. _You need to change this_. See below.
* If messages contain a `token`, the user is derived from the token, and appropriate permissions applied.
* If they have no token:
	* AIS messages over serial or n2k are assigned the `ais` user. 
	* AIS messages over internal_ip are assigned the `tcp_internal` user. 
	* NMEA0183 messages received on serial connections (or serial over USB) are assigned the `serial` user. Usually this is NMEA0183 gps data etc.
	* NMEA0183 messages received on internal_ip are assigned the `tcp_internal` user.
	* NMEA0183 messages received on external_ip are assigned the `tcp_external` user.  
	* N2K messages from N2K (canboat) are assigned the `n2k` user.
	* N2K messages on the internal network are assigned the `tcp_internal` user.
	* JSON_DELTA and JSON_FULL messages over serial are assigned the `serial` user. 
	* All other messages get the `public` user

The User 'Roles' allow the permissions for these default users to be controlled.
Full RBAC rules based filtering is in the pipeline. 
Obviously a secure installation needs to secure those N2K, AIS, SERIAL and TCP sources to prevent bad actors.

Manage Users and Roles
----------------------

* Start you server and point your browser at https://[your server]:8080
* Use the LOGIN button to login, use the `admin` user
* Select the 'Manage Server' tab
* Select 'Users'

At the top of the screen you will see the user list (somewhat ugly, help gratefully accepted!)

![](./design/artemisUsers.png?raw=true)

* Reset the admin password by entering in the password field. It will need at least 8 chars. 

The password will later be converted to a hash, so you wont see it again. 
If you need to fix a forgotton password open the ./conf/security-conf.json delete the `hash`, _and the comma before it_
  
![](./design/artemisHash.png?raw=true)

Note the user is assigned one or more 'Roles'. They are defined at the bottom of the page.

![](./design/artemisRoles.png?raw=true)

You will see the 'Official' role is allowed to read some data, including `environment`, so the can get weather data etc
But that also allows them data from inside the boat which we dont want, so we deny `environment.inside`