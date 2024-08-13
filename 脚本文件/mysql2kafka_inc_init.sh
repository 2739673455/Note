#!/bin/bash
#mysql中业务数据使用maxwell首次采集历史全量到kafka
#该脚本的作用是初始化所有的增量表，只需执行一次
if [ $# -lt 1 ];then
	echo "all | tableName"
	exit
fi
MAXWELL_HOME=/opt/module/maxwell-1.29.2
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
	$MAXWELL_HOME/bin/maxwell-bootstrap --database gmall --table $1 --config $MAXWELL_HOME/config.properties
}

case $1 in
"all")
	echo "--- mysql数据首次采集历史全量到kafka ---"
	for table in ${table_list[@]}; do
		import_data $table
	done
	;;
*)
	flag=false
	for table in "${table_list[@]}"; do
		if [[ "$table" == "$1" ]]; then
			flag=true
			break
		fi
	done
	if [[ $flag == true ]]; then
		echo "--- mysql $1 数据首次采集历史全量到kafka ---"
		import_data $1
	else
		echo "table not exist"
	fi
	;;
esac