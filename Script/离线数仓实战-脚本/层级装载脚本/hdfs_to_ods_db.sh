#!/bin/bash
[ $# -lt 1 ] && echo "<all|ods_tableName> [date]" && exit
[ -n "$2" ] && do_date=$2 || do_date=`date -d '-1 day' +%F`
inc_prefix=/edu/db_inc
full_prefix=/edu/db_full
hive_db=edu

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
	"ods_base_category_info_full"
	"ods_base_province_full"
	"ods_base_source_full"
	"ods_base_subject_info_full"
	"ods_cart_info_full"
	"ods_chapter_info_full"
	"ods_course_info_full"
	"ods_knowledge_point_full"
	"ods_test_paper_full"
	"ods_test_paper_question_full"
	"ods_test_point_question_full"
	"ods_test_question_info_full"
	"ods_test_question_option_full"
	"ods_user_chapter_process_full"
	"ods_video_info_full"
	"ods_cart_info_inc"
	"ods_comment_info_inc"
	"ods_favor_info_inc"
	"ods_order_detail_inc"
	"ods_order_info_inc"
	"ods_payment_info_inc"
	"ods_review_info_inc"
	"ods_test_exam_inc"
	"ods_test_exam_question_inc"
	"ods_user_info_inc"
	"ods_vip_change_detail_inc"
)

case $1 in
"all")load_data ${hive_tables[@]};;
*)load_data $1;;
esac