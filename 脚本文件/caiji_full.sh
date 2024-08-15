#!/bin/bash
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
conf_path=/opt/module/datax_json_generate/configuration.properties
conf_dir=`dirname $conf_path`
active_node=`hdfs haadmin -getAllServiceState | grep active | awk -F : '{print \$1}'`
echo mysql.username=root > $conf_path
echo mysql.password=000000 >> $conf_path
echo mysql.host=hadoop102 >> $conf_path
echo mysql.port=3306 >> $conf_path
echo mysql.database.import=edu >> $conf_path
echo mysql.tables.import=base_category_info,base_province,base_source,base_subject_info,cart_info,chapter_info,comment_info,course_info,favor_info,knowledge_point,order_detail,order_info,payment_info,review_info,test_exam,test_exam_question,test_paper,test_paper_question,test_point_question,test_question_info,test_question_option,user_chapter_process,user_info,video_info,vip_change_detail >> $conf_path
echo is.seperated.tables=0 >> $conf_path
echo hdfs.uri=hdfs://$active_node:8020 >> $conf_path
echo import_out_dir=/opt/module/datax/job/import >> $conf_path
cd $conf_dir;java -jar datax-config-generator-1.0-SNAPSHOT-jar-with-dependencies.jar
#指定各个路径与库名
database_name=edu
DATAX_HOME=/opt/module/datax
import_path=/opt/module/datax/job/import
hdfs_path=/edu_data/db/full
json_list=(
	"base_category_info"
	"base_province"
	"base_source"
	"base_subject_info"
	"cart_info"
	"chapter_info"
	"comment_info"
	"course_info"
	"favor_info"
	"knowledge_point"
	"order_detail"
	"order_info"
	"payment_info"
	"review_info"
	"test_exam"
	"test_exam_question"
	"test_paper"
	"test_paper_question"
	"test_point_question"
	"test_question_info"
	"test_question_option"
	"user_chapter_process"
	"user_info"
	"video_info"
	"vip_change_detail"
)

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
