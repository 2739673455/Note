#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=gmall240522

ads_coupon_stats="
insert overwrite table ${hive_db}.ads_coupon_stats
select * from ${hive_db}.ads_coupon_stats
union
select
    '$do_date' dt,
    coupon_id,
    coupon_name,
    cast(sum(used_count_1d) as bigint),
    cast(count(*) as bigint)
from ${hive_db}.dws_tool_user_coupon_coupon_used_1d
where dt='$do_date'
group by coupon_id,coupon_name;
"

ads_new_order_user_stats="
insert overwrite table ${hive_db}.ads_new_order_user_stats
select * from ${hive_db}.ads_new_order_user_stats
union
select
    '$do_date' dt,
    recent_days,
    count(*) new_order_user_count
from ${hive_db}.dws_trade_user_order_td lateral view explode(array(1,7,30)) tmp as recent_days
where dt='$do_date'
and order_date_first>=date_add('$do_date',-recent_days+1)
group by recent_days;
"

ads_order_by_province="
insert overwrite table ${hive_db}.ads_order_by_province
select * from ${hive_db}.ads_order_by_province
union
select
    '$do_date' dt,
    1 recent_days,
    province_id,
    province_name,
    area_code,
    iso_code,
    iso_3166_2,
    order_count_1d,
    order_total_amount_1d
from ${hive_db}.dws_trade_province_order_1d
where dt='$do_date'
union
select
    '$do_date' dt,
    recent_days,
    province_id,
    province_name,
    area_code,
    iso_code,
    iso_3166_2,
    case recent_days
        when 7 then order_count_7d
        when 30 then order_count_30d
    end order_count,
    case recent_days
        when 7 then order_total_amount_7d
        when 30 then order_total_amount_30d
    end order_total_amount
from ${hive_db}.dws_trade_province_order_nd lateral view explode(array(7,30)) tmp as recent_days
where dt='$do_date';
"

ads_order_continuously_user_count="
insert overwrite table ${hive_db}.ads_order_continuously_user_count
select * from ${hive_db}.ads_order_continuously_user_count
union
select
    '$do_date',
    7,
    count(distinct(user_id))
from
(
    select
        user_id,
        datediff(lead(dt,2,'9999-12-31') over(partition by user_id order by dt),dt) diff
    from ${hive_db}.dws_trade_user_order_1d
    where dt>=date_add('$do_date',-6)
)t1
where diff=2;
"

ads_order_stats_by_cate="
insert overwrite table ${hive_db}.ads_order_stats_by_cate
select * from ${hive_db}.ads_order_stats_by_cate
union
select
    '$do_date' dt,
    recent_days,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    order_count,
    order_user_count
from
(
    select
        1 recent_days,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        category3_id,
        category3_name,
        sum(order_count_1d) order_count,
        count(distinct(user_id)) order_user_count
    from ${hive_db}.dws_trade_user_sku_order_1d
    where dt='$do_date'
    group by category1_id,category1_name,category2_id,category2_name,category3_id,category3_name
    union all
    select
        recent_days,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        category3_id,
        category3_name,
        sum(order_count),
        count(distinct(if(order_count>0,user_id,null)))
    from
    (
        select
            recent_days,
            user_id,
            category1_id,
            category1_name,
            category2_id,
            category2_name,
            category3_id,
            category3_name,
            case recent_days
                when 7 then order_count_7d
                when 30 then order_count_30d
            end order_count
        from ${hive_db}.dws_trade_user_sku_order_nd lateral view explode(array(7,30)) tmp as recent_days
        where dt='$do_date'
    )t1
    group by recent_days,category1_id,category1_name,category2_id,category2_name,category3_id,category3_name
)odr;
"

ads_order_stats_by_tm="
insert overwrite table ${hive_db}.ads_order_stats_by_tm
select * from ${hive_db}.ads_order_stats_by_tm
union
select
    '$do_date' dt,
    recent_days,
    tm_id,
    tm_name,
    order_count,
    order_user_count
from
(
    select
        1 recent_days,
        tm_id,
        tm_name,
        sum(order_count_1d) order_count,
        count(distinct(user_id)) order_user_count
    from ${hive_db}.dws_trade_user_sku_order_1d
    where dt='$do_date'
    group by tm_id,tm_name
    union all
    select
        recent_days,
        tm_id,
        tm_name,
        sum(order_count),
        count(distinct(if(order_count>0,user_id,null)))
    from
    (
        select
            recent_days,
            user_id,
            tm_id,
            tm_name,
            case recent_days
                when 7 then order_count_7d
                when 30 then order_count_30d
            end order_count
        from ${hive_db}.dws_trade_user_sku_order_nd lateral view explode(array(7,30)) tmp as recent_days
        where dt='$do_date'
    )t1
    group by recent_days,tm_id,tm_name
)odr;
"

