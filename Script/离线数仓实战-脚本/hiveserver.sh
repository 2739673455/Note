#!/bin/bash
HIVE_LOG_DIR=$HIVE_HOME/logs
[ ! -d $HIVE_LOG_DIR ] && mkdir -p $HIVE_LOG_DIR

hiveserver2_host=hadoop100
metastore_host=hadoop101

function check_process(){
	server_name=$1
	server_port=$2
	host=$3
	pid=$(ssh $host ps -ef 2>/dev/null | grep -v grep | grep -i $server_name | awk '{print $2}')
	ppid=$(ssh $host netstat -nltp 2>/dev/null | grep $server_port | awk '{print $7}' | cut -d '/' -f 1)
	echo $pid
	[[ "$pid" =~ "$ppid" ]] && [ "$ppid" ] && return 0 || return 1
}
function hive_operate(){
	cmd1="ssh $metastore_host nohup hive --service metastore >$HIVE_LOG_DIR/metastore.log 2>&1 &"
	cmd2="ssh $hiveserver2_host nohup hive --service hiveserver2 >$HIVE_LOG_DIR/hiveServer2.log 2>&1 &"
	metapid=$(check_process HiveMetastore 9083 $metastore_host)
	metastatus=$?
	server2pid=$(check_process HiveServer2 10000 $hiveserver2_host)
	server2status=$?
	case $1 in
	"start")
		[ -z "$metapid" ] && eval $cmd1 || echo "Metastroe服务正在运行"
		[ -z "$server2pid" ] && eval $cmd2 || echo "HiveServer2服务正在运行"
		;;
	"stop")
		[ "$metapid" ] && ssh $metastore_host kill -9 $metapid || echo "Metastore服务未在运行"
		[ "$server2pid" ] && ssh $hiveserver2_host kill -9 $server2pid || echo "HiveServer2服务未在运行"
		;;
	"status")
		[ $metastatus -eq 0 ] && echo "Metastroe服务正常" || echo "Metastore服务异常"
		[ $server2status -eq 0 ] && echo "HiveServer2服务正常" || echo "HiveServer2服务异常"
		;;
	esac
}

case $1 in
"start")hive_operate start;;
"stop")hive_operate stop;;
"status")hive_operate status;;
*)echo "start|stop|status";;
esac