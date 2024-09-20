-- 1. 省份维度表
drop table if exists dim_province_full;
create external table dim_province_full
(
    id         string comment '省份id',
    name       string comment '省份名称',
    region_id  string comment '大区id',
    area_code  string comment '行政区位码',
    iso_code   string comment '国际编码',
    iso_3166_2 string comment 'ISO3166 编码'
) comment '省份维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_province_full'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
insert overwrite table dim_province_full partition (dt = '2022-02-26')
select
    id,
    name,
    region_id,
    area_code,
    iso_code,
    iso_3166_2
from ods_base_province_full
where dt = '2022-02-26';

-- 2. 来源维度表
drop table if exists dim_source_full;
create external table dim_source_full
(
    id          string comment '引流来源id',
    source_site string comment '引流来源名称'
) comment '来源维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_source_full'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
insert overwrite table dim_source_full partition (dt = '2022-02-26')
select
    id,
    source_site
from ods_base_source_full
where dt = '2022-02-26';

-- 3. 课程试卷维度表
drop table if exists dim_course_paper_full;
create external table dim_course_paper_full
(
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    paper_id      string comment '试卷id',
    paper_name    string comment '试卷名称',
    subject_id    string comment '科目id',
    subject_name  string comment '科目名称',
    category_id   string comment '分类id',
    category_name string comment '分类名称',
    teacher       string comment '讲师名称',
    publisher_id  string comment '发布者id',
    chapter_num   bigint comment '章节数',
    origin_price  decimal(16, 2) comment '价格',
    reduce_amount decimal(16, 2) comment '优惠金额',
    actual_price  decimal(16, 2) comment '实际价格',
    create_time   string comment '创建时间',
    update_time   string comment '更新时间'
) comment '课程试卷维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_course_paper_full'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
insert overwrite table dim_course_paper_full partition (dt = '2022-02-26')
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
    from ods_course_info_full
    where dt = '2022-02-26'
      and deleted = '0'
     ) as course_t
left join(
    select
        id          as paper_id,
        paper_title as paper_name,
        course_id
    from ods_test_paper_full
    where dt = '2022-02-26'
      and deleted = '0'
         ) as paper_t
  on course_t.course_id = paper_t.course_id
left join (
    select
        id as subject_id,
        subject_name,
        category_id
    from ods_base_subject_info_full
    where dt = '2022-02-26'
      and deleted = '0'
          ) as subject_t
  on course_t.subject_id = subject_t.subject_id
left join (
    select
        id as category_id,
        category_name
    from ods_base_category_info_full
    where dt = '2022-02-26'
      and deleted = '0'
          ) as category_t
  on subject_t.category_id = subject_t.category_id;

-- 4. 章节视频维度表
drop table if exists dim_chapter_video_full;
create external table dim_chapter_video_full
(
    chapter_id   string comment '章节id',
    chapter_name string comment '章节名称',
    video_id     string comment '视频id',
    video_name   string comment '视频名称',
    course_id    string comment '课程id',
    course_name  string comment '课程名称',
    publisher_id string comment '发布者id',
    is_free      string comment '是否免费',
    during_sec   bigint comment '视频时长',
    video_status string comment '视频状态 未上传，上传中，上传完',
    video_size   bigint comment '视频大小',
    version_id   string comment '版本号',
    create_time  string comment '创建时间',
    update_time  string comment '更新时间'
) comment '章节视频维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_chapter_video_full'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
insert overwrite table dim_chapter_video_full partition (dt = '2022-02-26')
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
    from ods_chapter_info_full
    where dt = '2022-02-26'
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
    from ods_video_info_full
    where dt = '2022-02-26'
      and deleted = '0'
         ) as video
  on chapter.video_id = video.video_id
left join(
    select
        id as course_id,
        course_name
    from ods_course_info_full
    where dt = '2022-02-26'
      and deleted = '0'
         ) as course
  on chapter.course_id = course.course_id;

-- 5. 题目维度表
drop table if exists dim_question_full;
create external table dim_question_full
(
    question_id   string comment '题目id',
    chapter_id    string comment '章节id',
    chapter_name  string comment '章节名称',
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    question_type string comment '题目类型',
    create_time   string comment '创建时间',
    update_time   string comment '更新时间',
    publisher_id  string comment '发布者id'
) comment '题目维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_question_full'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
insert overwrite table dim_question_full partition (dt = '2022-02-26')
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
    from ods_test_question_info_full
    where dt = '2022-02-26'
      and deleted = '0'
     ) as question_t
