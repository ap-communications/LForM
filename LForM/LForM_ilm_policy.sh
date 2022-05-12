PASS=`cat src/install.log | grep "The generated password" | awk '{print $11}'`

curl --cacert /etc/kibana/certs/elasticsearch-ca.pem -u elastic:$PASS -H "kbn-xsrf: reporting" -H 'Content-Type: application/json' -XPUT "https://localhost:9200/_ilm/policy/forti_ilm_policy_001" -d '
{
  "policy": {
    "phases": {
      "hot": {
        "actions": {
          "rollover": {
            "max_age": "7d",
            "max_primary_shard_size": "50gb"
          },
          "set_priority": {
            "priority": 100
          }
        },
        "min_age": "0ms"
      }
    }
  }
}
'
