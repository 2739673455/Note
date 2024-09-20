#!/bin/bash
#mysql中业务数据使用maxwell首次采集历史全量到kafka
#该脚本的作用是初始化所有的增量表，只需执行一次
[ $# -lt 1 ] && echo "all|tableName" && exit
database_name=edu
maxwell_home=/opt/module/maxwell-1.29.2
table_list=(
	"cart_info"
	"comment_info"
	"favor_info"
	"order_detail"
	"order_info"
	"payment_info"
	"review_info"
	"test_exam"
	"test_exam_question"
	"user_info"
	"vip_change_detail"
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