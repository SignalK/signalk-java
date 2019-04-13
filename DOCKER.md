# Docker Readme

This docker configuration implements three containers: influxdb, signalk and grafana. We have chosen to separate the the influxdb installation from signalk in case third parties also refere to influxdb independently. Grafana is a monitoring tool to have a graphical insight of the time series Data Base influxdb.

Before building the containers, we have to change the signalk entry point to a runnable bash script:
```
chmod +x docker/signalk/signalk_entrypoint.sh
```

then we also manage the SELinux security issue by running:
```
chcon -Rt svirt_sandbox_file_t docker/signalk/signalk_entrypoint.sh
```

To build the two images composing the docker. Locate yourself in the terminal at the root of the signalk-java project directory. Then:
- `sudo docker build --tag signalk:signalk -f docker/signalk/Dockerfile .`
- `sudo docker build --tag signalk:influxdb -f docker/influxdb/Dockerfile .`

Subsequently you can now run the `sudo docker-compose up` which will start the three different containers defined in the `docker-compose.yml` file.

### Influxdb

The influxdb image is not taken straight from the docker hub image because the latest version available is broken. We mount the local influx `/var/lib/influxdb` folder into the docker in order to have an easy external access. See the `docker-compose.yml` file where you will find:
```
volumes:
  - /var/lib/influxdb:/var/lib/influxdb:Z
```
We also open the recommended ports via:
```
ports:
  - 8086:8086
  - 8088:8088
```

### Signalk

Since influxdb is launched outside the signalk container, very little is left to manage.
For convenience, we mount the local github clone into the docker with:
```
volumes:
  - ./:/etc/signalkJavaServer:Z
```
This allows to have the session survice a container run and have access to the code for the maven execution with `mvn exec:exec`. We also open all the required ports for having all available access to the service provided by the signalk server.

### Todo
- Manage `arm` architectures. The signalk Dockerfile explicitly specifies the architecture.
- Use docker networks
- Use a minimal OS like alpine instead of ubuntu. The latter being too heavy for the purpose.
- Decide how to manage the signalk volumes. The configuration folders being inside the git project complicates a little bit the volumes set up.