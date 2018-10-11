# create new connector
echo '{"name":"mysql-source-connector","config":{"tasks.max":3,"connector.class":"JdbcSourceConnector","connection.url":"jdbc:mysql://127.0.0.1:3306/sink","connection.user":"root","connection.password":"123456","mode":"bulk","validate.non.null":false,"table.whitelist":"orders","topic.prefix":"sql."}}' | curl -X POST -d @- http://localhost:8083/connectors --header "content-Type:application/json"

# pause connector
curl -X PUT localhost:8082/connectors/mysql-source-connector/pause
# restart 
curl -X POST localhost:8082/connectors/mysql-source-connector/tasks/0/restart

# delete
curl -X DELETE localhost:8082/connectors/mysql-source-connector