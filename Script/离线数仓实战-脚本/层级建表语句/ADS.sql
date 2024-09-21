-- 1.1 各来源流量统计
drop table if exists ads_traffic_stats_by_source;
create external table ads_traffic_stats_by_source
(
    dt               string comment '统计日期',
    recent_days      bigint comment '最近天数,1:最近1天,7:最近7天,30:最近30天',
    source_id           string comment '引流来源id',
    source_site      string comment '引流来源名称',
    uv_count         bigint comment '访客人数',
    avg_duration_sec bigint comment '会话平均停留时长，单位为秒',
    avg_page_count   bigint comment '会话平均浏览页面数',
    sv_count         bigint comment '会话数',
    bounce_rate      decimal(16, 2) comment '跳出率'
) comment '各引流来源流量统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_traffic_stats_by_source/';

-- 1.2 路径分析
drop table if exists ads_traffic_page_path;
create external table ads_traffic_page_path
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近1天,7:最近7天,30:最近30天',
    source      string comment '跳转起始页面id',
    target      string comment '跳转终到页面id',
    path_count  bigint comment '跳转次数'
) comment '页面浏览路径分析'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_traffic_page_path/';

-- 1.3 各来源下单统计
drop table if exists ads_register_order_by_source;
create table ads_register_order_by_source
(
    dt           string comment '统计日期',
    recent_days  bigint comment '统计周期',
    source_id    string comment '来源id',
    source_name  string comment '来源名称',
    final_amount decimal(16, 2) comment '销售额',
    convert_rate string comment '转化率'
) comment '各来源下单统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_register_order_by_source';

-- 2.1 用户变动统计
drop table if exists ads_user_user_change;
create external table ads_user_user_change
(
    dt     string comment '统计日期',
    user_churn_count  bigint comment '流失用户数',
    user_back_count   bigint comment '回流用户数'
)   comment '用户变动统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_user_user_change/';

-- 2.2 用户留存率
drop table if exists ads_user_retained_rate;
create table ads_user_retained_rate
(
    dt               string comment '统计日期',
    register_date    string comment '注册日期',
    register_count   bigint comment '新增用户数',
    retained_rate_1d string comment '1日后留存率',
    retained_rate_2d string comment '2日后留存率',
    retained_rate_3d string comment '3日后留存率',
    retained_rate_4d string comment '4日后留存率',
    retained_rate_5d string comment '5日后留存率',
    retained_rate_6d string comment '6日后留存率',
    retained_rate_7d string comment '7日后留存率'
) comment '用户留存率'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_user_retained_rate';

-- 2.3 用户新增活跃统计
drop table if exists ads_user_user_stats;
create external table ads_user_user_stats
(
    dt                string comment '统计日期',
    recent_days       bigint comment '最近n日,1:最近1日,7:最近7日,30:最近30日',
    new_user_count    bigint comment '新增用户数',
    active_user_count bigint comment '活跃用户数'
) comment '用户新增活跃统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_user_user_stats/';
	
-- 2.4 用户行为漏斗分析
drop table if exists ads_user_user_action;
create external table ads_user_user_action
(
    dt                string comment '统计日期',
    recent_days       bigint comment '最近天数,1:最近1天,7:最近7天,30:最近30天',
    home_count        bigint comment '浏览首页人数',
    good_detail_count bigint comment '浏览课程详情页人数',
    cart_count        bigint comment '加入购物车人数',
    order_count       bigint comment '下单人数',
    payment_count     bigint comment '支付人数'
) comment '用户行为漏斗分析'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_user_user_action/';

-- 2.5 新增交易用户统计
drop table if exists ads_user_new_buyer_stats;
create external table ads_user_new_buyer_stats
(
    dt                     string comment '统计日期',
    recent_days            bigint comment '最近天数,1:最近1天,7:最近7天,30:最近30天',
    new_order_user_count   bigint comment '新增下单人数',
    new_payment_user_count bigint comment '新增支付人数'
) comment '新增交易用户统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_user_new_buyer_stats/';

