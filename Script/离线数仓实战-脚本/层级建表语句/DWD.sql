-- 交易域加购事务事实表
drop table if exists dwd_trade_cart_add_inc;
create external table dwd_trade_cart_add_inc
(
    id          string comment '编号',
    user_id     string comment '用户id',
    course_id   string comment '课程id',
    date_id     string comment '时间id',
    create_time string comment '加购时间',
    cart_price  decimal(16, 2) comment '加购时价格'
) comment '交易域加购事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_trade_cart_add_inc/'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域下单事务事实表
drop table if exists dwd_trade_order_detail_inc;
create external table dwd_trade_order_detail_inc
(
    order_id      string comment '订单id',
    user_id       string comment '用户id',
    order_time    string comment '下单时间',
    order_date    string comment '下单日期',
    origin_amount decimal(16, 2) comment '原始金额',
    coupon_reduce decimal(16, 2) comment '优惠券金额',
    final_amount  decimal(16, 2) comment '结算金额',
    age           bigint comment '年龄',
    province_id   string comment '省份id',
    source_id     string comment '来源id',
    source_name   string comment '来源名称',
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    subject_id    string comment '科目id',
    subject_name  string comment '科目名称',
    category_id   string comment '分类id',
    category_name string comment '分类名称'
) comment '交易域下单事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_trade_order_detail_inc'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域支付成功事务事实表
drop table if exists dwd_trade_pay_detail_suc_inc;
create external table dwd_trade_pay_detail_suc_inc
(
    id                   string comment '编号',
    order_id             string comment '订单id',
    user_id              string comment '用户id',
    course_id            string comment '课程id',
    province_id          string comment '省份id',
    date_id              string comment '支付日期id',
    alipay_trade_no      string comment '支付宝交易编号',
    trade_body           string comment '交易内容',
    payment_type         string comment '支付类型名称',
    payment_status       string comment '支付状态',
    callback_time        string comment '支付成功时间',
    original_amount      decimal(16, 2) comment '原始支付金额',
    coupon_reduce_amount decimal(16, 2) comment '优惠支付金额',
    final_amount         decimal(16, 2) comment '最终支付金额'
) comment '交易域支付成功事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_trade_pay_detail_suc_inc/'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域试听下单累计快照事实表
drop table if exists dwd_trade_course_order_inc;
create external table dwd_trade_course_order_inc
(
    user_id       string comment '用户id',
    order_id      string comment '订单id',
    play_time     string comment '播放时间',
    play_date     string comment '播放日期',
    order_time    string comment '下单时间',
    order_date    string comment '下单日期',
    course_id     string comment '课程id',
    course_name   string comment '课程名称',
    subject_id    string comment '科目id',
    subject_name  string comment '科目名称',
    category_id   string comment '分类id',
    category_name string comment '分类名称'
) comment '交易域试听下单累计快照事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_trade_course_order_inc'
    tblproperties ('orc.compress' = 'snappy');

-- 用户域用户注册事务事实表
drop table if exists dwd_user_register_inc;
create external table dwd_user_register_inc
(
    user_id       string comment '用户id',
    register_time string comment '注册时间',
    register_date string comment '注册日期',
    province_id   string comment '省份id',
    phone_brand   string comment '手机品牌',
    channel       string comment '渠道',
    phone_model   string comment '手机型号',
    mid           string comment '设备id',
    os            string comment '操作系统',
    source_id     string comment '来源id',
    source_name   string comment '来源名称'
) comment '用户域用户注册事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_user_register_inc'
    tblproperties ('orc.compress' = 'snappy');

-- 用户域用户登录事务事实表
drop table if exists dwd_user_login_inc;
create external table dwd_user_login_inc
(
    user_id        string comment '用户id',
    login_date     string comment '日期id',
    login_time     string comment '登录时间',
    source_id      string comment '来源id',
    source_site    string comment '来源名称',
    province_id    string comment '省份id',
    version_code   string comment '应用版本',
    mid_id         string comment '设备id',
    brand          string comment '设备品牌',
    model          string comment '设备型号',
    operate_system string comment '设备操作系统'
) comment '用户域用户登录事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_user_login_inc/'
    tblproperties ("orc.compress" = "snappy");

