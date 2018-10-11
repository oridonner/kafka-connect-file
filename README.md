# Kafka Cluster
## Kafka Broker

## Kafka Connect

# Sqream 
Use latest [Sqream Developer Docker Image](http://gitlab.sq.l/DevOps/sqream-developer) for this part.<br />
Build sqream persistent storage on Docker Testing Server:<br />
`docker run --name=sqream_storage --rm  -v ~/kafka-sandbox:/mnt sqream:2.15-dev bash -c "./sqream/build/SqreamStorage -C -r /mnt/sqream_storage"`

Start sqreamd on Docker Testing Server:<br />
`docker run --rm -it `

Log into running sqreamd with Client Command:


Create tables on sqreeamd:

