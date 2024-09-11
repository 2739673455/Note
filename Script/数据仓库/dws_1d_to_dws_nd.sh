#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=gmall240522

dws_trade_province_order_nd="
insert overwrite table ${hive_db}.dws_trade_province_order_nd partition(dt='$do_date')
select
    province_id,
    province_name,
    area_code,
    iso_code,
    iso_3166_2,
    sum(if(dt>=date_add('$do_date',-6),order_count_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_original_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),activity_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),coupon_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_total_amount_1d,0)),
    sum(order_count_1d),
    sum(order_original_amount_1d),
    sum(activity_reduce_amount_1d),
    sum(coupon_reduce_amount_1d),
    sum(order_total_amount_1d)
from ${hive_db}.dws_trade_province_order_1d
where dt>=date_add('$do_date',-29)
and dt<='$do_date'
group by province_id,province_name,area_code,iso_code,iso_3166_2;
"

dws_trade_user_sku_order_nd="
insert overwrite table ${hive_db}.dws_trade_user_sku_order_nd partition(dt='$do_date')
select
    user_id,
    sku_id,
    sku_name,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    tm_id,
    tm_name,
    sum(if(dt>=date_add('$do_date',-6),order_count_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_num_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_original_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),activity_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),coupon_reduce_amount_1d,0)),
    sum(if(dt>=date_add('$do_date',-6),order_total_amount_1d,0)),
    sum(order_count_1d),
    sum(order_num_1d),
    sum(order_original_amount_1d),
    sum(activity_reduce_amount_1d),
    sum(coupon_reduce_amount_1d),
    sum(order_total_amount_1d)
from ${hive_db}.dws_trade_user_sku_order_1d
where dt>=date_add('$do_date',-30)
group by  user_id,sku_id,sku_name,category1_id,category1_name,category2_id,category2_name,category3_id,category3_name,tm_id,tm_name;
"

case $1 in
"dws_trade_province_order_nd")hive -e "$dws_trade_province_order_nd";;
"dws_trade_user_sku_order_nd")hive -e "$dws_trade_user_sku_order_nd";;
"all")hive -e "$dws_trade_province_order_nd$dws_trade_user_sku_order_nd";;
*)echo "table not found";;
esac