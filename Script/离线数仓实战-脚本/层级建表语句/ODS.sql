-- 1. 分类表_全量
drop table if exists ods_base_category_info_full;
create external table ods_base_category_info_full
(
    id            string comment "编号",
    category_name string comment "分类名称",
    create_time   string comment "创建时间",
    update_time   string comment "更新时间",
    deleted       string comment "是否删除"
) comment "分类表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_base_category_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 2. 省份表_全量
drop table if exists ods_base_province_full;
create external table ods_base_province_full
(
    id         string comment "编号",
    name       string comment "省份名称",
    region_id  string comment "大区id",
    area_code  string comment "行政区位码",
    iso_code   string comment "国际编码",
    iso_3166_2 string comment "ISO3166 编码"
) comment "省份表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_base_province_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 3. 来源表_全量
drop table if exists ods_base_source_full;
create external table ods_base_source_full
(
    id          string comment "引流来源id",
    source_site string comment "引流来源名称",
    source_url  string comment "引流来源链接"
) comment "来源表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_base_source_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 4. 科目表_全量
drop table if exists ods_base_subject_info_full;
create external table ods_base_subject_info_full
(
    id           string comment "编号",
    subject_name string comment "科目名称",
    category_id  string comment "分类",
    create_time  string comment "创建时间",
    update_time  string comment "更新时间",
    deleted      string comment "是否删除"
) comment "科目表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_base_subject_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 5. 购物车表_全量
drop table if exists ods_cart_info_full;
create external table ods_cart_info_full
(
    id          string comment "编号",
    user_id     string comment "用户id",
    course_id   string comment "课程id",
    course_name string comment "课程名称",
    cart_price  string comment "放入购物车时价格",
    img_url     string comment "图片文件",
    session_id  string comment "会话id",
    create_time string comment "创建时间",
    update_time string comment "修改时间",
    deleted     string comment "是否删除",
    sold        string comment "是否已售"
) comment "购物车表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_cart_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 6. 章节表_全量
drop table if exists ods_chapter_info_full;
create external table ods_chapter_info_full
(
    id           string comment "编号",
    chapter_name string comment "章节名称",
    course_id    string comment "课程id",
    video_id     string comment "视频id",
    publisher_id string comment "发布者id",
    is_free      string comment "是否免费",
    create_time  string comment "创建时间",
    deleted      string comment "是否删除",
    update_time  string comment "更新时间"
) comment "章节表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_chapter_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 7. 课程信息表_全量
drop table if exists ods_course_info_full;
create external table ods_course_info_full
(
    id               string comment "编号",
    course_name      string comment "课程名称",
    course_slogan    string comment "课程标语",
    course_cover_url string comment "课程封面",
    subject_id       string comment "学科id",
    teacher          string comment "讲师名称",
    publisher_id     string comment "发布者id",
    chapter_num      string comment "章节数",
    origin_price     string comment "价格",
    reduce_amount    string comment "优惠金额",
    actual_price     string comment "实际价格",
    course_introduce string comment "课程介绍",
    create_time      string comment "创建时间",
    deleted          string comment "是否删除",
    update_time      string comment "更新时间"
) comment "课程信息表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_course_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 8. 知识点表_全量
drop table if exists ods_knowledge_point_full;
create external table ods_knowledge_point_full
(
    id           string comment "编号",
    point_txt    string comment "知识点内容",
    point_level  string comment "知识点级别",
    course_id    string comment "课程id",
    chapter_id   string comment "章节id",
    create_time  string comment "创建时间",
    update_time  string comment "修改时间",
    publisher_id string comment "发布者id",
    deleted      string comment "是否删除"
) comment "知识点表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_knowledge_point_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 9. 试卷表_全量
drop table if exists ods_test_paper_full;
create external table ods_test_paper_full
(
    id           string comment "编号",
    paper_title  string comment "试卷名称",
    course_id    string comment "课程id",
    create_time  string comment "创建时间",
    update_time  string comment "更新时间",
    publisher_id string comment "发布者id",
    deleted      string comment "是否删除"
) comment "试卷表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_test_paper_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 10. 试卷问题表_全量
drop table if exists ods_test_paper_question_full;
create external table ods_test_paper_question_full
(
    id           string comment "编号",
    paper_id     string comment "试卷id",
    question_id  string comment "题目id",
    score        string comment "得分",
    create_time  string comment "创建时间",
    deleted      string comment "是否删除",
    publisher_id string comment "发布者id"
) comment "试卷问题关联表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_test_paper_question_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 11. 知识点问题表_全量
drop table if exists ods_test_point_question_full;
create external table ods_test_point_question_full
(
    id           string comment "编号",
    point_id     string comment "知识点id",
    question_id  string comment "问题id",
    create_time  string comment "创建时间",
    publisher_id string comment "发布者id",
    deleted      string comment "是否删除"
) comment "知识点问题关联表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_test_point_question_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 12. 问题信息表_全量
drop table if exists ods_test_question_info_full;
create external table ods_test_question_info_full
(
    id            string comment "编号",
    question_txt  string comment "题目内容",
    chapter_id    string comment "章节id",
    course_id     string comment "课程id",
    question_type string comment "题目类型",
    create_time   string comment "创建时间",
    update_time   string comment "更新时间",
    publisher_id  string comment "发布者id",
    deleted       string comment "是否删除"
) comment "问题信息表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_test_question_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 13. 问题选项表_全量
drop table if exists ods_test_question_option_full;
create external table ods_test_question_option_full
(
    id          string comment "编号",
    option_txt  string comment "选项内容",
    question_id string comment "题目id",
    is_correct  string comment "是否正确",
    create_time string comment "创建时间",
    update_time string comment "更新时间",
    deleted     string comment "是否删除"
) comment "问题选项表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_test_question_option_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 14. 用户章节进度表_全量
drop table if exists ods_user_chapter_process_full;
create external table ods_user_chapter_process_full
(
    id           string comment "编号",
    course_id    string comment "课程id",
    chapter_id   string comment "章节id",
    user_id      string comment "用户id",
    position_sec string comment "时长位置",
    create_time  string comment "创建时间",
    update_time  string comment "更新时间",
    deleted      string comment "是否删除"
) comment "用户章节进度表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_user_chapter_process_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 15. 视频表_全量
drop table if exists ods_video_info_full;
create external table ods_video_info_full
(
    id              string comment "编号",
    video_name      string comment "视频名称",
    during_sec      string comment "时长",
    video_status    string comment "状态 未上传，上传中，上传完",
    video_size      string comment "大小",
    video_url       string comment "视频存储路径",
    video_source_id string comment "云端资源编号",
    version_id      string comment "版本号",
    chapter_id      string comment "章节id",
    course_id       string comment "课程id",
    publisher_id    string comment "发布者id",
    create_time     string comment "创建时间",
    update_time     string comment "更新时间",
    deleted         string comment "是否删除"
) comment "视频表"
    partitioned by (dt string)
    row format delimited fields terminated by '\t'
        null defined as ''
    location '/warehouse/edu/ods/ods_video_info_full'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 16. 购物车表_增量
