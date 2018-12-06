Artemis Server Design 
=====================

This is to record and provide a conceptual view of the artemis server composition and operation. Its somewhat simplified, and not always accurate.

Components
----------

![](./artemisComponents.png?raw=true)

Horizontal scaling and high availibility can be performed at many layers, but primarily by creating a cluster of ActiveMQ artemis servers. 
Bridging the INTERNAL.KV queue allows the cluster to behave as a single instance.

Netty, Atmosphere, and Activemq Artemis all use state-of-the-art asynchronous non-blocking IO and copy-on-write shared byte buffers. Activemq Artemis 

https://activemq.apache.org/artemis/

https://netty.io/

https://github.com/Atmosphere/atmosphere

Artemis performance: https://softwaremill.com/mqperf/

Management: 
* jolokia REST API: https://jolokia.org/talks.html
* Web console: http://hawt.io/

Incoming
--------

The various incoming protocols each have their own conversions to a std signalk message. Ws messages are mostly piped straight in, 
REST messages are pre-procesed by the Atmosphere framework, with the HTTP response waiting for the reply message. 
Request messages (that expect a reply) will create an temp queue to receive replies in the form of OUTGOING.REPLY.[uuid]. 

![](./incomingMsgHandling.png?raw=true)

The consumers of the INTERNAL.KV queue can be built to suit. Each gets a copy of each message (topic/pubsub semantics), 
they can use filters to limit messages, and they can perform any action to suit. Since INTERNAL.KV is a topic, 
a consumer can pause while consuming or consume periodically and not loose messages. 

Large queues will be automatically paged to disk. Default is non-durable, but if durable messages are enabled, all messages are stored on disk, and will survive reboots. This is ideal for intermittent connections and data transfers to the cloud.

Outgoing
--------  

![](./outgoingMsgHandling.png?raw=true)

