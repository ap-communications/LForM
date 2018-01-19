#! /bin/bash

#DBOPEN=`curator --host localhost open indices --older-than $# --timestring %Y%m%d --time-unit days --prefix forti`

DBOPEN=`curator open indices --index forti_syslog_log_001_$1-$2`
echo $DBOPEN

#DBSTATUS=`curl localhost:9200/_cat/indices?pretty`
#echo $DBSTATUS
