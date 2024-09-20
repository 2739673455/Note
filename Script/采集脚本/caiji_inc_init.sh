#!/bin/bash
#mysql中业务数据使用maxwell首次采集历史全量到kafka
#该脚本的作用是初始化所有的增量表，只需执行一次
[ $# -lt 1 ] && echo "all|tableName" && exit
database_name=gmall
maxwell_home=/opt/module/maxwell-1.29.2
table_list=(
	"cart_info"
	"comment_info"
	"coupon_use"
	"favor_info"
	"order_detail"
	"order_detail_activity"
	"order_detail_coupon"
	"order_info"
	"order_refund_info"
	"order_status_log"
	"payment_info"
	"refund_payment"
	"user_info"
)
import_data() {
	$maxwell_home/bin/maxwell-bootstrap --database $database_name --table $1 --config $maxwell_home/config.properties
}

for table in "${table_list[@]}"; do
	if [ "$1" == "$table" ] || [ "$1" == "all" ]; then
		echo "maxwell $table inc init start : mysql -> kafka"
		import_data $table
		[ "$1" != "all" ] && exit
	fi
done
[ "$1" != "all" ] && echo "table not found" || exit 0