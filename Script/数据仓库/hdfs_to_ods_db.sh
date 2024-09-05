#!/bin/bash
[ $# -lt 1 ] && echo "<all|ods_tableName> [date]" && exit
[ -n "$2" ] && do_date=$2 || do_date=`date -d '-1 day' +%F`
inc_prefix=/gmall/db_inc
full_prefix=/gmall/db_full
hive_db=gmall240522
load_data(){
    sql=""
    for i in $*; do
		suffix=${i:${#i}-3:${#i}}
		[ $suffix = "inc" ] && hdfs_dir=$inc_prefix/${i:4}/$do_date || hdfs_dir=$full_prefix/${i:4}/$do_date
        hadoop fs -test -e $hdfs_dir
        [ $? = 0 ] && sql=$sql"load data inpath '$hdfs_dir' overwrite into table ${hive_db}.$i partition(dt='$do_date');" && echo "$hdfs_dir is appended"|| echo "$hdfs_dir not exist!!!"
	done
    hive -e "$sql"
}
hive_tables=(
	"ods_activity_info_full"
	"ods_activity_rule_full"
	"ods_base_category1_full"
	"ods_base_category2_full"
	"ods_base_category3_full"
	"ods_base_dic_full"
	"ods_base_province_full"
	"ods_base_region_full"
	"ods_base_trademark_full"
	"ods_cart_info_full"
	"ods_coupon_info_full"
	"ods_sku_attr_value_full"
	"ods_sku_info_full"
	"ods_sku_sale_attr_value_full"
	"ods_spu_info_full"
	"ods_promotion_pos_full"
	"ods_promotion_refer_full"
	"ods_cart_info_inc"
	"ods_comment_info_inc"
	"ods_coupon_use_inc"
	"ods_favor_info_inc"
	"ods_order_detail_inc"
	"ods_order_detail_activity_inc"
	"ods_order_detail_coupon_inc"
	"ods_order_info_inc"
	"ods_order_refund_info_inc"
	"ods_order_status_log_inc"
	"ods_payment_info_inc"
	"ods_refund_payment_inc"
	"ods_user_info_inc"
)
case $1 in
    "all")load_data ${hive_tables[@]};;
	*)load_data $1;;
esac