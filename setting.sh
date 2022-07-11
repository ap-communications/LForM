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
#Forti
curl --data @src/elasticsearch/ilm_policy/forti_traffic_policy.json -XPUT "https://localhost:9200/_ilm/policy/forti_traffic_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/forti_security_policy.json -XPUT "https://localhost:9200/_ilm/policy/forti_security_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
#Palo
curl --data @src/elasticsearch/ilm_policy/palo_traffic_policy.json -XPUT "https://localhost:9200/_ilm/policy/palo_traffic_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/palo_threat_policy.json -XPUT "https://localhost:9200/_ilm/policy/palo_threat_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/palo_gp_policy.json -XPUT "https://localhost:9200/_ilm/policy/palo_globalprotect_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
#Nozomi
curl --data @src/elasticsearch/ilm_policy/nozomi_sign_policy.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_sign_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_incident_policy.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_incident_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_vi_policy.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_vi_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_audit_policy.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_audit_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"
curl --data @src/elasticsearch/ilm_policy/nozomi_health_policy.json -XPUT "https://localhost:9200/_ilm/policy/nozomi_health_policy_001" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:"$ES_PASS" -H "Content-Type: application/json" -H "kbn-xsrf: reporting"

echo "====Template setting Fortigate===="
curl --data @src/elasticsearch/index_template/forti_traffic_format.json -X PUT "https://localhost:9200/_index_template/forti_traffic_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/forti_security_format.json -X PUT "https://localhost:9200/_index_template/forti_threat_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'

echo "====Template setting Palo Alto===="
curl --data @src/elasticsearch/index_template/palo_traffic_format.json -X PUT "https://localhost:9200/_index_template/palo_traffic_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/palo_threat_format.json -X PUT "https://localhost:9200/_index_template/palo_threat_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/palo_gp_format.json -X PUT "https://localhost:9200/_index_template/palo_globalprotect_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'

echo "====Template setting Nozomi===="
curl --data @src/elasticsearch/index_template/nozomi_sign_format.json -X PUT "https://localhost:9200/_index_template/nozomi_sign_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/nozomi_incident_format.json -X PUT "https://localhost:9200/_index_template/nozomi_incident_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/nozomi_vi_format.json -X PUT "https://localhost:9200/_index_template/nozomi_vi_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/nozomi_audit_format.json -X PUT "https://localhost:9200/_index_template/nozomi_audit_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'
curl --data @src/elasticsearch/index_template/nozomi_health_format.json -X PUT "https://localhost:9200/_index_template/nozomi_health_template?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json'

echo "====Alias setting Fortigate===="
curl -X PUT "https://localhost:9200/forti_syslog-traffic-000001?pretty"  --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "forti_syslog-traffic": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/forti_syslog-security-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "forti_syslog-security": {
      "is_write_index": true
    }
  }
}'

echo "====Alias setting PaloAlto===="
curl -X PUT "https://localhost:9200/palo_syslog-traffic-000001?pretty"  --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "palo_syslog-traffic": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/palo_syslog-threat-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "palo_syslog-threat": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/palo_syslog-globalprotect-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "palo_syslog-globalprotect": {
      "is_write_index": true
    }
  }
}
'
echo "====Alias setting Nozomi===="
curl -X PUT "https://localhost:9200/nozomi_syslog-sign-000001?pretty"  --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nozomi_syslog-sign": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/nozomi_syslog-incident-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nozomi_syslog-incident": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/nozomi_syslog-vi-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nozomi_syslog-vi": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/nozomi_syslog-audit-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nozomi_syslog-audit": {
      "is_write_index": true
    }
  }
}
'
curl -X PUT "https://localhost:9200/nozomi_syslog-health-000001?pretty" --cacert /etc/elasticsearch/certs/ca/ca.crt -u elastic:$ES_PASS -H 'Content-Type: application/json' -d'
{
  "aliases": {
    "nozomi_syslog-health": {
      "is_write_index": true
    }
  }
}
'


echo " "
echo "**********************"
echo "Setting completed."
echo "**********************"