-- 2.6 各年龄段下单用户数
drop table if exists ads_order_user_count_by_age;
create table ads_order_user_count_by_age
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近1/7/30日',
    age_range   string comment '年龄范围',
    user_count  bigint comment '下单人数'
) comment '各年龄段下单用户数统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_user_count_by_age';
	
-- 3.1 各分类课程交易统计
drop table if exists ads_order_by_category;
create table ads_order_by_category
(
    dt            string comment '统计日期',
    days          bigint comment '最近1/7/30日',
    category_id   string comment '分类id',
    category_name string comment '分类名称',
    order_count   bigint comment '下单数',
    user_count    bigint comment '下单人数',
    final_amount  decimal(16, 2) comment '结算金额'
) comment '各分类课程交易统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_by_category';

-- 3.2 各学科课程交易统计
drop table if exists ads_order_by_subject;
create table ads_order_by_subject
(
    dt           string comment '统计日期',
    days         bigint comment '最近1/7/30日',
    subject_id   string comment '学科id',
    subject_name string comment '学科名称',
    order_count  bigint comment '下单数',
    user_count   bigint comment '下单人数',
    final_amount decimal(16, 2) comment '结算金额'
) comment '各学科课程交易统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_by_subject';

-- 3.3 各课程交易统计
drop table if exists ads_order_by_course;
create table ads_order_by_course
(
    dt           string comment '统计日期',
    days         bigint comment '最近1/7/30日',
    course_id    string comment '课程id',
    course_name  string comment '课程名称',
    order_count  bigint comment '下单数',
    user_count   bigint comment '下单人数',
    final_amount decimal(16, 2) comment '结算金额'
) comment '各课程交易统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_by_course';

-- 3.4 各课程评价统计
drop table if exists ads_course_review_stats_by_course;
create external table ads_course_review_stats_by_course
(
    dt                string comment '统计日期',
    recent_days       bigint comment '最近1/7/30日',
    course_id         string comment '课程id',
    course_name       string comment '课程名称',
    avg_stars         bigint comment '用户平均评分',
    review_user_count bigint comment '评价用户数',
    praise_rate       decimal(16, 2) comment '好评率'
) comment '各课程评价统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_course_review_stats_by_course/';

-- 3.5 各分类课程试听留存统计
drop table if exists ads_preview_retained_by_category;
create table ads_preview_retained_by_category
(
    dt            string comment '统计日期',
    recent_days   bigint comment '最近1-7日',
    category_id   string comment '分类id',
    category_name string comment '分类名称',
    preview_count bigint comment '试听人数',
    retained_rate string comment '留存率'
) comment '各分类课程试听留存统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_preview_retained_by_category';

-- 3.6 各学科课程试听留存统计
drop table if exists ads_preview_retained_by_subject;
create table ads_preview_retained_by_subject
(
    dt            string comment '统计日期',
    recent_days   bigint comment '最近1-7日',
    subject_id    string comment '学科id',
    subject_name  string comment '学科名称',
    preview_count bigint comment '试听人数',
    retained_rate string comment '留存率'
) comment '各学科课程试听留存统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_preview_retained_by_subject';

-- 3.7 各课程试听留存统计
drop table if exists ads_preview_retained_by_course;
create table ads_preview_retained_by_course
(
    dt            string comment '统计日期',
    recent_days   bigint comment '最近1-7日',
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    preview_count bigint comment '试听人数',
    retained_rate string comment '留存率'
) comment '各课程试听留存统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_preview_retained_by_course';

-- 4.1 交易综合统计
drop table if exists ads_order_total;
create table ads_order_total
(
    dt           string comment '统计日期',
    days         bigint comment '最近1/7/30日',
    order_count  bigint comment '下单数',
    user_count   bigint comment '下单人数',
    final_amount decimal(16, 2) comment '结算金额'
) comment '交易综合统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_total';

-- 4.2 各省份交易统计
drop table if exists ads_order_by_province;
create table ads_order_by_province
(
    dt            string comment '统计日期',
    days          bigint comment '最近1/7/30日',
    province_id   string comment '省份id',
    province_name string comment '省份名称',
    region_id     string comment '大区id',
    area_code     string comment '行政区位码',
    iso_code      string comment '国际编码',
    iso_3166_2    string comment 'ISO3166 编码',
    order_count   bigint comment '下单数',
    user_count    bigint comment '下单人数',
    final_amount  decimal(16, 2) comment '结算金额'
) comment '各省份交易统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_order_by_province';

