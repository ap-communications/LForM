curl -XPUT "https://localhost:9200/_ilm/policy/lform_ilm_policy_001" -H 'Content-Type: application/json' -d '
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