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