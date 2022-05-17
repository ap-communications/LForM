git #! /bin/bash
PASS=`cat LForM/LForM_install.log | grep "The generated password" | awk '{print $11}'`

curl --cacert /etc/kibana/certs/elasticsearch-ca.pem -u elastic:$PASS -H "kbn-xsrf: reporting" -H 'Content-Type: application/json' -X PUT "https://localhost:5601/api/spaces/space/default" -d '
{
"id": "default",
"name": "Default",
"disabledFeatures": ["canvas","maps","ml","enterpriseSearch","logs","infrastructure","graph","apm","uptime","observabilityCases","siem","securitySolutionCases","dev_tools","savedObjectsTagging","osquery","actions","stackAlerts","fleetv2","fleet","monitoring"]
}
'
