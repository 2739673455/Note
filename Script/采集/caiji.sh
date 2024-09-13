#!/bin/bash
function check_status(){
    result=`ps -ef | grep $1 | grep -v grep | wc -l`
    return $result
}
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
	message="Maxwell db1 : mysql -> kafka"
	check_status "$maxwell_conf"
	case $1 in
	"start")[ $? -lt 1 ] && echo "$message start" && $maxwell_home/bin/maxwell --config $maxwell_home/config.properties --daemon || echo "$message is running";;
	"stop")[ $? -gt 0 ] && echo "$message stop" && eval $(ps_stop $maxwell_conf) || echo "$message isn't running";;
	esac
}
function flume_operate(){
	host=$1
	conf_file=$2
	message=$host" flume "$3
	check_status_remote $host $conf_file
	case $4 in
	"start")[ $? -lt 1 ] && echo "$message start" && ssh $host "$(flume_start $conf_file)" || echo "$message is running";;
	"stop")[ $? -gt 0 ] && echo "$message stop" && ssh $host "$(ps_stop $conf_file)" || echo "$message isn't running";;
	esac
}

flume_home=/opt/module/flume-1.10.1
maxwell_home=/opt/module/maxwell-1.29.2
flume_conf_log1=file_to_kafka.conf
flume_conf_log2=kafka_to_hdfs_log.conf
flume_conf_db2=kafka_to_hdfs_db.conf
maxwell_conf=com.zendesk.maxwell.Maxwell

case $1 in
"log1open")flume_operate hadoop102 $flume_conf_log1 "log1 : logfile -> kafka" start;;
"log1close")flume_operate hadoop102 $flume_conf_log1 "log1 : logfile -> kafka" stop;;
"db2open")flume_operate hadoop103 $flume_conf_db2 "db2 : kafka -> hdfs" start;;
"db2close")flume_operate hadoop103 $flume_conf_db2 "db2 : kafka -> hdfs" stop;;
"log2open")flume_operate hadoop104 $flume_conf_log2 "log2 : kafka -> hdfs" start;;
"log2close")flume_operate hadoop104 $flume_conf_log2 "log2 : kafka -> hdfs" stop;;
"maxwellstart")maxwell_operate start;;
"maxwellstop")maxwell_operate stop;;
"allstart")
	flume_operate hadoop102 $flume_conf_log1 "log1 : logfile -> kafka" start
	flume_operate hadoop104 $flume_conf_log2 "log2 : kafka -> hdfs" start
	flume_operate hadoop103 $flume_conf_db2 "db2 : kafka -> hdfs" start
	maxwell_operate start
	;;
"allstop")
	flume_operate hadoop102 $flume_conf_log1 "log1 : logfile -> kafka" stop
	flume_operate hadoop104 $flume_conf_log2 "log2 : kafka -> hdfs" stop
	flume_operate hadoop103 $flume_conf_db2 "db2 : kafka -> hdfs" stop
	maxwell_operate stop
	;;
*)
	echo "log1open     | log1close"
	echo "log2open     | log2close"
	echo "db2open      | db2close"
	echo "maxwellstart | maxwellstop"
	echo "allstart     | allstop"
	;;
esac