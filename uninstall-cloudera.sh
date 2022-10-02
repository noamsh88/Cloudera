#!/usr/bin/env bash
set -ex
######################################
#Script deleting Cloudera from server
#####################################
# Regular Colors
NC='\033[0m'				# No Color
RED='\033[0;31m'		# Red
GREEN='\033[0;32m'	# Green
CYAN='\033[0;36m'		# Cyan

###Main###
echo -e ${CYAN} "Stoping Cloudera Services"
echo -e ${NC}
sudo service cloudera-scm-agent stop || true
sudo service cloudera-scm-server-db stop || true
sudo service cloudera-scm-server stop  || true
sudo systemctl disable cloudera-scm-server.service || true
echo -e "Cloudera Services are stopped"

echo -e ${CYAN} "Deleting Cloudera RPMs:"
echo -e ${NC}
sudo rpm -e $(rpm -qa | grep cloudera | xargs) || true
echo -e ${GREEN} "Done Deleting Cloudera RPMs on `hostname`"

echo -e ${CYAN} "Deleting Postgres DB if exist"
echo -e ${NC}
sudo systemctl stop postgresql || true
sudo rpm -e $(rpm -qa | grep python-psycopg2 | xargs) || true
sudo rpm -e $(rpm -qa | grep postgresql | grep 9 | xargs) || true
sudo rm -fr /var/lib/pgsql
echo -e ${GREEN} "Done"


echo -e ${CYAN} "Deleting all cloudera directories "
echo -e ${NC}
sudo rm -fr /var/log/hadoop-hdfs /var/log/hadoop-httpfs #HDFS_LOGDIRS
sudo rm -fr /var/log/hive /var/log/hive/operation_logs /var/log/hcatalog #HIVE_LOGDIRS
sudo rm -fr /var/log/hue #HUE_LOGDIRS
sudo rm -fr /var/log/catalogd /var/log/impala-minidumps /var/log/impalad /var/log/impala-llama /var/log/statestore #IMPALA_LOGDIRS
sudo rm -fr /var/log/oozie #OOZIE_LOGDIRS
sudo rm -fr /var/log/spark #SPARK_LOGDIRS
sudo rm -fr /var/log/hadoop-yarn #YARN_LOGDIRS
sudo rm -fr /var/log/kafka /var/log/hadoop-mapreduce #KAFKA_LOGDIRS
sudo rm -fr /var/log/zookeeper #ZOOKEEPER_LOGDIRS
sudo rm -fr /var/log/cloudera-scm-server /var/log/cloudera-scm-agent /var/log/cloudera-scm-firehose /var/log/cloudera-scm-alertpublisher /var/log/cloudera-scm-eventserver #CLOUDERA_LOGDIRS
sudo rm -fr /var/lib/cloudera*
sudo rm -fr /var/lib/hadoop*
sudo rm -fr /var/lib/hive
sudo rm -fr /var/lib/sqoop*
sudo rm -fr /var/lib/hbase /var/lib/spark /var/lib/spark2  /var/lib/zookeeper /var/lib/impala /var/lib/hue
sudo rm -fr /run/*cloudera* || true
sudo rm -fr /mnt/data*/*

echo -e ${CYAN} "Killing cloudera processes if remain"
echo -e ${NC}
sudo kill $(ps aux | grep hdfs | awk '{print $2}') || true
sudo kill $(ps aux | grep yarn | awk '{print $2}') || true

echo -e ${GREEN} "Cloudera uninstalled Successfully on `hostname` , please reboot it before continuing.. "
echo -e ${NC}
