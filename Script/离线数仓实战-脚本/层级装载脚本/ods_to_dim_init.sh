#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> date" && exit
[ -n "$2" ] && do_date="$2" || { echo "please input date"; exit; }
hive_db=edu

# 1. 省份维度表
dim_province_full="
insert overwrite table ${hive_db}.dim_province_full partition (dt = '$do_date')
select
    id,
    name,
    region_id,
    area_code,
    iso_code,
    iso_3166_2
from ${hive_db}.ods_base_province_full
where dt = '$do_date';
"

# 2. 来源维度表
dim_source_full="
insert overwrite table ${hive_db}.dim_source_full partition (dt = '$do_date')
select
    id,
    source_site
from ${hive_db}.ods_base_source_full
where dt = '$do_date';
"

# 3. 课程试卷维度表
dim_course_paper_full="
insert overwrite table ${hive_db}.dim_course_paper_full partition (dt = '$do_date')
select
    course_t.course_id,
    course_name,
    paper_id,
    paper_name,
    subject_t.subject_id,
    subject_name,
    category_t.category_id,
    category_name,
    teacher,
    publisher_id,
    chapter_num,
    origin_price,
    reduce_amount,
    actual_price,
    course_t.create_time,
    course_t.update_time
from (
    select
        id as course_id,
        course_name,
        subject_id,
        teacher,
        publisher_id,
        chapter_num,
        origin_price,
        reduce_amount,
        actual_price,
        create_time,
        update_time
    from ${hive_db}.ods_course_info_full
    where dt = '$do_date'
      and deleted = '0'
     ) as course_t
left join(
    select
        id          as paper_id,
        paper_title as paper_name,
        course_id
    from ${hive_db}.ods_test_paper_full
    where dt = '$do_date'
      and deleted = '0'
         ) as paper_t
  on course_t.course_id = paper_t.course_id
left join (
    select
        id as subject_id,
        subject_name,
        category_id
    from ${hive_db}.ods_base_subject_info_full
    where dt = '$do_date'
      and deleted = '0'
          ) as subject_t
  on course_t.subject_id = subject_t.subject_id
left join (
    select
        id as category_id,
        category_name
    from ${hive_db}.ods_base_category_info_full
    where dt = '$do_date'
      and deleted = '0'
          ) as category_t
  on subject_t.category_id = subject_t.category_id;
"

# 4. 章节视频维度表
dim_chapter_video_full="
insert overwrite table ${hive_db}.dim_chapter_video_full partition (dt = '$do_date')
select
    chapter.chapter_id,
    chapter_name,
    video.video_id,
    video_name,
    chapter.course_id,
    course_name,
    publisher_id,
    is_free,
    during_sec,
    video_status,
    video_size,
    version_id,
    create_time,
    update_time
from (
    select
        id as chapter_id,
        chapter_name,
        course_id,
        video_id,
        publisher_id,
        is_free,
        create_time,
        update_time,
        deleted
    from ${hive_db}.ods_chapter_info_full
    where dt = '$do_date'
      and deleted = '0'
     ) as chapter
left join(
    select
        id as video_id,
        video_name,
        during_sec,
        video_status,
        video_size,
        version_id
    from ${hive_db}.ods_video_info_full
    where dt = '$do_date'
      and deleted = '0'
         ) as video
  on chapter.video_id = video.video_id
left join(
    select
        id as course_id,
        course_name
    from ${hive_db}.ods_course_info_full
    where dt = '$do_date'
      and deleted = '0'
         ) as course
  on chapter.course_id = course.course_id;
"

# 5. 题目维度表
dim_question_full="
insert overwrite table ${hive_db}.dim_question_full partition (dt = '$do_date')
select
    question_id,
    chapter_id,
    chapter_name,
    course_id,
    course_name,
    question_type,
    create_time,
    update_time,
    publisher_id
from (
    select
        id as question_id,
        chapter_id,
        course_id,
        question_type,
        create_time,
        update_time,
        publisher_id
    from ${hive_db}.ods_test_question_info_full
    where dt = '$do_date'
      and deleted = '0'
     ) as question_t
left join(
    select
        id,
        chapter_name
    from ${hive_db}.ods_chapter_info_full
    where dt = '$do_date'
      and deleted = '0'
         ) as chapter_t
  on question_t.chapter_id = chapter_t.id
left join(
    select
        id,
        course_name
    from ${hive_db}.ods_course_info_full
    where dt = '$do_date'
      and deleted = '0'
         ) as course_t
  on question_t.course_id = course_t.id;
"

# 6. 用户维度表
dim_user_zip="
insert overwrite table ${hive_db}.dim_user_zip partition (dt = '9999-12-31')
select
    data.id        as user_id,
    data.real_name as user_name,
    data.phone_num,
    data.email,
    data.user_level,
    data.birthday,
    data.gender,
    data.create_time,
    data.operate_time,
    '$do_date'   as start_date,
    '9999-12-31'   as end_date
from ${hive_db}.ods_user_info_inc
where dt = '$do_date'
  and type = 'bootstrap-insert';
"

tables=(
    "dim_province_full"
    "dim_source_full"
    "dim_course_paper_full"
    "dim_chapter_video_full"
    "dim_question_full"
    "dim_user_zip"
)

case $1 in
"all")
    sql='$'$(IFS='$'; echo "${tables[*]}")
    sql=$(eval "echo \"$sql\"")
    hive -e "$sql"
    ;;
*)
    for table in ${tables[@]}; do
        if [ "$table" = "$1" ]; then
            sql='$'$1
            sql=$(eval "echo \"$sql\"")
            hive -e "$sql"
            exit
        fi
    done
    echo "table not found"
esac