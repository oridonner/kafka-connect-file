# Sqream 

SSH to Docker Testing Server and Open 3 terminal windows on Terminator.<br />
Use one terminal for managing the host, one for viewing sqreamd output (it runs on developer mode) and one for Client Command.<br />
Use latest [Sqream Developer Docker Image](http://gitlab.sq.l/DevOps/sqream-developer) for this part.<br />

Build sqream persistent storage on Docker Testing Server:<br />
`docker run --name=sqream_storage --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/SqreamStorage -C -r /mnt/sqream_storage"`

Start sqreamd on Docker Testing Server:<br />
`docker run --name=sqreamd -it --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/sqreamd"`

Log into running **sqreamd** with Client Command:<br />
`docker exec -it sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master"`

Prepare sqream database to get data from kafka connector, create tables on **sqreeamd**:<br />

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





