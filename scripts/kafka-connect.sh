# REST API documentation: https://docs.confluent.io/current/connect/references/restapi.html#
# get connector status
curl -X GET localhost:8083/connectors/mysql-source-connector/status

# pause connector
curl -X PUT localhost:8083/connectors/mysql-source-connector/pause

# restart connector
curl -X PUT localhost:8083/connectors/mysql-source-connector/resume