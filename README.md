# Kafka Cluster
## Kafka Broker

## Kafka Connect

# Sqream 
SSH to Docker Testing Server and Open 3 terminal windows on Terminator.<br />
Use one terminal for managing the host, one for viewing sqreamd output (it runs on developer mode) and one for Client Command.<br />
Use latest [Sqream Developer Docker Image](http://gitlab.sq.l/DevOps/sqream-developer) for this part.<br />

Build sqream persistent storage on Docker Testing Server:<br />
`docker run --name=sqream_storage --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/SqreamStorage -C -r /mnt/sqream_storage"`

Start sqreamd on Docker Testing Server:<br />
`docker run --name=sqreamd -it --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/sqreamd"`

Log into running sqreamd with Client Command:<br />
`docker exec -it sqreamd bash -c "./sqream/build/ClientCmd --user=sqream --password=sqream -d master"`

Create tables on sqreeamd:

