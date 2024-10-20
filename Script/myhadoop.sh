#!/bin/bash
hosts=(`cat /home/atguigu/bin/hosts.sh`)
function hadoop_start(){
    echo ------- hadoop start -------
    ssh hadoop102 start-dfs.sh
    ssh hadoop103 start-yarn.sh
    ssh hadoop102 mapred --daemon start historyserver
}
function hadoop_stop(){
    echo ------- hadoop stop -------
    ssh hadoop102 mapred --daemon stop historyserver
    ssh hadoop103 stop-yarn.sh
    ssh hadoop102 stop-dfs.sh
}
function hadoop_clean(){
    echo ------- hadoop clean -------
    for host in ${hosts[@]}; do
        ssh $host rm -rf $HADOOP_HOME/data        
        ssh $host rm -rf $HADOOP_HOME/logs        
        ssh $host sudo rm -rf /tmp/*
    done
    echo ------- clean finish -------
}
function hadoop_compare(){
    echo ------- hadoop compare -------
    files=(
        $HADOOP_HOME/etc/hadoop/core-site.xml
        $HADOOP_HOME/etc/hadoop/hdfs-site.xml
        $HADOOP_HOME/etc/hadoop/yarn-site.xml
        $HADOOP_HOME/etc/hadoop/mapred-site.xml
        $HADOOP_HOME/etc/hadoop/workers
    )
    for file in ${files[@]}; do
        if [ ! -f $file ]; then
            echo $file not exists
            continue
        fi
        for host in ${hosts[@]}; do
            ssh $host cat $file | diff $file - > /dev/null || echo $file on $host is different
        done
    done
    echo ------- compare finish -------
}
function jpsall(){
    for host in ${hosts[@]}; do
        echo ------- $host -------
        [ "$1" == "-m" ] && ssh $host "jps -m | grep -v Jps" || ssh $host "jps | grep -v Jps"
    done
}
function zk(){
    echo ------- zookeeper $1 -------
    for host in ${hosts[@]}; do
        echo ------- $host -------
        ssh $host zkServer.sh $1
    done
}
function kafka(){
    echo ------- kafka $1 -------
    for host in ${hosts[@]}; do
        echo ------- $host -------
        case $1 in
        "start") ssh $host kafka-server-start.sh -daemon $KAFKA_HOME/config/server.properties;;
        "stop") ssh $host kafka-server-stop.sh
        esac
    done
}
case $1 in
"start")hadoop_start;;
"stop")hadoop_stop;;
"clean")hadoop_clean;;
"compare")hadoop_compare;;
"jps")jpsall $2;;
"zk")zk $2;;
"kafka")kafka $2;;
*)echo "start|stop|clean|compare|jps|zk|kafka";;
esac