left join(
    select
        id,
        chapter_name
    from ods_chapter_info_full
    where dt = '2022-02-26'
      and deleted = '0'
         ) as chapter_t
  on question_t.chapter_id = chapter_t.id
left join(
    select
        id,
        course_name
    from ods_course_info_full
    where dt = '2022-02-26'
      and deleted = '0'
         ) as course_t
  on question_t.course_id = course_t.id;

-- 6. 时间维度表
drop table if exists dim_date;
create external table dim_date
(
    `date_id`    string comment '日期id',
    `week_id`    string comment '周id,一年中的第几周',
    `week_day`   string comment '周几',
    `day`        string comment '每月的第几天',
    `month`      string comment '一年中的第几月',
    `quarter`    string comment '一年中的第几季度',
    `year`       string comment '年份',
    `is_workday` string comment '是否是工作日',
    `holiday_id` string comment '节假日'
) comment '日期维度表'
    stored as orc
    location '/warehouse/edu/dim/dim_date/'
    tblproperties ('orc.compress' = 'snappy');
-- 数据装载
DROP TABLE IF EXISTS tmp_dim_date_info;
CREATE TABLE tmp_dim_date_info
(
    `date_id`    STRING COMMENT '日',
    `week_id`    STRING COMMENT '周ID',
    `week_day`   STRING COMMENT '周几',
    `day`        STRING COMMENT '每月的第几天',
    `month`      STRING COMMENT '第几月',
    `quarter`    STRING COMMENT '第几季度',
    `year`       STRING COMMENT '年',
    `is_workday` STRING COMMENT '是否是工作日',
    `holiday_id` STRING COMMENT '节假日'
) COMMENT '时间维度表'
    ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
    LOCATION '/warehouse/edu/tmp/tmp_dim_date_info/';

insert overwrite table dim_date
select *
from tmp_dim_date_info;

-- 7. 用户维度表
drop table if exists dim_user_zip;
create external table dim_user_zip
(
    user_id      bigint comment '用户id',
    user_name    string comment '用户姓名',
    phone_num    string comment '电话',
    email        string comment '邮箱',
    user_level   string comment '用户等级',
    birthday     string comment '生日',
    gender       string comment '性别 M男,F女',
    create_time  string comment '创建时间',
    operate_time string comment '操作时间',
    start_date   string comment '开始日期',
    end_date     string comment '结束日期'
) comment '用户维度表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dim/dim_user_zip'
    tblproperties ('orc.compress' = 'snappy');
-- 首日
insert overwrite table dim_user_zip partition (dt = '9999-12-31')
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
    '2022-02-26'   as start_date,
    '9999-12-31'   as end_date
from ods_user_info_inc
where dt = '2022-02-26'
  and type = 'bootstrap-insert';
-- 每日
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table dim_user_zip partition (dt)
select
    user_id,
    user_name,
    phone_num,
    email,
    user_level,
    birthday,
    gender,
    create_time,
    operate_time,
    start_date,
    if(rk = 1, '9999-12-31', date_sub('2022-02-27', 1)) as end_date,
    if(rk = 1, '9999-12-31', date_sub('2022-02-27', 1)) as dt
from (
    select
        row_number() over (partition by user_id order by start_date desc) as rk,
        *
    from (
        select *
        from dim_user_zip
        where dt = '9999-12-31'
        union all
        select
            user_id,
            user_name,
            phone_num,
            email,
            user_level,
            birthday,
            gender,
            create_time,
            operate_time,
            '2022-02-27' as start_date,
            '9999-12-31' as end_date,
            '9999-12-31' as dt
        from (
            select
                row_number() over (partition by data.id order by ts desc) as rk,
                data.id                                                   as user_id,
                data.real_name                                            as user_name,
                data.phone_num,
                data.email,
                data.user_level,
                data.birthday,
                data.gender,
                data.create_time,
                data.operate_time
            from ods_user_info_inc
            where dt = '2022-02-27'
              and data.real_name is not null
             ) ods_user
        where rk = 1
         ) t1
     ) t2;