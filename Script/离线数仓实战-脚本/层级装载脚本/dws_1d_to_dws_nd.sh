#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=edu

# 交易域用户粒度用户支付最近n日汇总表
dws_trade_user_payment_nd="
insert overwrite table ${hive_db}.dws_trade_user_payment_nd partition (dt = '$do_date')
select
    user_id,
    sum(if(dt >= date_sub('$do_date', 6), payment_count, 0)) payment_count_7d,
    sum(payment_count)                                       payment_count_30d
from ${hive_db}.dws_trade_user_payment_1d
where dt >= date_sub('$do_date', 29)
  and dt <= '$do_date'
group by user_id;
"

case $1 in
"dws_trade_user_payment_nd")hive -e "$dws_trade_user_payment_nd";;
"all")hive -e "$dws_trade_user_payment_nd";;
*)echo "table not found";;
esac