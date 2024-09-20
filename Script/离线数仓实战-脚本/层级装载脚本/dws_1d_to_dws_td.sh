#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=edu

# 交易域用户粒度用户支付历史至今汇总表
dws_trade_user_payment_td="
insert overwrite table ${hive_db}.dws_trade_user_payment_td partition (dt = '$do_date')
select
    nvl(old.user_id, npd.user_id)                                 as user_id,
    if(payment_dt_first is null, callback_time, payment_dt_first) as payment_dt_first
from (
    select
        user_id,
        payment_dt_first
    from ${hive_db}.dws_trade_user_payment_td
    where dt = date_sub('$do_date', 1)
     ) old
full outer join(
    select
        user_id,
        max(callback_time) callback_time
    from ${hive_db}.dwd_trade_pay_detail_suc_inc
    where dt = '$do_date'
    group by user_id
               ) npd
  on old.user_id = npd.user_id;
"

# 用户域用户粒度用户登录历史至今汇总表
dws_user_user_login_td="
insert overwrite table ${hive_db}.dws_user_user_login_td partition (dt = '$do_date')
select
    nvl(old.user_id, nl.user_id)                     as user_id,
    nvl(nl.date_id, old.login_last_date)             as login_last_date,
    nvl(old.user_login_count, 0) + nvl(nl.counts, 0) as user_login_count
from (
    select
        user_id,
        login_last_date,
        user_login_count
    from ${hive_db}.dws_user_user_login_td
    where dt = date_sub('$do_date', 1)
     ) old
full outer join (
    select
        user_id,
        max(login_date) date_id,
        count(*)        counts
    from ${hive_db}.dwd_user_login_inc
    where dt = '$do_date'
    group by user_id
                ) nl
  on old.user_id = nl.user_id;
"

case $1 in
"dws_trade_user_payment_td" )hive -e "$dws_trade_user_payment_td";;
"dws_user_user_login_td" )hive -e "$dws_user_user_login_td";;
"all" )hive -e "$dws_trade_user_payment_td$dws_user_user_login_td";;
*)echo "table not found";;
esac