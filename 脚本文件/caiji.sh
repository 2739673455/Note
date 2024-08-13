#!/bin/bash
#102从日志文件中采集用户行为数据到kafka
#103从kafka中采集业务数据到hdfs
#104从kafka中采集用户行为数据到hdfs
#maxwell从mysql采集增量数据到kafka
function flume_start(){
	echo "nohup ${FLUME_HOME}/bin/flume-ng agent -n a1 -c ${FLUME_HOME}/conf -f ${FLUME_HOME}/job/$1 >/dev/null 2>&1 &"
}
function flume_stop(){
	echo "ps -ef | grep $1 | grep -v grep | awk '{print \$2}' | xargs -n 1 kill -9"
}
function maxwell_status(){
    result=`ps -ef | grep com.zendesk.maxwell.Maxwell | grep -v grep | wc -l`
    return $result
}
function maxwell_start(){
    maxwell_status
    if [[ $? -lt 1 ]]; then
        echo "--- 启动 Maxwell ---"
        $MAXWELL_HOME/bin/maxwell --config $MAXWELL_HOME/config.properties --daemon
    else
        echo "--- Maxwell 正在运行 ---"
    fi
}
function maxwell_stop(){
    maxwell_status
    if [[ $? -gt 0 ]]; then
        echo "--- 停止 Maxwell ---"
        ps -ef | grep com.zendesk.maxwell.Maxwell | grep -v grep | awk '{print $2}' | xargs kill -9
    else
        echo "--- Maxwell 未在运行 ---"
    fi
}

FLUME_HOME=/opt/module/flume-1.10.1
MAXWELL_HOME=/opt/module/maxwell-1.29.2
flume_conf_01=file_to_kafka.conf
flume_conf_02=kafka_to_hdfs_db.conf
flume_conf_03=kafka_to_hdfs_log.conf

case $1 in
"102start")
	echo "--- 启动 hadoop102 上游用户行为数据采集 ---"
	ssh hadoop102 "$(flume_start $flume_conf_01)"
	;;
"102stop")
	echo "--- 停止 hadoop102 上游用户行为数据采集 ---"
	ssh hadoop102 "$(flume_stop $flume_conf_01)"
	;;
"103start")
	echo "--- 启动 hadoop103 下游业务数据采集 ---"
	ssh hadoop103 "$(flume_start $flume_conf_02)"
	;;
"103stop")
	echo "--- 停止 hadoop103 下游业务数据采集 ---"
	ssh hadoop103 "$(flume_stop $flume_conf_02)"
	;;
"104start")
	echo "--- 启动 hadoop104 下游用户行为数据采集 ---"
	ssh hadoop104 "$(flume_start $flume_conf_03)"
	;;
"104stop")
	echo "--- 停止 hadoop104 下游用户行为数据采集 ---"
	ssh hadoop104 "$(flume_stop $flume_conf_03)"
	;;
"maxwellstart")
	maxwell_start
	;;
"maxwellstop")
	maxwell_stop
	;;
"allstart")
	echo "--- 启动 hadoop102 上游用户行为数据采集 ---"
	ssh hadoop102 "$(flume_start $flume_conf_01)"
	echo "--- 启动 hadoop103 下游业务数据采集 ---"
	ssh hadoop103 "$(flume_start $flume_conf_02)"
	echo "--- 启动 hadoop104 下游用户行为数据采集 ---"
	ssh hadoop104 "$(flume_start $flume_conf_03)"
	maxwell_start
	;;
"allstop")
	echo "--- 停止 hadoop102 上游用户行为数据采集 ---"
	ssh hadoop102 "$(flume_stop $flume_conf_01)"
	echo "--- 停止 hadoop103 下游业务数据采集 ---"
	ssh hadoop103 "$(flume_stop $flume_conf_02)"
	echo "--- 停止 hadoop104 下游用户行为数据采集 ---"
	ssh hadoop104 "$(flume_stop $flume_conf_03)"
	maxwell_stop
	;;
*)
	echo "102|103|104 + start|stop"
	echo "maxwellstart|maxwellstop"
	echo "allstart|allstop"
	;;
esac