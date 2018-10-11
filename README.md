Clone repo from GitLab and enter into kafka-connector-debugger directory.
Start Terminator and open 2 tabs, _tab 1_ for sqream _tab 2_ for kafka.

# Sqream 

On _tab 1_ open 3 new terminal windows. _Terminal 1_ for managing the host, _Terminal 2_ for viewing sqreamd output (it runs on developer mode) and _Terminal 3_ for Client Command.<br />
Use latest [Sqream Developer Docker Image](http://gitlab.sq.l/DevOps/sqream-developer) for this part.<br />

_Terminal 1:_  Build sqream persistent storage on Docker Testing Server:<br />
`docker run --name=sqream_storage --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/SqreamStorage -C -r /mnt/sqream_storage"`

_Terminal 2:_  Start sqreamd on Docker Testing Server:<br />
`docker run --name=sqreamd -it --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/sqreamd"`

_Terminal 3:_  Log into running **sqreamd** with Client Command:<br />
`docker exec -it sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master"`

_Terminal 1:_  Prepare sqream db to get data from kafka topic, create tables on **sqreeamd**:<br />
`docker exec sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master -f scripts/sqream_sutomer_table.sql"`

# Kafka Cluster

### Kafka Broker
Start Zookeeper Server:<br />
`./bin/zookeeper-server-start config/zookeeper.properties`

Start Kafka Broker on local machine:<br />
`./bin/kafka-server-start.sh config/server.properties`


### Kafka Connect
Start standalone mysql source connector to load tpch tables from mysql database to kafka topic:<br />
`./bin/connect-standalone.sh config/connect-standalone.properties config/mysql-source.properties`<br />


Check if data was loaded to kafka topic:<br />
`./bin/kafka-console-consumer.sh --bootstrap-server=localhost:9092 --topic mysql.customer --from-beginning`<br />

Stop standalone mysql source connector and start standalone sqream sink connector to load data from kafka topic to sqream db:<br />
`./bin/connect-standalone.sh config/connect-standalone.properties config/sqream-sink.properties`<br />





