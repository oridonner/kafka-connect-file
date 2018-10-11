# create new connector
echo '{"name":"sqream-source-connector","config":{"connector.class":"JdbcSourceConnector","connection.url":"jdbc:Sqream://192.168.0.212:5000/master","connection.user":"sqream","connection.password":"sqream","mode":"bulk","table.whitelist":"login","validate.non.null":false,"topic.prefix":"sqream."}}' | curl -X POST -d @- http://localhost:8082/connectors --header "content-Type:application/json"

# pause connector
curl -X PUT localhost:8082/connectors/sqream-source-connector/pause

# restart 
curl -X POST localhost:8082/connectors/sqream-source-connector/tasks/0/restart

# delete
curl -X DELETE localhost:8082/connectors/sqream-source-connector