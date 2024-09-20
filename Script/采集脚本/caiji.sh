#!/bin/bash

flume_home=/opt/module/flume-1.10.1
maxwell_home=/opt/module/maxwell-1.29.2

log1_host=hadoop102
log2_host=hadoop104
db2_host=hadoop103
maxwell_host=hadoop102

flume_conf_log1=file_to_kafka.conf
flume_conf_log2=kafka_to_hdfs_log.conf
flume_conf_db2=kafka_to_hdfs_db.conf
maxwell_conf=com.zendesk.maxwell.Maxwell

function check_status_remote(){
    return $(ssh $1 "ps -ef | grep $2 | grep -v grep | wc -l")
}
function flume_start(){
	echo "nohup ${flume_home}/bin/flume-ng agent -n a1 -c ${flume_home}/conf -f ${flume_home}/job/$1 >/dev/null 2>&1 &"
}
function ps_stop(){
	echo "ps -ef | grep $1 | grep -v grep | awk '{print \$2}' | xargs kill -9"
}
function maxwell_operate(){
	message="$maxwell_host Maxwell db1 : mysql -> kafka"
	check_status_remote $maxwell_host $maxwell_conf
	case $1 in
	"start")[ $? -lt 1 ] && echo "$message start" && $maxwell_home/bin/maxwell --config $maxwell_home/config.properties --daemon || echo "$message is running";;
	"stop")[ $? -gt 0 ] && echo "$message stop" && eval $(ps_stop $maxwell_conf) || echo "$message isn't running";;
	esac
}
function flume_operate(){
	host=$1
	conf_file=$2
	message="$host flume $3"
	check_status_remote $host $conf_file
	case $4 in
	"start")[ $? -lt 1 ] && echo "$message start" && ssh $host "$(flume_start $conf_file)" || echo "$message is running";;
	"stop")[ $? -gt 0 ] && echo "$message stop" && ssh $host "$(ps_stop $conf_file)" || echo "$message isn't running";;
	esac
}

case $1 in
"log1start")flume_operate $log1_host $flume_conf_log1 "log1 : logfile -> kafka" start;;
"log1stop")flume_operate $log1_host $flume_conf_log1 "log1 : logfile -> kafka" stop;;
"db2start")flume_operate $db2_host $flume_conf_db2 "db2 : kafka -> hdfs" start;;
"db2stop")flume_operate $db2_host $flume_conf_db2 "db2 : kafka -> hdfs" stop;;
"log2start")flume_operate $log2_host $flume_conf_log2 "log2 : kafka -> hdfs" start;;
"log2stop")flume_operate $log2_host $flume_conf_log2 "log2 : kafka -> hdfs" stop;;
"maxwellstart")maxwell_operate start;;
"maxwellstop")maxwell_operate stop;;
"allstart")
	flume_operate $log1_host $flume_conf_log1 "log1 : logfile -> kafka" start
	flume_operate $log2_host $flume_conf_log2 "log2 : kafka -> hdfs" start
	flume_operate $db2_host $flume_conf_db2 "db2 : kafka -> hdfs" start
	maxwell_operate start
	;;
"allstop")
	flume_operate $log1_host $flume_conf_log1 "log1 : logfile -> kafka" stop
	flume_operate $log2_host $flume_conf_log2 "log2 : kafka -> hdfs" stop
	flume_operate $db2_host $flume_conf_db2 "db2 : kafka -> hdfs" stop
	maxwell_operate stop
	;;
*)
	echo "log1start    | log1stop"
	echo "log2start    | log2stop"
	echo "db2start     | db2stop"
	echo "maxwellstart | maxwellstop"
	echo "allstart     | allstop"
	;;
esac