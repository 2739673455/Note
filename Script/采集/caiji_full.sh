#!/bin/bash
#mysql中业务数据使用datax全量采集到hdfs
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
#如果传入日期则do_date等于传入的日期，否则等于前一天日期
[ -n "$2" ] && do_date=$2 || do_date=`date -d "-1 day" +%F`
datax_home=/opt/module/datax
datax_conf_path=/opt/module/gen_datax_config/configuration.properties
import_path=/opt/module/datax/job/import
database_name=gmall
hdfs_path=/$database_name/db_full
table_list=(
	"activity_info"
	"activity_rule"
	"base_category1"
	"base_category2"
	"base_category3"
	"base_dic"
	"base_province"
	"base_region"
	"base_trademark"
	"cart_info"
	"coupon_info"
	"sku_attr_value"
	"sku_info"
	"sku_sale_attr_value"
	"spu_info"
	"promotion_pos"
	"promotion_refer"
)

#使用datax配置生成器生成json配置文件
# active_node=`hdfs haadmin -getAllServiceState | grep active | awk -F : '{print \$1}'`  #获取HA中活动的NameNode
active_node=`hdfs getconf -namenodes`  #获取NameNode
datax_conf_dir=`dirname $datax_conf_path`
echo mysql.username=root > $datax_conf_path
echo mysql.password=000000 >> $datax_conf_path
echo mysql.host=hadoop102 >> $datax_conf_path
echo mysql.port=3306 >> $datax_conf_path
echo mysql.database.import=$database_name >> $datax_conf_path
echo mysql.tables.import=$(IFS=,; echo "${table_list[*]}") >> $datax_conf_path
echo is.seperated.tables=0 >> $datax_conf_path
echo hdfs.uri=hdfs://$active_node:8020 >> $datax_conf_path
echo import_out_dir=$import_path >> $datax_conf_path
cd $datax_conf_dir;java -jar datax-config-generator-1.0-SNAPSHOT-jar-with-dependencies.jar

#数据同步
import_data() {
	datax_config=$1
	target_dir=$2
	hadoop fs -test -e $target_dir
	[ $? -eq 1 ] && hadoop fs -mkdir -p $target_dir
	python $datax_home/bin/datax.py -p"-Dtargetdir=$target_dir" $datax_config
}

flag=1
for table in "${table_list[@]}"; do
	if [ "$1" == "$table" ] || [ "$1" == "all" ]; then
		flag=0
		echo "$table : mysql -> hdfs"
		import_data $import_path/$database_name.${table}.json $hdfs_path/${table}_full/$do_date
		[ "$1" != "all" ] && exit
	fi
done
[ $flag -eq 1 ] && echo "table not found"

# case $1 in
# "all")
# 	echo "datax full start : mysql -> hdfs"
# 	for table in ${table_list[@]}; do
# 		import_data $import_path/$database_name.${table}.json $hdfs_path/${table}_full/$do_date
# 	done
# 	;;
# *)
# 	for table in "${table_list[@]}"; do
# 		if [[ "$table" == "$1" ]]; then
# 			echo "datax $1 full start : mysql -> hdfs"
# 			import_data $import_path/$database_name.${table}.json $hdfs_path/${table}_full/$do_date
# 			exit
# 		fi
# 	done
# 	echo "table not found"
# 	;;
# esac