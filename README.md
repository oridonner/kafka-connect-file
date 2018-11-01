Streaming CSV data into _Kafka_ described in _Confluent's_ [blog bost](https://www.confluent.io/blog/ksql-in-action-enriching-csv-events-with-data-from-rdbms-into-AWS/).  
**data** directory keeps **tpch** data and **sqream_storage** data.  

# Prerequisites
### _kafka-connect-spooldir_ package
[kafka-connect-spooldir](https://github.com/jcustenborder/kafka-connect-spooldir) applies a supplied schema to CSV file.  
Clone project:  
`git clone https://github.com/jcustenborder/kafka-connect-spooldir`  
`cd kafka-connect-spooldir`  

Build package with _Maven_:  
`mvn clean package -DskipTests`  

Copy **jar** files from **target/kafka-connect-target/usr/share/kafka-connect/kafka-connect-spooldir/** to local **kafka_2.11-2.0.0/libs**  

### _SQream JDBC Driver_ package
Copy latest **SqreamJDBC.jar** to to local **kafka_2.11-2.0.0/libs**  

# Create _TPCH_ sample data
Create 1 GB of _TPCH_ customer table. Full _dbgen_ instructions available [here](https://github.com/electrum/tpch-dbgen).  
`cd data/tpch`  
`./../../tpch/dbgen -s 1 -T c`  


# Start SQream
We will start _Sqream_ in a developer mode over _Docker_ not _docker compose_ for debugging reasons.  
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
This command will start _sqreamd_, _zookeeper_, 2 _kafka_ brokers (broker-1, broker-2), _schema registry_, _kafka connect_.  

# Tests
First check status of the containers, executing this command:  
`docker-compose ps`  
If all containers  are up and running start the following funcionality tests.  

### Test _Kafka Broker_
Test if _Kafka Broker_ is running by createing a topic:  
`docker run --net=kafka-cluster --rm confluentinc/cp-kafka:5.0.0 kafka-topics --create --topic foo --partitions 1 --replication-factor 1 --if-not-exists --zookeeper zookeeper:32181`

List all existing topics:  
`docker run --net=kafka-cluster --rm confluentinc/cp-kafka:5.0.0 kafka-topics --list --zookeeper zookeeper:32181`  

Delete testing topic:  
`docker run --net=kafka-cluster --rm confluentinc/cp-kafka:5.0.0 kafka-topics --delete --topic foo --zookeeper zookeeper:32181`  

### Test _Schema Registry_
Code examples from [here](https://github.com/confluentinc/schema-registry#quickstart):  

Register a new version of a schema under the subject "Kafka-key"  
`curl -X POST -H "Content-Type: application/vnd.schemaregistry.v1+json" --data '{"schema": "{\"type\": \"string\"}"}' http://localhost:8081/subjects/Kafka-key/versions`  
     
List all subjects:  
`curl -X GET http://localhost:8081/subjects | jq`  

Delete subject:  
`curl -X DELETE http://localhost:8081/subjects/Kafka-key`  

### Test _kafka connect_
Check available connector plugins:  
`curl localhost:8083/connector-plugins | jq`  
You shoud see _Twitter_ connector plugin among other built in connectors:  
> {  
    "class": "com.github.jcustenborder.kafka.connect.twitter.TwitterSourceConnector",  
    "type": "source",  
    "version": "0.2-SNAPSHOT"  
  },  
  
### Test _kafka cluster_ listeners
Mapped internal broker listerners can't be used by _schema registry_ as discussed [here](https://github.com/confluentinc/schema-registry/issues/648), and remains PLAINTEXT. External broker listeners is named EXTERNAL, and mapped to PLAINTEXT security protocol.  

Run a [kstet](http://gitlab.sq.l/DevOps/kstet) container configed to _kafka-cluster_ network:  
`docker run -it --rm --network=kafka-cluster kstet:1.0.0 bash`  

Test listeners from inside of the container:  
Test internal listener:  
`kafkacat -b broker-1:29092 -L`  
`kafkacat -b broker-2:29092 -L` 

Test external listener:  
`kafkacat -b broker-1:9092 -L`  
`kafkacat -b broker-2:9093 -L`  

Test external listener from host, where 172.17.0.1 is _docker0_ ip:  
`kafkacat -b 172.17.0.1:9093 -L`  

### Create _SpoolDir Source Connector_
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
    "input.file.pattern": "^customer.tbl$",
    "input.path": "/home/sqream/kafka/file-sqream-pipeline/data/tpch",
    "finished.path": "/home/sqream/kafka/file-sqream-pipeline/data/finished",
    "error.path": "/home/sqream/kafka/file-sqream-pipeline/data/error",
    "halt.on.error": "false",
    "csv.separator.char": 124,
    "topic": "customer",
    "value.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Value\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"NAME\":{\"type\":\"STRING\",\"isOptional\":true},\"ADDRESS\":{\"type\":\"STRING\",\"isOptional\":true},\"NATIONKEY\":{\"type\":\"INT64\",\"isOptional\":true},\"PHONE\":{\"type\":\"STRING\",\"isOptional\":true},\"ACCTBAL\":{\"type\":\"STRING\",\"isOptional\":true},\"MKTSEGMENT\":{\"type\":\"STRING\",\"isOptional\":true},\"COMMENT\":{\"type\":\"STRING\",\"isOptional\":true}}}",
    "key.schema": "{\"name\":\"com.github.jcustenborder.kafka.connect.model.Key\",\"type\":\"STRUCT\",\"isOptional\":false,\"fieldSchemas\":{\"CUSTKEY\":{\"type\":\"INT64\",\"isOptional\":true}}}",
    "csv.first.row.as.header": "false"
  }
}'`  

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

### Check _customer_ topic
Start a _Kafka Consumer_ listens to **customer** topic:  
`./bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic customer --from-beginning`  

### Create _SQream Sink Connector_
`echo '{"name":"sqream-csv-sink","config":{"connector.class":"JdbcSinkConnector","connection.url":"jdbc:Sqream://192.168.0.212:5000/master","connection.user":"sqream","connection.password":"sqream","tasks.max":"1","topics":"customer","insert.mode":"insert","table.name.format":"customer","fields.whitelist":"CUSTKEY,NAME,ADDRESS,NATIONKEY,PHONE,ACCTBAL,MKTSEGMENT,COMMENT"}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"`  

Check if connector was created:  
`curl localhost:8083/connectors | jq`  


Pause connector:  
`curl -X PUT localhost:8083/connectors/sqream-csv-sink/pause`  

To restart connector:  
`curl -X PUT localhost:8083/connectors/sqream-csv-sink/resume`  

Delete connector:  
`curl -X DELETE localhost:8083/connectors/sqream-csv-sink`  

