-- 流量域会话粒度页面浏览最近1日汇总表
drop table if exists dws_traffic_session_page_view_1d;
create external table dws_traffic_session_page_view_1d
(
    session_id  string comment '会话id',
    mid_id      string comment '设备id',
    user_id     string comment '用户id',
    source_id   string comment '引流来源id',
    source_site string comment '引流来源名称',
    page_count  bigint comment '页面总数',
    during_time bigint comment '停留时长,单位: 毫秒'
) comment '流量域会话粒度页面浏览最近1日汇总表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dws/dws_traffic_session_page_view_1d/'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域用户粒度用户支付最近1日汇总表
drop table if exists dws_trade_user_payment_1d;
create external table dws_trade_user_payment_1d
(
    user_id       string comment '用户id',
    payment_count bigint comment '支付次数'
) comment '交易域用户粒度用户支付最近1日汇总表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dws/dws_trade_user_payment_1d/'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域用户粒度用户支付最近n日汇总表
drop table if exists dws_trade_user_payment_nd;
create external table dws_trade_user_payment_nd
(
    user_id           string comment '用户id',
    payment_count_7d  bigint comment '最近7日支付次数',
    payment_count_30d bigint comment '最近30日支付次数'
) comment '交易域用户粒度用户支付最近n日汇总表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dws/dws_trade_user_payment_nd/'
    tblproperties ('orc.compress' = 'snappy');

-- 交易域用户粒度用户支付历史至今汇总表
drop table if exists dws_trade_user_payment_td;
create external table dws_trade_user_payment_td
(
    user_id          string comment '用户id',
    payment_dt_first string comment '首次支付日期'
) comment '交易域用户粒度用户支付历史至今汇总表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dws/dws_trade_user_payment_td/'
    tblproperties ('orc.compress' = 'snappy');

-- 用户域用户粒度用户登录历史至今汇总表
drop table if exists dws_user_user_login_td;
create external table dws_user_user_login_td
(
    user_id          string comment '用户id',
    login_last_date  string comment '末次登录日期',
    user_login_count bigint comment '用户登录次数'
) comment '用户域用户粒度用户登录历史至今汇总表'
    partitioned by (dt string)
    stored as orc
    location '/warehouse/edu/dws/dws_user_user_login_td/'
    tblproperties ('orc.compress' = 'snappy');