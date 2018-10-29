Streaming CSV data into _Kafka_ described in _Confluent's_ [blog bost](https://www.confluent.io/blog/ksql-in-action-enriching-csv-events-with-data-from-rdbms-into-AWS/).  
**data** directory keeps **tpch** data and **sqream_storage** data.  

# Create _TPCH_ sample data
Create 1 GB of _TPCH_ data. Full _dbgen_ instructions available [here](https://github.com/electrum/tpch-dbgen).  
`cd data/tpch`  
`./../dbgen -s 1`  

# Build _kafka-connect-spooldir_ package
kafka-connect-spooldir applies a supplied schema to CSV file.  

Clone project:  
`git clone https://github.com/jcustenborder/kafka-connect-spooldir`  
`cd kafka-connect-spooldir`  

Build package with _Maven_:  
`mvn clean package -DskipTests`  

Required **jar** files path is **target/kafka-connect-target/usr/share/kafka-connect/kafka-connect-spooldir/**  

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

# Start _Kafka Cluster_
