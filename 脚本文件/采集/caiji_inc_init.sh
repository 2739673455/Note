#!/bin/bash
#mysql中业务数据使用maxwell首次采集历史全量到kafka
#该脚本的作用是初始化所有的增量表，只需执行一次
[ $# -lt 1 ] && echo "all | tableName" && exit
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

case $1 in
"all")
	echo "maxwell inc init start : mysql -> kafka"
	for table in ${table_list[@]}; do
		import_data $table
	done
	;;
*)
	for table in "${table_list[@]}"; do
		if [[ "$table" == "$1" ]]; then
			echo "maxwell $1 inc init start : mysql -> kafka"
			import_data $table
			exit
		fi
	done
	echo "table not exist"
	;;
esac