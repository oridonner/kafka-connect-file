
# Start Zookeeper
./bin/zookeeper-server-start config/zookeeper.properties

# Start Kafka brokers
./bin/kafka-server-start.sh config/server1.properties
./bin/kafka-server-start.sh config/server2.properties
./bin/kafka-server-start.sh config/server3.properties

# Kafka Connect
 ./bin/connect-distributed.sh config/connect-distributed.properties

 # Create topic
 ./bin/kafka-topics.sh --zookeeper localhost:2181 --topic mysql.orders --create --replication-factor 3 --partitions 5

# Hard Delettion topic 
./bin/zookeeper-shell.sh localhost:2181 rmr/brokers/topics/mysql.orders

# Start sqream sink connector
./bin/connect-standalone.sh config/connect-standalone.properties config/sqream-sink.properties

# Start mysql source connector
./bin/connect-standalone.sh config/connect-standalone.properties config/mysql-source.properties

# Kafka consumer
./bin/kafka-console-consumer.sh --bootstrap-server=localhost:9092 --topic mysql.customer --from-beginning