ads_order_to_pay_interval_avg="
insert overwrite table ${hive_db}.ads_order_to_pay_interval_avg
select * from ${hive_db}.ads_order_to_pay_interval_avg
union
select
    '$do_date',
    cast(avg(to_unix_timestamp(payment_time)-to_unix_timestamp(order_time)) as bigint)
from ${hive_db}.dwd_trade_trade_flow_acc
where dt in ('9999-12-31','$do_date')
and payment_date_id='$do_date';
"

ads_page_path="
insert overwrite table ${hive_db}.ads_page_path
select * from ${hive_db}.ads_page_path
union
select
    '$do_date' dt,
    source,
    nvl(target,'null'),
    count(*) path_count
from
(
    select
        concat('step-',rn,':',page_id) source,
        concat('step-',rn+1,':',next_page_id) target
    from
    (
        select
            page_id,
            lead(page_id,1,null) over(partition by session_id order by view_time) next_page_id,
            row_number() over (partition by session_id order by view_time) rn
        from ${hive_db}.dwd_traffic_page_view_inc
        where dt='$do_date'
    )t1
)t2
group by source,target;
"

ads_repeat_purchase_by_tm="
insert overwrite table ${hive_db}.ads_repeat_purchase_by_tm
select * from ${hive_db}.ads_repeat_purchase_by_tm
union
select
    '$do_date',
    30,
    tm_id,
    tm_name,
    cast(sum(if(order_count>=2,1,0))/sum(if(order_count>=1,1,0)) as decimal(16,2))
from
(
    select
        user_id,
        tm_id,
        tm_name,
        sum(order_count_30d) order_count
    from ${hive_db}.dws_trade_user_sku_order_nd
    where dt='$do_date'
    group by user_id, tm_id,tm_name
)t1
group by tm_id,tm_name;
"

ads_sku_cart_num_top3_by_cate="
set hive.mapjoin.optimized.hashtable=false;
insert overwrite table ${hive_db}.ads_sku_cart_num_top3_by_cate
select * from ${hive_db}.ads_sku_cart_num_top3_by_cate
union
select
    '$do_date' dt,
    category1_id,
    category1_name,
    category2_id,
    category2_name,
    category3_id,
    category3_name,
    sku_id,
    sku_name,
    cart_num,
    rk
from
(
    select
        sku_id,
        sku_name,
        category1_id,
        category1_name,
        category2_id,
        category2_name,
        category3_id,
        category3_name,
        cart_num,
        rank() over (partition by category1_id,category2_id,category3_id order by cart_num desc) rk
    from
    (
        select
            sku_id,
            sum(sku_num) cart_num
        from ${hive_db}.dwd_trade_cart_full
        where dt='$do_date'
        group by sku_id
    )cart
    left join
    (
        select
            id,
            sku_name,
            category1_id,
            category1_name,
            category2_id,
            category2_name,
            category3_id,
            category3_name
        from ${hive_db}.dim_sku_full
        where dt='$do_date'
    )sku
    on cart.sku_id=sku.id
)t1
where rk<=3;
set hive.mapjoin.optimized.hashtable=true;
"

ads_sku_favor_count_top3_by_tm="
insert overwrite table ${hive_db}.ads_sku_favor_count_top3_by_tm
select * from ${hive_db}.ads_sku_favor_count_top3_by_tm
union
select
    '$do_date' dt,
    tm_id,
    tm_name,
    sku_id,
    sku_name,
    favor_add_count_1d,
    rk
from
(
    select
        tm_id,
        tm_name,
        sku_id,
        sku_name,
        favor_add_count_1d,
        rank() over (partition by tm_id order by favor_add_count_1d desc) rk
    from ${hive_db}.dws_interaction_sku_favor_add_1d
    where dt='$do_date'
)t1
where rk<=3;
"

ads_traffic_stats_by_channel="
insert overwrite table ${hive_db}.ads_traffic_stats_by_channel
select * from ${hive_db}.ads_traffic_stats_by_channel
union
select
    '$do_date' dt,
    recent_days,
    channel,
    cast(count(distinct(mid_id)) as bigint) uv_count,
    cast(avg(during_time_1d)/1000 as bigint) avg_duration_sec,
    cast(avg(page_count_1d) as bigint) avg_page_count,
    cast(count(*) as bigint) sv_count,
    cast(sum(if(page_count_1d=1,1,0))/count(*) as decimal(16,2)) bounce_rate
