#! /bin/bash
read -rsp 'Password: ' ES_PASS

systemctl start nginx.service
systemctl start td-agent.service
systemctl start elasticsearch.service
sleep 120

curl --cacert /etc/elasticsearch/certs/ca/ca.crt  -u elastic:$ES_PASS -H "Content-Type: application/json" -XPOST https://localhost:9200/_security/user/kibana_system/_password -d'
{
  "password" : "kibana_pw"
}'

systemctl start kibana.service
sleep 120

systemctl status nginx.service
systemctl status td-agent.service
systemctl status elasticsearch.service
systemctl status kibana.service


echo "**********************"
echo "completed."
echo "**********************"