#! /bin/bash
read -rsp 'Password: ' ES_PASS

echo "====Space setting===="
curl -X PUT "http://localhost:5601/api/spaces/space/default" --cacert /etc/kibana/certs/elasticsearch-ca.pem -u elastic:$ES_PASS -H 'Content-Type: application/json' -H "kbn-xsrf: reporting"  -d '
{
"id": "default",
"name": "Default",
"disabledFeatures": ["canvas","maps","ml","enterpriseSearch","logs","infrastructure","graph","apm","uptime","observabilityCases","siem","securitySolutionCases","dev_tools","savedObjectsTagging","osquery","actions","stackAlerts","fleetv2","fleet","monitoring"]
}
'

echo "====Import objects===="
curl --form file=@src/kibana/export.ndjson -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" --cacert /etc/kibana/certs/elasticsearch-ca.pem -u elastic:$ES_PASS -H "kbn-xsrf: true" 


echo "====Backup repo===="
curl -XPUT "https://localhost:9200/_snapshot/snapshot?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d '{
    "type": "fs",
    "settings": {
        "location": "/var/lib/APC/backup/",
        "compress": true
    }
}'

echo "====Create role===="
curl -XPOST "https://localhost:9200/_security/role/data_stream?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H "Content-Type: application/json" -d'
{
  "cluster": ["all"],
  "indices": [
    {
      "names": ["*"],
      "privileges": ["all"]
    }
  ]
}
'

echo "====Create user===="
curl -XPOST "https://localhost:9200/_security/user/data_stream_user?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H "Content-Type: application/json" -d'
{
  "password" : "Data_stream_pw",
  "roles" : [ "data_stream" ]
}
'

echo "====ILM settings===="
curl --data @src/elasticsearch/ilm_policy/forti_traffic.json -XPUT "https://localhost:9200/_ilm/policy/forti_traffic_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/forti_security.json -XPUT "https://localhost:9200/_ilm/policy/forti_security_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/palo_traffic.json -XPUT "https://localhost:9200/_ilm/policy/palo_traffic_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/palo_security.json -XPUT "https://localhost:9200/_ilm/policy/palo_threat_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/palo_globalprotect.json -XPUT "https://localhost:9200/_ilm/policy/palo_globalprotect_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_sign.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_sign_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_incident.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_incident_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_vi.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_vi_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_audit.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_audit_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_health.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_health_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"


echo "====Template setting Fortigate===="
curl --data @src/elasticsearch/index_template/forti_log_format.json -X PUT "https://localhost:9200/_index_template/forti_template_02?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'


echo "====Template setting Paloalto===="
curl --data @src/elasticsearch/index_template/palo_log_format.json -X PUT "https://localhost:9200/_index_template/palo_template_02?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'


echo "====Template setting Nozomi===="
curl --data @src/elasticsearch/index_template/nozomi_log_format.json -X PUT "https://localhost:9200/_index_template/nozomi_template_02?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'

echo " "
echo "**********************"
echo "Setting completed."
echo "**********************"