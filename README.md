Streaming CSV data into _Kafka_ described in _Confluent's_ [blog bost](https://www.confluent.io/blog/ksql-in-action-enriching-csv-events-with-data-from-rdbms-into-AWS/).  
**data** directory keeps **tpch** data and **sqream_storage** data.  

# Create _TPCH_ sample data
Create 1 GB of _TPCH_ customer table. Full _dbgen_ instructions available [here](https://github.com/electrum/tpch-dbgen).  
`cd data/tpch`  
`./../../tpch/dbgen -s 1 -T c`  

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

### Create table on _SQream_

` DROP TABLE customer;`  
` CREATE TABLE customer    (  
                            CUSTKEY           BIGINT,    
                            NAME              NVARCHAR(100),    
                            ADDRESS           NVARCHAR(100),    
                            NATIONKEY         BIGINT,  
                            PHONE             NVARCHAR(100),    
                            ACCTBAL           NVARCHAR(100),  
                            MKTSEGMENT        NVARCHAR(100),  
                            COMMENT           NVARCHAR(100)  
                        );  
`
# Start _Kafka Broker_  
Start _Zookeeper_ Server:  
`./bin/zookeeper-server-start.sh config/zookeeper.properties`  

Start _Kafka Broker_ on local machine:  
`./bin/kafka-server-start.sh config/server.properties`  

# Start _Kafka Connect_
Start _Kafka Connect_ in a distributed mode:  
`./bin/connect-distributed.sh config/connect-distributed.properties`  

Check if _Kafka Connect_ is up:  
`curl localhost:8083/`  

Check available connector plugins:  
`curl localhost:8083/connector-plugins | jq`  

### _SpoolDir Source Connector_
We will import **customer table** into **customer topic**. Make sure topic is empty, if it exists data will be added to it. If required delete it with this command:  
`./bin/kafka-topics.sh --zookeeper localhost:2181 --delete --topic customer`  

Start _SpoolDir Source Connector_ in a stanalone mode:  
`curl -i -X POST -H "Accept:application/json" \
    -H  "Content-Type:application/json" http://localhost:8083/connectors/ \
    -d '{
  "name": "csv-source-customer",
  "config": {
    "tasks.max": "1",
    "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
    "input.file.pattern": "customer.tbl",
    "input.path": "/home/sqream/kafka/file-sqream-pipeline/data/tpch",
    "finished.path": "/home/sqream/kafka/file-sqream-pipeline/data/finished",
    "error.path": "/home/sqream/kafka/file-sqream-pipeline/data/error",
    "halt.on.error": "false",
    "topic": "customer",
    "value.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"NAME\":{\"type\":\"STRING\",\"isOptional\":true},\"ADDRESS\":{\"type\":\"STRING\",\"isOptional\":true},\"NATIONKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"PHONE\":{\"type\":\"STRING\",\"isOptional\":true},\"ACCTBAL\":{\"type\":\"STRING\",\"isOptional\":true},\"MKTSEGMENT\":{\"type\":\"STRING\",\"isOptional\":true},\"COMMENT\":{\"type\":\"STRING\",\"isOptional\":true}}}",
    "key.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true}}}",
    "csv.first.row.as.header": "false"
  }
}'`  

Start a _Kafka Consumer_ listens to **customer** topic:  
`./bin/kafka-console-consumer.sh --zookeeper localhost:2181 --topic customer --from-beginning`  
On _Kafka 2.0.0_ use `--bootstrap-server localhost:9092` instead of `--zookeeper` flag.  

### Create _SQream Sink Connector_
Start _SQream Sink Connector_ in a standalone mode, first make sure to stop _Kafka Connect_ with **CRTL C**:
`./bin/connect-standalone.sh config/connect-standalone.properties config/sqream-spooldir-sink.properties`  

### Run a full pipeline
Start both _Spooldir Source Connector_ and  _SQream Sink Connector_ in a stanalone mode, this will create a full pipeline from CSV file to _SQream_.  
`./bin/connect-standalone.sh config/connect-standalone.properties config/connect-spooldir-source.properties config/sqream-spooldir-sink.properties`  





