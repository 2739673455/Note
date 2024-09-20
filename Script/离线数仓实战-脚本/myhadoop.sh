#!/bin/bash
hosts=(`cat /home/atguigu/bin/hosts.sh`)
hdfs_host=hadoop100
yarn_host=hadoop101
function hadoop_start(){
    echo ------- hadoop start -------
    ssh $hdfs_host start-dfs.sh
    ssh $yarn_host start-yarn.sh
}
function hadoop_stop(){
    echo ------- hadoop stop -------
    ssh $yarn_host stop-yarn.sh
    ssh $hdfs_host stop-dfs.sh
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
            ssh $host cat $file | diff $file - > /dev/null || echo $file on  $host is different
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
    zk_host=(
        hadoop102
        hadoop103
        hadoop104
    )
    echo ------- zookeeper $1 -------
    for host in ${zk_host[@]}; do
        echo ------- $host -------
        ssh $host zkServer.sh $1
    done
}
function kafka(){
    kafka_host=(
        hadoop102
        hadoop103
        hadoop104
    )
    echo ------- kafka $1 -------
    for host in ${kafka_host[@]}; do
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