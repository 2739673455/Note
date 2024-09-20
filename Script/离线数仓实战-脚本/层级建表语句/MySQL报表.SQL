# 1.1 各来源流量统计
DROP TABLE IF EXISTS `ads_traffic_stats_by_source`;
CREATE TABLE `ads_traffic_stats_by_source`
(
    `dt`               date                                                   NOT NULL COMMENT '统计日期',
    `recent_days`      bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `source_id`        varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '引流来源id',
    `source_site`      varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '引流来源名称',
    `uv_count`         bigint(20)                                             NULL DEFAULT NULL COMMENT '访客人数',
    `avg_duration_sec` bigint(20)                                             NULL DEFAULT NULL COMMENT '会话平均停留时长，单位为秒',
    avg_page_count     bigint(20)                                             NULL DEFAULT NULL COMMENT '会话平均浏览页面数',
    sv_count           bigint(20)                                             NULL DEFAULT NULL COMMENT '会话数',
    `bounce_rate`      decimal(16, 2)                                         NULL DEFAULT NULL COMMENT '跳出率',
    PRIMARY KEY (`dt`, `recent_days`, `source_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各来源流量统计'
  ROW_FORMAT = DYNAMIC;

# 1.2 路径分析
DROP TABLE IF EXISTS `ads_traffic_page_path`;
CREATE TABLE `ads_traffic_page_path`
(
    `dt`          date                                                    NOT NULL COMMENT '统计日期',
    `recent_days` bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `source`      varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '跳转起始页面id',
    `target`      varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '跳转终到页面id',
    `path_count`  bigint(20)                                              NULL DEFAULT NULL COMMENT '跳转次数',
    PRIMARY KEY (`dt`, `recent_days`, `source`, `target`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '页面浏览路径分析'
  ROW_FORMAT = DYNAMIC;

# 1.3 各来源下单统计
DROP TABLE IF EXISTS `ads_register_order_by_source`;
CREATE TABLE `ads_register_order_by_source`
(
    `dt`           date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`  bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `source_id`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '来源id',
    `source_name`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '来源名称',
    `final_amount` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '销售额',
    `convert_rate` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '转化率',
    PRIMARY KEY (`dt`, `recent_days`, `source_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各来源下单统计'
  ROW_FORMAT = DYNAMIC;

# 2.1 用户变动统计
DROP TABLE IF EXISTS `ads_user_user_change`;
CREATE TABLE `ads_user_user_change`
(
    `dt`               date       NOT NULL COMMENT '统计日期',
    `user_churn_count` bigint(20) NOT NULL COMMENT '流失用户数',
    `user_back_count`  bigint(20) NULL DEFAULT NULL COMMENT '回流用户数',
    PRIMARY KEY (`dt`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '用户变动统计'
  ROW_FORMAT = DYNAMIC;

# 2.2 用户留存率
DROP TABLE IF EXISTS `ads_user_retained_rate`;
CREATE TABLE `ads_user_retained_rate`
(
    `dt`               date                                                   NOT NULL COMMENT '统计日期',
    `recent_days`      varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '注册日期',
    `register_count`   bigint(20)                                             NULL DEFAULT NULL COMMENT '新增用户数',
    `retained_rate_1d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '1日后留存率',
    `retained_rate_2d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '2日后留存率',
    `retained_rate_3d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '3日后留存率',
    `retained_rate_4d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '4日后留存率',
    `retained_rate_5d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '5日后留存率',
    `retained_rate_6d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '6日后留存率',
    `retained_rate_7d` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '7日后留存率',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '用户留存率'
  ROW_FORMAT = DYNAMIC;

# 2.3 用户新增活跃统计
DROP TABLE IF EXISTS `ads_user_user_stats`;
CREATE TABLE `ads_user_user_stats`
(
    `dt`                date       NOT NULL COMMENT '统计日期',
    `recent_days`       bigint(20) NOT NULL COMMENT '统计周期',
    `new_user_count`    bigint(20) NULL DEFAULT NULL COMMENT '新增用户数',
    `active_user_count` bigint(20) NULL DEFAULT NULL COMMENT '活跃用户数',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '用户新增活跃统计'
  ROW_FORMAT = DYNAMIC;

# 2.4 用户行为漏斗分析
DROP TABLE IF EXISTS `ads_user_user_action`;
CREATE TABLE `ads_user_user_action`
(
    `dt`                varchar(50) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '统计日期',
    `recent_days`       bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `home_count`        bigint(20)                                             NULL DEFAULT NULL COMMENT '浏览首页人数',
    `good_detail_count` bigint(20)                                             NULL DEFAULT NULL COMMENT '浏览课程详情页人数',
    `cart_count`        bigint(20)                                             NULL DEFAULT NULL COMMENT '加入购物车人数',
    `order_count`       bigint(20)                                             NULL DEFAULT NULL COMMENT '下单人数',
    `payment_count`     bigint(20)                                             NULL DEFAULT NULL COMMENT '支付人数',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '用户行为漏斗分析'
  ROW_FORMAT = DYNAMIC;

# 2.5 新增交易用户统计
DROP TABLE IF EXISTS `ads_user_new_buyer_stats`;
CREATE TABLE `ads_user_new_buyer_stats`
(
    `dt`                     date       NOT NULL COMMENT '统计日期',
    `recent_days`            bigint(20) NOT NULL COMMENT '最近1/7/30日',
    `new_order_user_count`   bigint(20) NULL DEFAULT NULL COMMENT '新增下单人数',
    `new_payment_user_count` bigint(20) NULL DEFAULT NULL COMMENT '新增支付人数',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '新增交易用户统计'
  ROW_FORMAT = DYNAMIC;

# 2.6 各年龄段下单用户数统计
DROP TABLE IF EXISTS `ads_order_user_count_by_age`;
CREATE TABLE `ads_order_user_count_by_age`
(
    `dt`          date                                                   NOT NULL COMMENT '统计日期',
    `recent_days` bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `age_range`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '年龄范围',
    `user_count`  bigint(20)                                             NULL DEFAULT NULL COMMENT '下单人数',
    PRIMARY KEY (`dt`, `recent_days`, `age_range`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各年龄段下单用户数统计'
  ROW_FORMAT = DYNAMIC;

# 3.1 各分类课程交易统计
DROP TABLE IF EXISTS `ads_order_by_category`;
CREATE TABLE `ads_order_by_category`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `category_id`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '分类id',
    `category_name` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分类名称',
    `order_count`   bigint(20)                                              NULL DEFAULT NULL COMMENT '下单数',
    `user_count`    bigint(20)                                              NULL DEFAULT NULL COMMENT '下单人数',
    `final_amount`  decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '结算金额',
    PRIMARY KEY (`dt`, `recent_days`, `category_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各分类课程交易统计'
  ROW_FORMAT = DYNAMIC;

# 3.2 各学科课程交易统计
DROP TABLE IF EXISTS `ads_order_by_subject`;
CREATE TABLE `ads_order_by_subject`
(
    `dt`           date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`  bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `subject_id`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '学科id',
    `subject_name` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '学科名称',
    `order_count`  bigint(20)                                              NULL DEFAULT NULL COMMENT '下单数',
    `user_count`   bigint(20)                                              NULL DEFAULT NULL COMMENT '下单人数',
    `final_amount` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '结算金额',
    PRIMARY KEY (`dt`, `recent_days`, `subject_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各学科课程交易统计'
  ROW_FORMAT = DYNAMIC;

# 3.3 各课程交易统计
DROP TABLE IF EXISTS `ads_order_by_course`;
CREATE TABLE `ads_order_by_course`
(
    `dt`           date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`  bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程id',
    `course_name`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `order_count`  bigint(20)                                              NULL DEFAULT NULL COMMENT '下单数',
    `user_count`   bigint(20)                                              NULL DEFAULT NULL COMMENT '下单人数',
    `final_amount` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '结算金额',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程交易统计'
  ROW_FORMAT = DYNAMIC;

# 3.4 各课程评价统计
DROP TABLE IF EXISTS `ads_course_review_stats_by_course`;
CREATE TABLE `ads_course_review_stats_by_course`
(
    `dt`                date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`       bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`         varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程ID',
    `course_name`       varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `avg_stars`         bigint(20)                                              NOT NULL COMMENT '用户平均评分',
    `review_user_count` bigint(20)                                              NOT NULL COMMENT '评价用户数',
    `praise_rate`       decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '好评率',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程评价统计'
  ROW_FORMAT = DYNAMIC;

# 3.5 各分类课程试听留存统计
DROP TABLE IF EXISTS `ads_preview_retained_by_category`;
CREATE TABLE `ads_preview_retained_by_category`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `category_id`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '分类id',
    `category_name` varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '分类名称',
    `preview_count` bigint(20)                                              NULL DEFAULT NULL COMMENT '试听人数',
    `retained_rate` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '留存率',
    PRIMARY KEY (`dt`, `recent_days`, `category_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各分类课程试听留存统计'
  ROW_FORMAT = DYNAMIC;

# 3.6 各学科课程试听留存统计
DROP TABLE IF EXISTS `ads_preview_retained_by_subject`;
CREATE TABLE `ads_preview_retained_by_subject`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `subject_id`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '学科id',
    `subject_name`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '学科名称',
    `preview_count` bigint(20)                                              NULL DEFAULT NULL COMMENT '试听人数',
    `retained_rate` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '留存率',
    PRIMARY KEY (`dt`, `recent_days`, `subject_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各学科课程试听留存统计'
  ROW_FORMAT = DYNAMIC;

# 3.7 各课程试听留存统计
DROP TABLE IF EXISTS `ads_preview_retained_by_course`;
CREATE TABLE `ads_preview_retained_by_course`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`     varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程id',
    `course_name`   varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `preview_count` bigint(20)                                              NULL DEFAULT NULL COMMENT '试听人数',
    `retained_rate` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '留存率',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程试听留存统计'
  ROW_FORMAT = DYNAMIC;

# 4.1 交易综合统计
DROP TABLE IF EXISTS `ads_order_total`;
CREATE TABLE `ads_order_total`
(
    `dt`           date           NOT NULL COMMENT '统计日期',
    `recent_days`  bigint(20)     NOT NULL COMMENT '最近1/7/30日',
    `order_count`  bigint(20)     NULL DEFAULT NULL COMMENT '下单数',
    `user_count`   bigint(20)     NULL DEFAULT NULL COMMENT '下单人数',
    `final_amount` decimal(16, 2) NULL DEFAULT NULL COMMENT '结算金额',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '交易综合统计'
  ROW_FORMAT = DYNAMIC;

# 4.2 各省份交易统计
DROP TABLE IF EXISTS `ads_order_by_province`;
CREATE TABLE `ads_order_by_province`
(
    `dt`            date                                                   NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `province_id`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '省份id',
    `province_name` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '省份名称',
    `region_id`     varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '大区id',
    `area_code`     varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '行政区位码',
    `iso_code`      varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '国际编码',
    iso_3166_2      varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT 'ISO3166 编码',
    order_count     bigint(20)                                             NULL DEFAULT NULL COMMENT '下单数',
    user_count      bigint(20)                                             NULL DEFAULT NULL COMMENT '下单人数',
    `final_amount`  decimal(16, 2)                                         NULL DEFAULT NULL COMMENT '结算金额',
    PRIMARY KEY (`dt`, `recent_days`, `province_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各省份交易统计'
  ROW_FORMAT = DYNAMIC;

# 5.1 各试卷相关指标统计
DROP TABLE IF EXISTS `ads_examination_paper_avg_stats`;
CREATE TABLE `ads_examination_paper_avg_stats`
(
    `dt`               date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`      bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `paper_id`         varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '试卷id',
    `paper_name`       varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '试卷名称',
    `avg_score`        varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '平均分',
    `avg_duration_sec` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '平均时长',
    `count_user`       decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '用户数',
    PRIMARY KEY (`dt`, `recent_days`, `paper_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各试卷相关指标统计'
  ROW_FORMAT = DYNAMIC;

# 5.2 各课程考试相关指标统计
DROP TABLE IF EXISTS `ads_course_exam_avg_stats`;
CREATE TABLE `ads_course_exam_avg_stats`
(
    `dt`               date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`      bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`        varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程ID',
    `course_name`      varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `avg_score`        varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '平均分',
    `avg_duration_sec` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '平均时长',
    `count_user_id`    bigint(20)                                              NOT NULL COMMENT '用户数',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程考试相关指标统计'
  ROW_FORMAT = DYNAMIC;

# 5.3 各试卷分数分布统计
DROP TABLE IF EXISTS `ads_paper_fraction_distribution_stats`;
CREATE TABLE `ads_paper_fraction_distribution_stats`
(
    `dt`          date                                                    NOT NULL COMMENT '统计日期',
    `recent_days` bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `paper_id`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '试卷id',
    `paper_name`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '试卷名称',
    `score_range` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '分数段',
    `user_count`  bigint(20)                                              NULL DEFAULT NULL COMMENT '下单人数',
    PRIMARY KEY (`dt`, `recent_days`, `paper_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各试卷分数分布统计'
  ROW_FORMAT = DYNAMIC;

# 5.4 各题目正确率统计
DROP TABLE IF EXISTS `ads_exam_topic_accuracy_stats`;
CREATE TABLE `ads_exam_topic_accuracy_stats`
(
    `dt`          date                                                   NOT NULL COMMENT '统计日期',
    `recent_days` bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `question_id` varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '题目id',
    `accuracy`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '正确率',
    PRIMARY KEY (`dt`, `recent_days`, `question_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各题目正确率统计'
  ROW_FORMAT = DYNAMIC;

# 6.1 各章节视频播放情况统计
DROP TABLE IF EXISTS `ads_chapter_video_play_stats`;
CREATE TABLE `ads_chapter_video_play_stats`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `chapter_id`    varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '章节id',
    `chapter_name`  varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NULL DEFAULT NULL COMMENT '章节名称',
    `video_player`  bigint(20)                                              NULL DEFAULT NULL COMMENT '视频播放次数',
    `avg_view_time` bigint(20)                                              NULL DEFAULT NULL COMMENT '人均观看时长',
    `view_people`   bigint(20)                                              NULL DEFAULT NULL COMMENT '观看人数',
    PRIMARY KEY (`dt`, `recent_days`, `chapter_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各章节视频播放情况统计'
  ROW_FORMAT = DYNAMIC;

# 6.2 各课程视频播放情况统计
DROP TABLE IF EXISTS `ads_course_video_play_stats`;
CREATE TABLE `ads_course_video_play_stats`
(
    `dt`            date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`   bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`     varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程ID',
    `course_name`   varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `video_count`   bigint(20)                                              NULL DEFAULT NULL COMMENT '视频播放次数',
    `avg_view_time` bigint(20)                                              NULL DEFAULT NULL COMMENT '人均观看时长',
    `view_people`   bigint(20)                                              NULL DEFAULT NULL COMMENT '观看人数',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程视频播放情况统计'
  ROW_FORMAT = DYNAMIC;

# 7.1 各课程完课人数统计
DROP TABLE IF EXISTS `ads_complete_user_count_per_course`;
CREATE TABLE `ads_complete_user_count_per_course`
(
    `dt`          date                                                   NOT NULL COMMENT '统计日期',
    `recent_days` bigint(20)                                             NOT NULL COMMENT '最近1/7/30日',
    `course_id`   varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程 id',
    `user_count`  bigint(20)                                             NOT NULL COMMENT '用户数''完课人数',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE

) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程完课人数统计'
  ROW_FORMAT = DYNAMIC;

# 7.2 完课综合指标
DROP TABLE IF EXISTS `ads_complete_course_index_stats`;
CREATE TABLE `ads_complete_course_index_stats`
(
    `dt`                    date       NOT NULL COMMENT '统计日期',
    `recent_days`           bigint(20) NOT NULL COMMENT '最近1/7/30日',
    `sum_complete_course`   bigint(20) NULL DEFAULT NULL COMMENT '总完课人数',
    `count_complete_course` bigint(20) NULL DEFAULT NULL COMMENT '总完课人次',
    PRIMARY KEY (`dt`, `recent_days`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '完课综合指标'
  ROW_FORMAT = DYNAMIC;

# 7.3 各课程人均完成章节视频数统计
DROP TABLE IF EXISTS `ads_complete_chapter_per_user_by_course`;
CREATE TABLE `ads_complete_chapter_per_user_by_course`
(
    `dt`                        date                                                    NOT NULL COMMENT '统计日期',
    `recent_days`               bigint(20)                                              NOT NULL COMMENT '最近1/7/30日',
    `course_id`                 varchar(16) CHARACTER SET utf8 COLLATE utf8_general_ci  NOT NULL COMMENT '课程id',
    `course_name`               varchar(200) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL COMMENT '课程名称',
    `complete_chapter_per_user` decimal(16, 2)                                          NULL DEFAULT NULL COMMENT '人均完成章节数',
    PRIMARY KEY (`dt`, `recent_days`, `course_id`) USING BTREE
) ENGINE = InnoDB
  CHARACTER SET = utf8
  COLLATE = utf8_general_ci COMMENT = '各课程人均完成章节视频数统计'
  ROW_FORMAT = DYNAMIC;