drop table if exists ods_cart_info_inc;
create external table ods_cart_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, user_id :bigint, course_id :bigint, course_name :string, cart_price :decimal(16, 2),
                  img_url :string, session_id :string, create_time :string, update_time :string, deleted :string, sold
                  :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "购物车增量表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_cart_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 17. 章节评价表_增量
drop table if exists ods_comment_info_inc;
create external table ods_comment_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, user_id :bigint, chapter_id :bigint, course_id :bigint, comment_txt :string, create_time
                  :string, deleted :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "章节评价表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_comment_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 18. 收藏表_增量
drop table if exists ods_favor_info_inc;
create external table ods_favor_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, course_id :bigint, user_id :bigint, create_time :string, update_time :string, deleted
                  :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "收藏表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_favor_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 19. 订单明细表_增量
drop table if exists ods_order_detail_inc;
create external table ods_order_detail_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, course_id :bigint, course_name :string, order_id :bigint, user_id :bigint, origin_amount
                  :decimal(16, 2), coupon_reduce :decimal(16, 2), final_amount :decimal(16, 2), create_time :string,
                  update_time :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "订单明细表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_order_detail_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 20. 订单表_增量
drop table if exists ods_order_info_inc;
create external table ods_order_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, user_id :bigint, origin_amount :decimal(16, 2), coupon_reduce :decimal(16, 2),
                  final_amount :decimal(16, 2), order_status :string, out_trade_no :string, trade_body :string,
                  session_id :string, province_id :string, create_time :string, expire_time :string, update_time
                  :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "订单表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_order_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 21. 支付表_增量
