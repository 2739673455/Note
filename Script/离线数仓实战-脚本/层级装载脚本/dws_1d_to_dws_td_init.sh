#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> date" && exit
[ -n "$2" ] && do_date="$2" || { echo "please input date"; exit; }
hive_db=edu

# 交易域用户粒度用户支付历史至今汇总表
dws_trade_user_payment_td="
set hive.exec.dynamic.partition.mode = nonstrict;
insert overwrite table ${hive_db}.dws_trade_user_payment_td partition (dt)
select
    user_id,
    min(callback_time) as first_pay_time,
    min(callback_time) as dt
from ${hive_db}.dwd_trade_pay_detail_suc_inc
where dt <= '$do_date'
group by user_id;
"

# 用户域用户粒度用户登录历史至今汇总表
dws_user_user_login_td="
insert overwrite table ${hive_db}.dws_user_user_login_td partition (dt = '$do_date')
select
    user_id,
    max(login_date) date_id,
    count(*)        counts
from ${hive_db}.dwd_user_login_inc
where dt <= '$do_date'
group by user_id
"

case $1 in
"dws_trade_user_payment_td" )hive -e "$dws_trade_user_payment_td";;
"dws_user_user_login_td" )hive -e "$dws_user_user_login_td";;
"all" )hive -e "$dws_trade_user_payment_td$dws_user_user_login_td";;
*)echo "table not found";;
esac