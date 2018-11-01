Streaming CSV data into _Kafka_ described in _Confluent's_ [blog bost](https://www.confluent.io/blog/ksql-in-action-enriching-csv-events-with-data-from-rdbms-into-AWS/).  
**data** directory keeps **tpch** data and **sqream_storage** data.  

# Create _TPCH_ sample data
Create 1 GB of _TPCH_ data. Full _dbgen_ instructions available [here](https://github.com/electrum/tpch-dbgen).  
`cd data/tpch`  
`./../../tpch/dbgen -s 1`  

# Build _kafka-connect-spooldir_ package
[kafka-connect-spooldir](https://github.com/jcustenborder/kafka-connect-spooldir) applies a supplied schema to CSV file.  

Clone project:  
`git clone https://github.com/jcustenborder/kafka-connect-spooldir`  
`cd kafka-connect-spooldir`  

Build package with _Maven_:  
`mvn clean package -DskipTests`  

Copy **jar** files from **target/kafka-connect-target/usr/share/kafka-connect/kafka-connect-spooldir/**  to **kafka_2.11-2.0.0/libs**  

# Start SQream
On _tab 0_ open 3 new terminal windows. _Terminal 1_ for managing the host, _Terminal 2_ for viewing sqreamd output (it runs on developer mode) and _Terminal 3_ for Client Command.  
Use latest [Sqream Developer Docker Image](http://gitlab.sq.l/DevOps/sqream-developer) for this part.  

_Terminal 1:_  Build sqream persistent storage:  
`docker run --rm -v $(pwd)/data:/mnt sqream:2.15-dev bash -c "./sqream/build/SqreamStorage -C -r /mnt/sqream_storage"`  

_Terminal 2:_  Start sqreamd, mount sqream_storage and scripts directories:  
`docker run --name=sqreamd -it --rm  -v $(pwd)/data:/mnt -v $(pwd)/scripts:/home/sqream/scripts sqream:2.15-dev bash -c "./sqream/build/sqreamd"`  

_Terminal 3:_  Log into running **sqreamd** with Client Command:  
`docker exec -it sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master"`  

_Terminal 1:_  Prepare sqream db to get data from kafka topic, create tables on **sqreeamd**:  
`docker exec sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master -f scripts/sqream_customer_table.sql"`  

# Start _Kafka Broker_  
Start Zookeeper Server:  
`./bin/zookeeper-server-start.sh config/zookeeper.properties`  

Start Kafka Broker on local machine:  
`./bin/kafka-server-start.sh config/server.properties`  

### _SpoolDir Source Connector_
We will import **customer** table into **customer** topic. Make sure topic is empty, if it exists data will be added to it. If required delete it with this command:  
`./bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic customer`  

Start _SpoolDir Source Connector_ in a stanalone mode:  
`./bin/connect-standalone.sh config/connect-standalone.properties config/connect-spooldir-source.properties`  

Start a _Kafka Consumer_ listens to **customer** topic:  
`./bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic customer --from-beginning`  
On _Kafka 2.0.0_ use `--bootstrap-server localhost:9092` instead of `--zookeeper` flag  

