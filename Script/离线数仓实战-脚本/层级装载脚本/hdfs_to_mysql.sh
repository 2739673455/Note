#!/bin/bash
#hdfs中报表数据导出到mysql
[ $# -lt 1 ] && echo "<all|tableName>" && exit
datax_home=/opt/module/datax
datax_conf_path=/opt/module/gen_datax_config/configuration.properties
export_path=/opt/module/datax/job/export
database_name=edu_report
hdfs_path=/warehouse/edu/ads
table_list=(
	"ads_chapter_video_play_stats"
	"ads_complete_chapter_per_user_by_course"
	"ads_complete_user_count_per_course"
	"ads_complete_course_index_stats"
	"ads_course_exam_avg_stats"
	"ads_course_review_stats_by_course"
	"ads_course_video_play_stats"
	"ads_exam_topic_accuracy_stats"
	"ads_examination_paper_avg_stats"
	"ads_order_by_category"
	"ads_order_by_course"
	"ads_order_by_province"
	"ads_order_by_subject"
	"ads_order_total"
	"ads_order_user_count_by_age"
	"ads_paper_fraction_distribution_stats"
	"ads_preview_retained_by_category"
	"ads_preview_retained_by_course"
	"ads_preview_retained_by_subject"
	"ads_register_order_by_source"
	"ads_traffic_page_path"
	"ads_traffic_stats_by_source"
	"ads_user_new_buyer_stats"
	"ads_user_retained_rate"
	"ads_user_user_action"
	"ads_user_user_change"
	"ads_user_user_stats"
)

active_node=`hdfs haadmin -getAllServiceState | grep active | awk -F : '{print \$1}'`
datax_conf_dir=`dirname $datax_conf_path`
echo mysql.username=root > $datax_conf_path
echo mysql.password=000000 >> $datax_conf_path
echo mysql.host=hadoop100 >> $datax_conf_path
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

for table in "${table_list[@]}"; do
	if [ "$1" == "$table" ] || [ "$1" == "all" ]; then
		echo "$table : hdfs -> mysql"
		export_data $export_path/$database_name.${table}.json $hdfs_path/${table}
		[ "$1" != "all" ] && exit
	fi
done
[ "$1" != "all" ] && echo "table not found" || exit 0
