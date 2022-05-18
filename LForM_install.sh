#! /bin/bash

echo "**********************"
echo "Install started."
echo "**********************"

echo `date`

# Version definition

elasticsearch_version="8.1.1"
java_version="java-1.8.0"
gem_elastic_version="7.16.3"
gem_fluent_elastic_version="5.1.4"
nginx_version="nginx-1.18.0"


# Preparation

echo "====Preparation===="

mkdir /var/log/APC
mkdir -p /opt/APC/fluentd/lib
mkdir -p /opt/APC/elasticsearch
mkdir /var/lib/fluentd_buffer
mkdir -p /var/log/kibana

source /root/.bash_profile


cp -p /etc/rsyslog.conf /etc/rsyslog.conf.`date '+%Y%m%d'`
\cp -f /etc/rsyslog.d/50-default.conf /etc/rsyslog.d/50-default.conf.`date '+%Y%m%d'`
\cp -f LForM/system/50-default.conf /etc/rsyslog.d/50-default.conf
systemctl restart rsyslog


## Elasticsearch
echo "====Elasticsearch===="

sudo apt-get install -y apt-transport-https
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list
sudo apt-get update && sudo apt-get install -y elasticsearch=$elasticsearch_version


## kibana
echo "====kibana===="
curl -O "https://lform-repo.s3.ap-northeast-1.amazonaws.com/pkg/kibana-8.1.1-SNAPSHOT-amd64.deb"
curl -O "https://lform-repo.s3.ap-northeast-1.amazonaws.com/pkg/kibana-8.1.1-SNAPSHOT-amd64.deb.sha1.txt"
echo `sha1sum kibana-8.1.1-SNAPSHOT-amd64.deb`
echo `cat kibana-8.1.1-SNAPSHOT-amd64.deb.sha1.txt`
sudo dpkg -i kibana-8.1.1-SNAPSHOT-amd64.deb

## Fluentd
echo "====Fluentd===="

ulimit -n 1048576
curl -fsSL https://toolbelt.treasuredata.com/sh/install-debian-bullseye-td-agent4.sh | sh

## Fluentd Plugin
echo "====Fluentd Plugin===="

td-agent-gem install elasticsearch -v $gem_elastic_version
td-agent-gem install fluent-plugin-elasticsearch -v $gem_elastic_version
 
 
## nginx
echo "====nginx===="

curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -

cat <<EOF> /etc/apt/sources.list.d/nginx.list
deb https://nginx.org/packages/ubuntu/ focal nginx 
deb-src https://nginx.org/packages/ubuntu/ focal nginx
EOF

sudo apt -y install nginx=$nginx_version

## Setting file copy
echo "====Setting file copy===="

### kibana
cp -pf src/kibana/config/kibana.yml /etc/kibana/kibana.yml
mkdir /etc/kibana/certs

cp /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.png /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.png`date '+%Y%m%d'`
cp /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.svg /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.svg`date '+%Y%m%d'`
cp -pf src/kibana/favicon.png /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.png
cp -pf src/kibana/favicon.svg /usr/share/kibana/src/core/server/core_app/assets/favicons/favicon.svg

cp -p /usr/share/kibana/src/core/server/rendering/views/logo.js /usr/share/kibana/src/core/server/rendering/views/logo.js`date '+%Y%m%d'`
cp -p /usr/share/kibana/src/core/server/rendering/views/template.js /usr/share/kibana/src/core/server/rendering/views/template.js`date '+%Y%m%d'`
cp -pf src/kibana/logo.js /usr/share/kibana/src/core/server/rendering/views/logo.js
cp -pf src/kibana/template.js /usr/share/kibana/src/core/server/rendering/views/template.js

### Elasticsearch
echo `src/elasticsearch/jvmoptions_set.sh`
wait

\cp -pf PALallax/elasticsearch/config/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml
chown elasticsearch:elasticsearch /etc/elasticsearch/elasticsearch.yml
chown elasticsearch:elasticsearch /var/log/elasticsearch/
chown elasticsearch:elasticsearch /var/lib/elasticsearch/

### Fluentd
\cp -pf src/fluentd/config/td-agent.conf /etc/td-agent/td-agent.conf
\cp -pf src/fluentd/lib/parser_fortigate_syslog.rb /etc/td-agent/plugin/parser_fortigate_syslog.rb
\cp -pf src/fluentd/lib/snmp_get_out_exec.rb /opt/APC/fluentd/lib/

sed -i -e "s/TD_AGENT_USER=td-agent/TD_AGENT_USER=root/g" /etc/init.d/td-agent
sed -i -e "s/TD_AGENT_GROUP=td-agent/TD_AGENT_GROUP=root/g" /etc/init.d/td-agent

### nginx
cp -p /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/default.conf.`date '+%Y%m%d'`
cp -p /etc/nginx/nginx.conf /etc/nginx/nginx.conf.`date '+%Y%m%d'`
cp -p src/nginx/config/.htpasswd /etc/nginx/conf.d/.htpasswd
\cp -pf src/nginx/config/default.conf /etc/nginx/conf.d/default.conf
\cp -pf src/nginx/config/nginx.conf /etc/nginx/nginx.conf


## ufw check

echo `sudo ufw status`


# FileDescriptor Setting

echo `ulimit -n`
# Default setting for Ubuntu Focal is 1048576


# Disable yum update

echo exclude=td-agent* kibana* elasticsearch* nginx* java* >> /etc/yum.conf

# database copy
echo "====database copy===="

mkdir -p /var/lib/APC/backup
chown -R elasticsearch:elasticsearch /var/lib/APC/backup/

systemctl start elasticsearch.service
sleep 180s
systemctl status elasticsearch.service

## Kibana Settings

ES_PASS=`cat src/install.log | grep "The generated password" | awk '{print $11}'`

systemctl start kibana.service
sleep 300s
systemctl status kibana.service

curl -u elastic:$ES_PASS -XPUT 'http://localhost:9200/_snapshot/snapshot'  -H 'Content-Type: application/json' -d '{
    "type": "fs",
    "settings": {
        "location": "/var/lib/APC/backup/",
        "compress": true
    }
}'

curl -u elastic:$ES_PASS -XPOST localhost:9200/_snapshot/snapshot/snapshot_kibana/_restore

echo `src/format.sh`
wait
sleep 60s

curl -u elastic:$ES_PASS -X POST "http://localhost:5601/api/saved_objects/_import" -H 'Content-Type: application/json' -H "kbn-xsrf: true" --form file=@src/kibana/export.ndjson
wait
echo `src/kibana_setting.sh`
wait

## Logrotate Settings
echo `src/ilm_policy.sh`


# Auto start
 echo "====Auto start===="

systemctl enable td-agent.service
systemctl enable elasticsearch.service
systemctl enable kibana.service
systemctl enable nginx.service


systemctl start kibana.service
systemctl start nginx.service
systemctl start td-agent.service

systemctl status td-agent.service
systemctl status elasticsearch.service
systemctl status kibana.service
systemctl status nginx.service

date
echo "**********************"
echo "Install completed."
echo "**********************"