-- 流量域页面浏览事务事实表
drop table if exists dwd_traffic_page_view_inc;
create external table dwd_traffic_page_view_inc
(
    mid_id         string comment '手机唯一编号',
    province_id    string comment '省份id',
    brand          string comment '手机品牌',
    channel        string comment '渠道',
    is_new         string comment '是否新用户',
    model          string comment '手机型号',
    os             string comment '手机品牌',
    session_id     string comment '会话id',
    user_id        string comment '用户id',
    version_code   string comment '版本号',
    source_id         string comment '数据来源',
    during_time    bigint comment '持续时间毫秒',
    page_item      string comment '目标id ',
    page_item_type string comment '目标类型',
    page_id        string comment '页面id ',
    last_page_id   string comment '上页类型',
    ts             string comment '跳入时间'
)
    comment '流量域页面浏览事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_traffic_page_view_inc'
    tblproperties ('orc.compress' = 'snappy');

-- 学习域播放事务事实表
drop table if exists dwd_learn_play_inc;
create external table dwd_learn_play_inc
(
    mid_id       string comment '手机唯一编号',
    province_id  string comment '省份id',
    brand        string comment '手机品牌',
    is_new       string comment '是否新用户',
    model        string comment '手机型号',
    os           string comment '手机品牌',
    session_id   string comment '会话id',
    user_id      string comment '用户id',
    version_code string comment '版本号',
    source_id    string comment '数据来源',
    video_id     string comment '视频id',
    video_name   string comment '视频名称',
    chapter_id   string comment '章节id',
    chapter_name string comment '章节名称',
    course_id    string comment '课程id',
    course_name  string comment '课程名称',
    play_sec     bigint comment '播放时长',
    ts           bigint comment '跳入时间'
) comment '学习域播放事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_learn_play_inc'
    tblproperties ('orc.compress' = 'snappy');

-- 学习域播放周期快照事实表
drop table if exists dwd_learn_play_stats_full;
create external table dwd_learn_play_stats_full
(
    user_id                     string comment '用户id',
    video_id                    string comment '视频id',
    video_name                  string comment '视频名称',
    chapter_id                  string comment '章节id',
    chapter_name                string comment '章节名称',
    course_id                   string comment '课程id',
    course_name                 string comment '课程名称',
    total_play_sec              bigint comment '累计播放时长',
    position_sec                bigint comment '当前播放进度',
    max_position_sec            bigint comment '历史最大播放进度',
    first_sec_complete_date     string comment '首次累计时长完播日期',
    first_process_complete_date string comment '进度首次完播日期',
    first_complete_date         string comment '首次完播日期'
) comment '学习域播放周期快照事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_learn_play_stats_full'
    tblproperties ('orc.compress' = 'snappy');

-- 考试域答卷事务事实表
drop table if exists dwd_examination_test_paper_inc;
create external table dwd_examination_test_paper_inc
(
    id           string comment '编号',
    paper_id     string comment '试卷id',
    user_id      string comment '用户id',
    date_id      string comment '日期id',
    score        decimal(16, 2) comment '分数',
    duration_sec string comment '所用时长',
    create_time  string comment '创建时间',
    submit_time  string comment '提交时间',
    update_time  string comment '更新时间'
) comment '考试域答卷事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_examination_test_paper_inc/'
    tblproperties ("orc.compress" = "snappy");

-- 考试域答题事务事实表
drop table if exists dwd_examination_test_question_inc;
create external table dwd_examination_test_question_inc
(
    id          string comment '编号',
    user_id     string comment '用户id',
    paper_id    string comment '试卷id',
    question_id string comment '题目id',
    date_id     string comment '日期id',
    answer      string comment '答案',
    is_correct  string comment '是否正确',
    score       decimal(16, 2) comment '分数',
    create_time string comment '开始时间',
    update_time string comment '更新时间'
) comment '考试域答题事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_examination_test_question_inc/'
    tblproperties ("orc.compress" = "snappy");

-- 互动域课程评价事务事实表
drop table if exists dwd_interaction_review_inc;
create external table dwd_interaction_review_inc
(
    id           string comment '编号',
    user_id      string comment '用户id',
    course_id    string comment '课程id',
    date_id      string comment '日期id',
    review_stars bigint comment '评级',
    create_time  string comment '评价时间'
) comment '互动域课程评价事务事实表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dwd/dwd_interaction_review_inc/'
    tblproperties ("orc.compress" = "snappy");