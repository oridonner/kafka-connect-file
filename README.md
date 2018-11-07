Building CSV SQream Pipeline over _Apache Kafka_ with _Schema Registry_ inspired by this [blog bost](https://www.confluent.io/blog/ksql-in-action-enriching-csv-events-with-data-from-rdbms-into-AWS/).  
**data** directory keeps **tpch** data and **sqream_storage** data.  

# Prerequisites
### _kafka-connect-spooldir_ package
[kafka-connect-spooldir](https://github.com/jcustenborder/kafka-connect-spooldir) applies a supplied schema to CSV file.  
Clone project:  
`git clone https://github.com/jcustenborder/kafka-connect-spooldir`  
`cd kafka-connect-spooldir`  

Build package with _Maven_:  
`mvn clean package -DskipTests`  

Copy **jar** files from **target/kafka-connect-target/usr/share/kafka-connect/kafka-connect-spooldir/** to local **libs/kafka-connect-spooldir** folder.    

### _SQream JDBC Driver_ package
Copy latest **SqreamJDBC.jar** to to local **libs/sqream-jdbc**  


### _Confluent Monitoring Interceptors_ package
Copy **monitoring-interceptors-5.0.0.jar** to local **libs/monitoring-interceptors** folder from **confluent-5.0.0/share/java/monitoring-interceptors/** folder. _Confluent Platform_ cand be downloaded from [here](https://www.confluent.io/download/).  

# Create _TPCH_ sample data
Create 1 GB of _TPCH_ customer table. Full _dbgen_ instructions available [here](https://github.com/electrum/tpch-dbgen).  
`cd data/tpch`  
`./../../tpch/dbgen -s 1 -T c`  


# Start _SQream_
We will start _SQream_ in a developer mode over _Docker_ not _docker compose_ for debugging reasons.  
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
# Start _kafka cluster_  
Create _Docker_ local network:   
`docker network create kafka-cluster`  
`docker-compose up`  
This command will start the mentioned below containers: 
- 1 _zookeeper_: on localhost:2181
- 2 _kafka_ brokers: broker-1 on localhost:9092, broker-2 on localhost:9093 
- _schema registry_ : on localhost:8081
- _kafka connect_ : on localhost:8083
- _Confluent Control Center_: on localhost:9021

Use scripts in [tests.md](http://gitlab.sq.l/DataOps/file-sqream-pipeline/blob/docker-compose/tests.md) to test running containers functionality.  

### Create _SpoolDir Source Connector_
Before starting the connector check existing topics:  
`docker run --net=kafka-cluster --rm confluentinc/cp-kafka:5.0.0 kafka-topics --zookeeper zookeeper:32181 --list`  

If **customer** topic exists, delete it:  
`docker run --net=kafka-cluster --rm confluentinc/cp-kafka:5.0.0 kafka-topics --zookeeper zookeeper:32181 --delete --topic customer` 
 
Create _SpoolDir Source Connector_ via REST API call to _kafka connect_ listens on 8083 port:  

`curl -i -X POST -H "Accept:application/json" \
    -H  "Content-Type:application/json" http://localhost:8083/connectors/ \
    -d '{
  "name": "csv-source-customer",
  "config": {
    "tasks.max": "1",
    "connector.class": "com.github.jcustenborder.kafka.connect.spooldir.SpoolDirCsvSourceConnector",
    "input.file.pattern": "^customer.tbl$",
    "input.path": "/tmp/source",
    "finished.path": "/tmp/finish",
    "error.path": "/tmp/error",
    "halt.on.error": "false",
    "csv.separator.char": 124,
    "topic": "customer",
    "value.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"NAME\":{\"type\":\"STRING\",\"isOptional\":true},\"ADDRESS\":{\"type\":\"STRING\",\"isOptional\":true},\"NATIONKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"PHONE\":{\"type\":\"STRING\",\"isOptional\":true},\"ACCTBAL\":{\"type\":\"STRING\",\"isOptional\":true},\"MKTSEGMENT\":{\"type\":\"STRING\",\"isOptional\":true},\"COMMENT\":{\"type\":\"STRING\",\"isOptional\":true}}}",
    "key.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true}}}",
    "csv.first.row.as.header": "false"
  }
}'`  

input.path,finished.path,error.path are pointing to folders inside _Kafka Connect_ container.  

Check if connector was created:  
`curl localhost:8083/connectors | jq`  

Check connector's status:  
`curl localhost:8083/connectors/csv-source-customer/status | jq`  

### Manage connector
Pause connector:  
`curl -X PUT localhost:8083/connectors/csv-source-customer/pause`  

To restart connector:  
`curl -X PUT localhost:8083/connectors/csv-source-customer/resume`  

Delete connector:  
`curl -X DELETE localhost:8083/connectors/csv-source-customer`  

Read data from _customer_ topic with _Avro_ consumer, pay attention to the `--property` flag added at the end, it is required when running _kafka-avro-console-consumer_ over local _docker_ network:  
`docker run --net=kafka-cluster --rm confluentinc/cp-schema-registry:5.0.0 kafka-avro-console-consumer --bootstrap-server broker-1:29092 --topic customer --from-beginning --property schema.registry.url="http://schema-registry:8081"`  

### Create _SQream Sink Connector_
`echo '{"name":"sqream-csv-sink","config":{"connector.class":"JdbcSinkConnector","connection.url":"jdbc:Sqream://192.168.0.212:5000/master","connection.user":"sqream","connection.password":"sqream","tasks.max":"1","topics":"customer","insert.mode":"insert","table.name.format":"customer","fields.whitelist":"CUSTKEY,NAME,ADDRESS,NATIONKEY,PHONE,ACCTBAL,MKTSEGMENT,COMMENT"}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"`  

Check if connector was created:  
`curl localhost:8083/connectors | jq`  

Check connector's status:  
`curl localhost:8083/connectors/sqream-csv-sink/status | jq` 


Pause connector:  
`curl -X PUT localhost:8083/connectors/sqream-csv-sink/pause`  

To restart connector:  
`curl -X PUT localhost:8083/connectors/sqream-csv-sink/resume`  

Delete connector:  
`curl -X DELETE localhost:8083/connectors/sqream-csv-sink`  