drop table if exists ods_payment_info_inc;
create external table ods_payment_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, out_trade_no :string, order_id :bigint, alipay_trade_no :string, total_amount
                  :decimal(16, 2), trade_body :string, payment_type :string, payment_status :string, create_time
                  :string, update_time :string, callback_content :string, callback_time :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "支付表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_payment_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 22. 课程评价表_增量
drop table if exists ods_review_info_inc;
create external table ods_review_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, user_id :bigint, course_id :bigint, review_txt :string, review_stars :bigint, create_time
                  :string, deleted :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "课程评价表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_review_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 23. 测验表_增量
drop table if exists ods_test_exam_inc;
create external table ods_test_exam_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, paper_id :bigint, user_id :bigint, score :decimal(16, 2), duration_sec :bigint,
                  create_time :string, submit_time :string, update_time :string, deleted :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "测验表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_test_exam_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 24. 测验问题表_增量
drop table if exists ods_test_exam_question_inc;
create external table ods_test_exam_question_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, exam_id :bigint, paper_id :bigint, question_id :bigint, user_id :bigint, answer :string,
                  is_correct :string, score :decimal(16, 2), create_time :string, update_time :string, deleted
                  :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "测验问题表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_test_exam_question_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 25. 用户表_增量
drop table if exists ods_user_info_inc;
create external table ods_user_info_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, login_name :string, nick_name :string, passwd :string, real_name :string, phone_num
                  :string, email :string, head_img :string, user_level :string, birthday :string, gender :string,
                  create_time :string, operate_time :string, `status` :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "用户表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_user_info_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');

-- 26. VIP变化表_增量
drop table if exists ods_vip_change_detail_inc;
create external table ods_vip_change_detail_inc
(
    `type` string comment '变动类型',
    `ts`   bigint comment '变动时间',
    `data` struct<id :bigint, user_id :bigint, from_vip :bigint, to_vip :bigint, create_time :string> comment '数据',
    `old`  map<string,string> comment '旧值'
) comment "VIP变化表"
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_vip_change_detail_inc';

--27 日志表
drop table if exists ods_log_inc;
create external table ods_log_inc
(
    `actions`  array<struct<action_id : string, item : string, item_type : string, ts : bigint>> comment '动作（事件）',
    `common`   struct<ar : string, ba : string, ch : string, is_new : string, md : string, mid : string, os : string, sc
                      : string, sid : string, uid : string, vc : string> comment '公共信息',
    `displays` array<struct<display_type : string, item : string, item_type : string, `order` : bigint, pos_id
                            : bigint>> comment '曝光（页面显示）',
    `page`     struct<during_time : bigint, item : string, item_type : string, last_page_id : string, page_id
                      : string>comment '页面信息',
    `start`    struct<entry : string, first_open : bigint, loading_time : bigint, open_ad_id : bigint, open_ad_ms
                      : bigint, open_ad_skip_ms : bigint>comment '启动信息',
    `appVideo` struct<play_sec : bigint, position_sec : bigint, video_id : string>comment '播放信息',
    `err`      struct<error_code : bigint, msg : string>comment '错误信息',
    `ts`       bigint comment '跳入时间戳'
) comment '日志表'
    partitioned by (dt string)
    row format serde 'org.apache.hadoop.hive.serde2.JsonSerDe'
    location '/warehouse/edu/ods/ods_log_inc'
    tblproperties ('compression.codec' = 'org.apache.hadoop.io.compress.GzipCodec');
	
	