from ${hive_db}.dws_traffic_session_page_view_1d lateral view explode(array(1,7,30)) tmp as recent_days
where dt>=date_add('$do_date',-recent_days+1)
group by recent_days,channel;
"

ads_user_action="
insert overwrite table ${hive_db}.ads_user_action
select * from ${hive_db}.ads_user_action
union
select
    '$do_date' dt,
    home_count,
    good_detail_count,
    cart_count,
    order_count,
    payment_count
from
(
    select
        1 recent_days,
        sum(if(page_id='home',1,0)) home_count,
        sum(if(page_id='good_detail',1,0)) good_detail_count
    from ${hive_db}.dws_traffic_page_visitor_page_view_1d
    where dt='$do_date'
    and page_id in ('home','good_detail')
)page
join
(
    select
        1 recent_days,
        count(*) cart_count
    from ${hive_db}.dws_trade_user_cart_add_1d
    where dt='$do_date'
)cart
on page.recent_days=cart.recent_days
join
(
    select
        1 recent_days,
        count(*) order_count
    from ${hive_db}.dws_trade_user_order_1d
    where dt='$do_date'
)ord
on page.recent_days=ord.recent_days
join
(
    select
        1 recent_days,
        count(*) payment_count
    from ${hive_db}.dws_trade_user_payment_1d
    where dt='$do_date'
)pay
on page.recent_days=pay.recent_days;
"
ads_user_change="
insert overwrite table ${hive_db}.ads_user_change
select * from ${hive_db}.ads_user_change
union
select
    churn.dt,
    user_churn_count,
    user_back_count
from
(
    select
        '$do_date' dt,
        count(*) user_churn_count
    from ${hive_db}.dws_user_user_login_td
    where dt='$do_date'
    and login_date_last=date_add('$do_date',-7)
)churn
join
(
    select
        '$do_date' dt,
        count(*) user_back_count
    from
    (
        select
            user_id,
            login_date_last
        from ${hive_db}.dws_user_user_login_td
        where dt='$do_date'
        and login_date_last = '$do_date'
    )t1
    join
    (
        select
            user_id,
            login_date_last login_date_previous
        from ${hive_db}.dws_user_user_login_td
        where dt=date_add('$do_date',-1)
    )t2
    on t1.user_id=t2.user_id
    where datediff(login_date_last,login_date_previous)>=8
)back
on churn.dt=back.dt;
"

ads_user_retention="
insert overwrite table ${hive_db}.ads_user_retention
select * from ${hive_db}.ads_user_retention
union
select '$do_date' dt,
       login_date_first create_date,
       datediff('$do_date', login_date_first) retention_day,
       sum(if(login_date_last = '$do_date', 1, 0)) retention_count,
       count(*) new_user_count,
       cast(sum(if(login_date_last = '$do_date', 1, 0)) / count(*) * 100 as decimal(16, 2)) retention_rate
from (
         select user_id,
                login_date_last,
                login_date_first
         from ${hive_db}.dws_user_user_login_td
         where dt = '$do_date'
           and login_date_first >= date_add('$do_date', -7)
           and login_date_first < '$do_date'
     ) t1
group by login_date_first;
"

ads_user_stats="
insert overwrite table ${hive_db}.ads_user_stats
select * from ${hive_db}.ads_user_stats
union
select '$do_date' dt,
       recent_days,
       sum(if(login_date_first >= date_add('$do_date', -recent_days + 1), 1, 0)) new_user_count,
       count(*) active_user_count
from ${hive_db}.dws_user_user_login_td lateral view explode(array(1, 7, 30)) tmp as recent_days
where dt = '$do_date'
  and login_date_last >= date_add('$do_date', -recent_days + 1)
group by recent_days;
"

tables=(
	"ads_coupon_stats"
	"ads_new_order_user_stats"
	"ads_order_by_province"
	"ads_order_continuously_user_count"
	"ads_order_stats_by_cate"
	"ads_order_stats_by_tm"
	"ads_order_to_pay_interval_avg"
	"ads_page_path"
	"ads_repeat_purchase_by_tm"
	"ads_sku_cart_num_top3_by_cate"
	"ads_sku_favor_count_top3_by_tm"
	"ads_traffic_stats_by_channel"
	"ads_user_action"
	"ads_user_change"
	"ads_user_retention"
	"ads_user_stats"
)

case $1 in
"all")
	sql='$'$(IFS='$'; echo "${tables[*]}")
	sql=$(eval "echo \"$sql\"")
	hive -e "$sql"
	;;
*)
	for table in ${tables[@]}; do
		if [ "$table" = "$1" ]; then
			sql='$'$1
			sql=$(eval "echo \"$sql\"")
			hive -e "$sql"
			exit
		fi
	done
	echo "table not found"
esac