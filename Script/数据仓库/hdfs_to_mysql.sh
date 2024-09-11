#!/bin/bash
#hdfs中报表数据导出到mysql
[ $# -lt 1 ] && echo "<all|tableName>" && exit
datax_home=/opt/module/datax
datax_conf_path=/opt/module/gen_datax_config/configuration.properties
export_path=/opt/module/datax/job/export
database_name=gmall_report
hdfs_path=/warehouse/gmall/ads
table_list=(
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

active_node=`hdfs getconf -namenodes`  #获取NameNode
datax_conf_dir=`dirname $datax_conf_path`
echo mysql.username=root > $datax_conf_path
echo mysql.password=000000 >> $datax_conf_path
echo mysql.host=hadoop102 >> $datax_conf_path
echo mysql.port=3306 >> $datax_conf_path
echo mysql.database.export=$database_name >> $datax_conf_path
echo mysql.tables.export= >> $datax_conf_path
echo is.seperated.tables=0 >> $datax_conf_path
echo hdfs.uri=hdfs://$active_node:8020 >> $datax_conf_path
echo export_out_dir=$export_path >> $datax_conf_path
cd $datax_conf_dir;java -jar datax-config-generator-1.0-SNAPSHOT-jar-with-dependencies.jar

#DataX导出路径不允许存在空文件，该函数作用为清理空文件
handle_export_path(){
	for i in `hadoop fs -ls -R $1 | awk '{print $8}'`; do
		hadoop fs -test -z $i
		[ $? -eq 0 ] && hadoop fs -rm -r -f $i
	done
}
#数据导出
export_data() {
	datax_config=$1
	export_dir=$2
	handle_export_path $export_dir
	$datax_home/bin/datax.py -p"-Dexportdir=$export_dir" $datax_config
}

flag=1
for table in "${table_list[@]}"; do
	if [ "$1" == "$table" ] || [ "$1" == "all" ]; then
		flag=0
		echo "$table : hdfs -> mysql"
		export_data $export_path/$database_name.${table}.json $hdfs_path/${table}
		[ "$1" != "all" ] && exit
	fi
done
[ $flag -eq 1 ] && echo "table not found"