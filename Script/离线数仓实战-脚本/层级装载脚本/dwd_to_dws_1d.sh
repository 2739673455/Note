#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=edu

# 交易域用户粒度用户支付最近1日汇总表
dws_trade_user_payment_1d="
insert overwrite table ${hive_db}.dws_trade_user_payment_1d partition (dt = '$do_date')
select
    user_id,
    count(distinct order_id) payment_count
from ${hive_db}.dwd_trade_pay_detail_suc_inc
where dt = '$do_date'
group by user_id;
"

# 流量域会话粒度页面浏览最近1日汇总表
dws_traffic_session_page_view_1d="
insert overwrite table ${hive_db}.dws_traffic_session_page_view_1d partition (dt = '$do_date')
select
    session_id,
    mid_id,
    user_id,
    source_id,
    source_site,
    page_count,
    during_time
from (
    select
        session_id,
        mid_id,
        user_id,
        source_id,
        count(*)         page_count,
        sum(during_time) during_time
    from ${hive_db}.dwd_traffic_page_view_inc
    where dt = '$do_date'
    group by session_id, dt, mid_id, user_id, session_id, source_id
     ) t1
left join(
    select
        id,
        source_site
    from ${hive_db}.dim_source_full
    where dt = '$do_date'
         ) t2
  on source_id = t2.id;
"

tables=(
	"dws_trade_user_payment_1d"
	"dws_traffic_session_page_view_1d"
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