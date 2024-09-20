#!/bin/bash
# 如果是输入的日期按照取输入日期；如果没输入日期取当前时间的前一天
[ -n "$1" ] && do_date=$1 || do_date=`date -d "-1 day" +%F`
hdfs_dir="/edu/log/$do_date"
hive_db=edu
echo "log date : $do_date"
hadoop fs -test -e $hdfs_dir
[ $? = 0 ] && sql="load data inpath '$hdfs_dir' into table ${hive_db}.ods_log_inc partition(dt='$do_date');" && hive -e "$sql" || echo "$hdfs_dir not exist"