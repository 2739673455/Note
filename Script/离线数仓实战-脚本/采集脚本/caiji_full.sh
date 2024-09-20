#!/bin/bash
#mysql中业务数据使用datax全量采集到hdfs
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
#如果传入日期则do_date等于传入的日期，否则等于前一天日期
[ -n "$2" ] && do_date=$2 || do_date=`date -d "-1 day" +%F`
datax_home=/opt/module/datax
datax_conf_path=/opt/module/gen_datax_config/configuration.properties
import_path=/opt/module/datax/job/import
database_name=edu
hdfs_path=/$database_name/db_full
table_list=(
	"base_category_info"
	"base_province"
	"base_source"
	"base_subject_info"
	"cart_info"
	"chapter_info"
	"course_info"
	"knowledge_point"
	"test_paper"
	"test_paper_question"
	"test_point_question"
	"test_question_info"
	"test_question_option"
	"user_chapter_process"
	"video_info"
)

#使用datax配置生成器生成json配置文件
active_node=`hdfs haadmin -getAllServiceState | grep active | awk -F : '{print \$1}'`  #获取HA中活动的NameNode
# active_node=`hdfs getconf -namenodes`  #获取NameNode
datax_conf_dir=`dirname $datax_conf_path`
echo mysql.username=root > $datax_conf_path
echo mysql.password=000000 >> $datax_conf_path
echo mysql.host=hadoop100 >> $datax_conf_path
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

for table in "${table_list[@]}"; do
	if [ "$1" == "$table" ] || [ "$1" == "all" ]; then
		echo "$table : mysql -> hdfs"
		import_data $import_path/$database_name.${table}.json $hdfs_path/${table}_full/$do_date
		[ "$1" != "all" ] && exit
	fi
done
[ "$1" != "all" ] && echo "table not found" || exit 0