-- 5.1 各试卷相关指标统计
drop table if exists ads_examination_paper_avg_stats;
create table ads_examination_paper_avg_stats
(
    dt               string comment '统计日期',
    recent_days      bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    paper_id         string comment '试卷id',
    paper_name       string comment '试卷名称',
    avg_score        decimal(16, 2) comment '平均分',
    avg_duration_sec decimal(16, 2) comment '平均时长',
    count_user       bigint comment '用户数'
) comment '各试卷相关指标统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_examination_paper_avg_stats/';

-- 5.2 各课程考试相关指标统计
drop table if exists ads_course_exam_avg_stats;
create table ads_course_exam_avg_stats
(
    dt               string comment '统计日期',
    recent_days      bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    course_id        string comment '课程id',
    course_name      string comment '课程名称',
    avg_score        decimal(16, 2) comment '平均分',
    avg_duration_sec decimal(16, 2) comment '平均时长',
    count_user_id    bigint comment '用户数'
) comment '各课程考试相关指标统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_course_exam_avg_stats/';

-- 5.3 各试卷分数分布统计
drop table if exists ads_paper_fraction_distribution_stats;
create table ads_paper_fraction_distribution_stats
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    paper_id      string comment '试卷id',
    paper_name    string comment '试卷名称',
    score_range   string comment '分数段',
    sum_user      bigint comment '用户数'
) comment '各试卷分数分布统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_paper_fraction_distribution_stats/';

-- 5.4 各题目正确率统计
drop table if exists ads_exam_topic_accuracy_stats;
create table ads_exam_topic_accuracy_stats
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    question_id   string comment '题目id',
    accuracy      string comment '正确率'
) comment '各题目正确率统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_exam_topic_accuracy_stats/';

-- 6.1 各章节视频播放情况统计
drop table if exists ads_chapter_video_play_stats;
create table ads_chapter_video_play_stats
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    chapter_id    string comment '章节id',
    chapter_name  string comment '章节名称',
    video_player  bigint comment '视频播放次数',
    avg_view_time bigint comment '人均观看时长',
    view_people   bigint comment '观看人数'
) comment '各章节视频播放情况统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_chapter_video_play_stats/';

-- 6.2 各课程视频播放情况统计
drop table if exists ads_course_video_play_stats;
create table ads_course_video_play_stats
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    video_count   bigint comment '视频播放次数',
    avg_view_time bigint comment '人均观看时长',
    view_people   bigint comment '观看人数'
) comment '各课程视频播放情况统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_course_video_play_stats/';

-- 7.1 各课程完课人数统计
drop table if exists ads_complete_user_count_per_course;
create external table ads_complete_user_count_per_course
(
    dt          string comment '统计日期',
    recent_days bigint comment '最近天数,1:最近1天,7:最近7天,30:最近30天',
    course_id   string comment '课程id',
    user_count  bigint comment '完课人数'
) comment '各课程完课人数'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_complete_user_count_per_course/';

-- 7.2 完课综合指标
drop table if exists ads_complete_course_index_stats;
create table ads_complete_course_index_stats
(
    dt                  string comment '统计日期',
    recent_days         bigint comment '最近天数,1:最近 1 天,7:最近 7天,30:最近 30 天',
    sum_complete_course   bigint comment '总完课人数',
    count_complete_course bigint comment '总完课人次'
) comment '各课程视频播放情况统计'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_complete_course_index_stats/';

-- 7.3 各个课程人均完成章节数
drop table if exists ads_complete_chapter_per_user_by_course;
create table ads_complete_chapter_per_user_by_course
(
    dt                        string comment '统计日期',
    recent_days               bigint comment '最近1/7/30日',
    course_id                 string comment '课程id',
    course_name               string comment '课程名称',
    complete_chapter_per_user decimal(16, 2) comment '人均完成章节数'
) comment '各个课程人均完成章节数'
    row format delimited fields terminated by '\t'
    location '/warehouse/edu/ads/ads_complete_chapter_per_user_by_course';