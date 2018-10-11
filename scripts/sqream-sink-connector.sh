# create new connector
echo '{"name":"sqream-sink-connector","config":{"connector.class":"JdbcSinkConnector","connection.url":"jdbc:Sqream://192.168.0.212:5000/master","connection.user":"sqream","connection.password":"sqream","tasks.max":"5","topics":"mysql.orders","insert.mode":"insert","table.name.format":"orders"}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"

# pause connector
curl -X PUT localhost:8082/connectors/sqream-sink-connector/pause
curl -X DELETE localhost:8082/connectors/sqream-sink-connector
