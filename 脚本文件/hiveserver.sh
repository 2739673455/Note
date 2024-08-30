#!/bin/bash
HIVE_LOG_DIR=$HIVE_HOME/logs
if [ ! -d $HIVE_LOG_DIR ]
then
	mkdir -p $HIVE_LOG_DIR
fi

function check_process(){
	pid=$(ps -ef 2>/dev/null | grep -v grep | grep -i $1 | awk '{print $2}')
	ppid=$(netstat -nltp 2>/dev/null | grep $2 | awk '{print $7}' | cut -d '/' -f 1)
	echo $pid
	[[ "$pid" =~ "$ppid" ]] && [ "$ppid" ] && return 0 || return 1
}
function hive_operate(){
	cmd1="nohup hive --service metastore >$HIVE_LOG_DIR/metastore.log 2>&1 &"
	cmd2="nohup hive --service hiveserver2 >$HIVE_LOG_DIR/hiveServer2.log 2>&1 &"
	metapid=$(check_process HiveMetastore 9083)
	metastatus=$?
	server2pid=$(check_process HiveServer2 10000)
	server2status=$?
	case $1 in
	"start")
		[ -z "$metapid" ] && eval $cmd1 || echo "Metastroe服务已启动"
		[ -z "$server2pid" ] && eval $cmd2 || echo "HiveServer2服务已启动"
		;;
	"stop")
		[ "$metapid" ] && kill $metapid || echo "Metastore服务未启动"
		[ "$server2pid" ] && kill $server2pid || echo "HiveServer2服务未启动"
		;;
	"status")
		[ $metastatus -eq 0 ] && echo "Metastroe服务已启动" || echo "Metastore服务未启动"
		[ $server2status -eq 0 ] && echo "HiveServer2服务已启动" || echo "HiveServer2服务未启动"
		;;
	esac
}
case $1 in
"start")hive_operate start;;
"stop")hive_operate stop;;
"status")hive_operate status;;
*)echo "start|stop|status";;
esac