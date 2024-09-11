#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> date" && exit
[ -n "$2" ] && do_date="$2" || { echo "please input date"; exit; }
hive_db=gmall240522

dws_trade_user_order_td="
insert overwrite table ${hive_db}.dws_trade_user_order_td partition(dt='$do_date')
select
    user_id,
    min(dt) login_date_first,
    max(dt) login_date_last,
    sum(order_count_1d) order_count,
    sum(order_num_1d) order_num,
    sum(order_original_amount_1d) original_amount,
    sum(activity_reduce_amount_1d) activity_reduce_amount,
    sum(coupon_reduce_amount_1d) coupon_reduce_amount,
    sum(order_total_amount_1d) total_amount
from ${hive_db}.dws_trade_user_order_1d
group by user_id;
"

dws_user_user_login_td="
insert overwrite table ${hive_db}.dws_user_user_login_td partition (dt = '$do_date')
select u.id                                                         user_id,
       nvl(login_date_last, date_format(create_time, 'yyyy-MM-dd')) login_date_last,
       date_format(create_time, 'yyyy-MM-dd')                       login_date_first,
       nvl(login_count_td, 1)                                       login_count_td
from (
         select id,
                create_time
         from ${hive_db}.dim_user_zip
         where dt = '9999-12-31'
     ) u
         left join
     (
         select user_id,
                max(dt)  login_date_last,
                count(*) login_count_td
         from ${hive_db}.dwd_user_login_inc
         group by user_id
     ) l
     on u.id = l.user_id;
"

case $1 in
"dws_trade_user_order_td")hive -e "$dws_trade_user_order_td";;
"dws_user_user_login_td")hive -e "$dws_user_user_login_td";;
"all")hive -e "$dws_trade_user_order_td$dws_user_user_login_td";;
*)echo "table not found";;
esac