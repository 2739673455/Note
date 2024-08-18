#!/bin/bash
conf_path=/opt/module/gen_datax_config/configuration.properties
database_name=gmall
DATAX_HOME=/opt/module/datax
import_path=/opt/module/datax/job/import
hdfs_path=/$database_name/db_full
json_list=(
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
#mysql中业务数据使用datax全量采集到hdfs
if [ $# -lt 1 ]; then
	echo "all | tableName"
	exit
fi
#如果传入日期则do_date等于传入的日期，否则等于前一天日期
if [ -n "$2" ]; then
	do_date=$2
else
	do_date=`date -d "-1 day" +%F`
fi
#处理目标路径，此处的处理逻辑是，如果目标路径不存在，则创建；若存在，则清空，目的是保证同步任务可重复执行
handle_targetdir() {
	hadoop fs -test -e $1
	if [[ $? -eq 1 ]]; then
		echo "路径$1不存在，正在创建......"
		hadoop fs -mkdir -p $1
	else
		echo "路径$1已经存在"
	fi
}
#数据同步
import_data() {
	datax_config=$1
	target_dir=$2
	handle_targetdir $target_dir
	python $DATAX_HOME/bin/datax.py -p"-Dtargetdir=$target_dir" $datax_config
}
#使用datax配置生成器生成json配置文件
# active_node=`hdfs haadmin -getAllServiceState | grep active | awk -F : '{print \$1}'`  #获取HA中活动的NameNode
active_node=`hdfs getconf -namenodes`  #获取NameNode
conf_dir=`dirname $conf_path`
echo mysql.username=root > $conf_path
echo mysql.password=000000 >> $conf_path
echo mysql.host=hadoop102 >> $conf_path
echo mysql.port=3306 >> $conf_path
echo mysql.database.import=$database_name >> $conf_path
echo mysql.tables.import=$(IFS=,; echo "${json_list[*]}") >> $conf_path
echo is.seperated.tables=0 >> $conf_path
echo hdfs.uri=hdfs://$active_node:8020 >> $conf_path
echo import_out_dir=$import_path >> $conf_path
cd $conf_dir;java -jar datax-config-generator-1.0-SNAPSHOT-jar-with-dependencies.jar
#指定各个路径与库名

case $1 in
"all")
	echo "--- mysql数据全量采集到hdfs ---"
	for json in ${json_list[@]}; do
		import_data $import_path/$database_name.${json}.json $hdfs_path/${json}_full/$do_date
	done
	;;
*)
	flag=false
	for json in "${json_list[@]}"; do
		if [[ "$json" == "$1" ]]; then
			echo "--- mysql $1 数据全量采集到hdfs ---"
			import_data $import_path/$database_name.${json}.json $hdfs_path/${json}_full/$do_date
			exit
		fi
	done
	echo "table not exist"
	;;
esac
