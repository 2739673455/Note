#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> [date]" && exit
[ -n "$2" ] && do_date="$2" || do_date=`date -d "-1 day" +%F`
hive_db=edu

# 1.1 各来源流量统计
ads_traffic_stats_by_source="
insert overwrite table ${hive_db}.ads_traffic_stats_by_source
select *
from ${hive_db}.ads_traffic_stats_by_source
union
select
    '$do_date' as                                   dt,
    recent_days,
    source_id,
    source_site,
    count(distinct user_id)                           uv_count,
    bigint(avg(during_time / 1000))                   avg_duration_sec,
    bigint(avg(page_count))                           avg_page_count,
    count(session_id)                                 sv_count,
    sum(if(page_count = 1, 1, 0)) / count(session_id) bounce_rate
from ${hive_db}.dws_traffic_session_page_view_1d lateral view explode(array(1, 7, 30)) tmp as recent_days
where date_sub('$do_date', recent_days - 1) <= dt
  and dt <= '$do_date'
group by recent_days, source_id, source_site;
"

# 1.2 路径分析
ads_traffic_page_path="
insert overwrite table ${hive_db}.ads_traffic_page_path
select *
from ${hive_db}.ads_traffic_page_path
union
select
    '$do_date' as dt,
    recent_days,
    source,
    nvl(target, 'null'),
    count(*)     as path_count
from (
    select
        recent_days,
        concat('step-', rk, ':', page_id)          source,
        concat('step-', rk + 1, ':', next_page_id) target
    from (
        select
            recent_days,
            page_id,
            lead(page_id) over (partition by recent_days,session_id order by ts) next_page_id,
            row_number() over (partition by recent_days,session_id order by ts)  rk
        from ${hive_db}.dwd_traffic_page_view_inc lateral view explode(array(1, 7, 30)) tmp as recent_days
        where date_sub('$do_date', recent_days - 1) <= dt
          and dt <= '$do_date'
         ) t1
     ) t2
group by recent_days, source, target;
"

# 1.3 各来源下单统计
ads_register_order_by_source="
insert overwrite table ${hive_db}.ads_register_order_by_source
select *
from ${hive_db}.ads_register_order_by_source
union
select
    '$do_date',
    view_t.days,
    view_t.source_id,
    source_name,
    final_amount,
    concat(bigint(order_user_count / view_user_count * 100), '%') as convert_rate
from (
    select
        days,
        source_id,
        source_name,
        count(distinct user_id) as view_user_count
    from (
        select
            source_id,
            source_site as source_name,
            user_id,
            dt
        from ${hive_db}.dws_traffic_session_page_view_1d
        where user_id is not null
          and date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1
        lateral view explode(array(1, 7, 30)) lv as days
    where datediff('$do_date', dt) <= days - 1
    group by days, source_id, source_name
     ) view_t
left join(
    select
        days,
        source_id,
        count(distinct user_id) as order_user_count,
        sum(final_amount)       as final_amount
    from (
        select
            source_id,
            order_date,
            user_id,
            final_amount
        from ${hive_db}.dwd_trade_order_detail_inc
        where source_id is not null
          and date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) lv as days
    where datediff('$do_date', order_date) <= days - 1
    group by days, order_date, source_id
         ) order_t
  on view_t.days = order_t.days and view_t.source_id = order_t.source_id;
"

# 2.1 用户变动统计
ads_user_user_change="
insert overwrite table ${hive_db}.ads_user_user_change
select *
from ${hive_db}.ads_user_user_change
union
select
    '$do_date' as dt,
    user_churn_count,
    user_back_count
from (
    select
        '$do_date' as dt,
        count(*)     as user_churn_count
    from ${hive_db}.dws_user_user_login_td
    where dt = '$do_date'
      and login_last_date = date_sub('$do_date', 6)
     ) t1
join
(
    select
        '$do_date' as dt,
        count(*)     as user_back_count
    from (
        select
            user_id,
            login_last_date nd
        from ${hive_db}.dws_user_user_login_td
        where dt = '$do_date'
          and login_last_date = '$do_date'
         ) a
    join
    (
        select
            user_id,
            login_last_date pd
        from ${hive_db}.dws_user_user_login_td
        where dt = date_sub('$do_date', 1)
    ) b
      on a.user_id = b.user_id
    where datediff(nd, pd) >= 7
) t
  on t1.dt = t.dt;
"

# 2.2 用户留存率
ads_user_retained_rate="
insert overwrite table ${hive_db}.ads_user_retained_rate
select *
from ${hive_db}.ads_user_retained_rate
union
select
    '$do_date',
    register_date,
    count(*) as register_count,
    if(datediff('$do_date', register_date) >= 1,
       concat(bigint(sum(if(days = 1, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_1d,
    if(datediff('$do_date', register_date) >= 2,
       concat(bigint(sum(if(days = 2, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_2d,
    if(datediff('$do_date', register_date) >= 3,
       concat(bigint(sum(if(days = 3, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_3d,
    if(datediff('$do_date', register_date) >= 4,
       concat(bigint(sum(if(days = 4, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_4d,
    if(datediff('$do_date', register_date) >= 5,
       concat(bigint(sum(if(days = 5, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_5d,
    if(datediff('$do_date', register_date) >= 6,
       concat(bigint(sum(if(days = 6, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_6d,
    if(datediff('$do_date', register_date) >= 7,
       concat(bigint(sum(if(days = 7, 1, 0)) / count(*) * 100), '%'),
       '-')  as retained_rate_7d
from (
    select
        register_date,
        login_date,
        datediff(login_date, register_date) as days
    from (
        select
            user_id,
            register_date
        from ${hive_db}.dwd_user_register_inc
        where datediff('$do_date', dt) <= 7
          and 1 <= datediff('2022-02-27', dt)
         ) as register_t
    left join (
        select
            user_id,
            login_date
        from ${hive_db}.dwd_user_login_inc
        where datediff('$do_date', dt) <= 7 - 1
          and dt <= '$do_date'
        group by login_date, user_id
              ) as login_t
      on login_t.user_id = register_t.user_id
     ) t1
group by register_date;
"

# 2.3 用户新增活跃统计
ads_user_user_stats="
insert overwrite table ${hive_db}.ads_user_user_stats
select *
from ${hive_db}.ads_user_user_stats
union
select
    '$do_date' as dt,
    new.recent_days,
    new_user_count,
    active_user_count
from (
    select
        recent_days,
        count(user_id) new_user_count
    from ${hive_db}.dwd_user_register_inc lateral view explode(array(1, 7, 30)) tmp as recent_days
    where date_sub('$do_date', recent_days - 1) <= dt
    group by recent_days
     ) new
join
(
    select
        recent_days,
        count(user_id) active_user_count
    from ${hive_db}.dws_user_user_login_td lateral view explode(array(1, 7, 30)) tmp as recent_days
    where dt = '$do_date'
      and date_sub('$do_date', recent_days - 1) <= login_last_date
    group by recent_days
) act
  on new.recent_days = act.recent_days;
"

# 2.4 用户行为漏斗分析
ads_user_user_action="
insert overwrite table ${hive_db}.ads_user_user_action
select *
from ${hive_db}.ads_user_user_action
union
select
    '$do_date' as dt,
    j1.days,
    sum(home)       home_count,
    sum(detail)     good_detail_count,
    sum(cart)       cart_count,
    sum(order_num)  order_count,
    sum(payment)    payment_count
from (
    select
        days,
        count(distinct user_id) home
    from (
        select
            dt,
            user_id
        from ${hive_db}.dwd_traffic_page_view_inc
        where page_id = 'home'
          and date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by days
     ) j1
join (
    select
        days,
        count(distinct user_id) detail
    from (
        select
            dt,
            user_id
        from ${hive_db}.dwd_traffic_page_view_inc
        where page_id = 'course_detail'
          and date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by days
     ) j2
  on j1.days = j2.days
join (
    select
        days,
        count(distinct user_id) cart
    from (
        select
            dt,
            user_id
        from ${hive_db}.dwd_trade_cart_add_inc
        where date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by days
     ) j3
  on j1.days = j3.days
join (
    select
        days,
        count(distinct user_id) as order_num
    from (
        select
            dt,
            user_id
        from ${hive_db}.dwd_trade_order_detail_inc
        where date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by days
     ) j4
  on j1.days = j4.days
join (
    select
        days,
        count(distinct user_id) payment
    from (
        select
            dt,
            user_id
        from ${hive_db}.dwd_trade_pay_detail_suc_inc
        where payment_status = '1602'
          and date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by days
     ) j5
  on j1.days = j5.days
group by j1.days;
"

# 2.5 新增交易用户统计
ads_user_new_buyer_stats="
insert overwrite table ${hive_db}.ads_user_new_buyer_stats
select *
from ${hive_db}.ads_user_new_buyer_stats
union
select
    '$do_date' as dt,
    t1.recent_days,
    new_order_user_count,
    new_payment_user_count
from (
    select
        recent_days,
        sum(if(date_sub('$do_date', recent_days - 1) <= order_dt_first
            , 1, 0)) as new_order_user_count
    from (
        select
            user_id,
            collect_set(dt)[0] as dt,
            min(order_time)    as order_dt_first
        from ${hive_db}.dwd_trade_order_detail_inc
        where dt = '$do_date'
        group by user_id, dt
         ) t lateral view explode(array(1, 7, 30)) tmp as recent_days
    group by recent_days
     ) t1
join
(
    select
        recent_days,
        sum(if(date_sub('$do_date', recent_days - 1) <= payment_dt_first
            , 1, 0)) as new_payment_user_count
    from ${hive_db}.dws_trade_user_payment_td lateral view explode(array(1, 7, 30)) tmp as recent_days
    where dt = '$do_date'
    group by recent_days
) t2
  on t1.recent_days = t2.recent_days;
"

# 2.6 各年龄段下单用户数
ads_order_user_count_by_age="
insert overwrite table ${hive_db}.ads_order_user_count_by_age
select *
from ${hive_db}.ads_order_user_count_by_age
union
select
    '$do_date',
    recent_days,
    concat(age_range * 10, '岁-', (age_range + 1) * 10, '岁') as age_range,
    count(distinct user_id)                                   as user_count
from (
    select
        user_id,
        floor(age / 10) as age_range,
        dt
    from ${hive_db}.dwd_trade_order_detail_inc
    where date_sub('$do_date', 30 - 1) <= dt
      and dt <= '$do_date'
     ) as t1
    lateral view explode(array(1, 7, 30)) lv as recent_days
where date_sub('$do_date', recent_days - 1) <= dt
group by recent_days, age_range;
"

# 3.1 各分类课程交易统计
ads_order_by_category="
insert overwrite table ${hive_db}.ads_order_by_category
select *
from ${hive_db}.ads_order_by_category
union
select
    '$do_date',
    days,
    category_id,
    category_name,
    count(distinct order_id) as order_count,
    count(distinct user_id)  as user_count,
    sum(final_amount)        as final_amount
from (
    select
        order_id,
        user_id,
        final_amount,
        category_id,
        category_name,
        dt
    from ${hive_db}.dwd_trade_order_detail_inc
    where date_sub('$do_date', 30 - 1) <= dt
      and dt <= '$do_date'
     ) as t1
    lateral view explode(array(1, 7, 30)) lv as days
where date_sub('$do_date', days - 1) <= dt
group by days, category_id, category_name;
"

# 3.2 各学科课程交易统计
ads_order_by_subject="
insert overwrite table ${hive_db}.ads_order_by_subject
select *
from ${hive_db}.ads_order_by_subject
union
select
    '$do_date',
    days,
    subject_id,
    subject_name,
    count(distinct order_id) as order_count,
    count(distinct user_id)  as user_count,
    sum(final_amount)        as final_amount
from (
    select
        order_id,
        user_id,
        final_amount,
        subject_id,
        subject_name,
        dt
    from ${hive_db}.dwd_trade_order_detail_inc
    where date_sub('$do_date', 30 - 1) <= dt
      and dt <= '$do_date'
     ) as t1
    lateral view explode(array(1, 7, 30)) lv as days
where date_sub('$do_date', days - 1) <= dt
group by days, subject_id, subject_name;
"

# 3.3 各课程交易统计
ads_order_by_course="
insert overwrite table ${hive_db}.ads_order_by_course
select *
from ${hive_db}.ads_order_by_course
union
select
    '$do_date',
    days,
    course_id,
    course_name,
    count(order_id)         as order_count,
    count(distinct user_id) as user_count,
    sum(final_amount)       as final_amount
from (
    select
        order_id,
        user_id,
        final_amount,
        course_id,
        course_name,
        dt
    from ${hive_db}.dwd_trade_order_detail_inc
    where date_sub('$do_date', 30 - 1) <= dt
      and dt <= '$do_date'
     ) as t1
    lateral view explode(array(1, 7, 30)) lv as days
where date_sub('$do_date', days - 1) <= dt
group by days, course_id, course_name;
"

# 3.4 各课程评价统计
ads_course_review_stats_by_course="
insert overwrite table ${hive_db}.ads_course_review_stats_by_course
select *
from ${hive_db}.ads_course_review_stats_by_course
union
select
    '$do_date' as dt,
    days            recent_days,
    t1.course_id,
    course_name,
    avg_stars,
    review_user_count,
    praise_rate
from (
    select
        days,
        course_id,
        bigint(avg(review_stars))                                            avg_stars,
        count(*)                                                             review_user_count,
        cast(sum(if(review_stars = 5, 1, 0)) / count(*) as decimal(16, 2)) praise_rate
    from ${hive_db}.dwd_interaction_review_inc lateral view explode(array(1, 7, 30)) tpm as days
    where date_sub('$do_date', days - 1) <= dt
      and dt <= '$do_date'
    group by course_id, days
     ) t1
left join (
    select
        course_id,
        course_name
    from ${hive_db}.dim_course_paper_full
    where dt='$do_date'
          ) t2
  on t1.course_id = t2.course_id;
"

# 3.5 各分类课程试听留存统计
ads_preview_retained_by_category="
insert overwrite table ${hive_db}.ads_preview_retained_by_category
select *
from ${hive_db}.ads_preview_retained_by_category
union
select
    '$do_date',
    days,
    category_id,
    category_name,
    count(distinct user_id)                                                              as preview_count,
    concat(bigint(count(distinct user_order_flag) / count(distinct user_id) * 100), '%') as retained_rate
from (
    select
        user_id,
        category_id,
        category_name,
        play_date,
        if(order_date is not null, user_id, null) user_order_flag,
        dt
    from ${hive_db}.dwd_trade_course_order_inc
    where (dt = '9999-12-31' or (datediff('$do_date', dt) <= 7 - 1 and dt <= '$do_date'))
      and datediff('$do_date', play_date) <= 7 - 1
     ) as t1 lateral view explode(array(1, 2, 3, 4, 5, 6, 7)) lv as days
where date_sub('$do_date', days - 1) <= play_date
group by days, category_id, category_name;
"

# 3.6 各学科课程试听留存统计
ads_preview_retained_by_subject="
insert overwrite table ${hive_db}.ads_preview_retained_by_subject
select *
from ${hive_db}.ads_preview_retained_by_subject
union
select
    '$do_date',
    days,
    subject_id,
    subject_name,
    count(distinct user_id)                                                              as preview_count,
    concat(bigint(count(distinct user_order_flag) / count(distinct user_id) * 100), '%') as retained_rate
from (
    select
        user_id,
        subject_id,
        subject_name,
        play_date,
        if(order_date is not null, user_id, null) user_order_flag,
        dt
    from ${hive_db}.dwd_trade_course_order_inc
    where (dt = '9999-12-31' or (datediff('$do_date', dt) <= 7 - 1 and dt <= '$do_date'))
      and datediff('$do_date', play_date) <= 7 - 1
     ) as t1 lateral view explode(array(1, 2, 3, 4, 5, 6, 7)) lv as days
where date_sub('$do_date', days - 1) <= play_date
group by days, subject_id, subject_name;
"

# 3.7 各课程试听留存统计
ads_preview_retained_by_course="
insert overwrite table ${hive_db}.ads_preview_retained_by_course
select *
from ${hive_db}.ads_preview_retained_by_course
union
select
    '$do_date',
    days,
    course_id,
    course_name,
    count(distinct user_id)                                                              as preview_count,
    concat(bigint(count(distinct user_order_flag) / count(distinct user_id) * 100), '%') as retained_rate
from (
    select
        user_id,
        course_id,
        course_name,
        play_date,
        if(order_date is not null, user_id, null) user_order_flag,
        dt
    from ${hive_db}.dwd_trade_course_order_inc
    where (dt = '9999-12-31' or (datediff('$do_date', dt) <= 7 - 1 and dt <= '$do_date'))
      and datediff('$do_date', play_date) <= 7 - 1
     ) as t1 lateral view explode(array(1, 2, 3, 4, 5, 6, 7)) lv as days
where date_sub('$do_date', days - 1) <= play_date
group by days, course_id, course_name;
"

# 4.1 交易综合统计
ads_order_total="
insert overwrite table ${hive_db}.ads_order_total
select *
from ${hive_db}.ads_order_total
union
select
    '$do_date',
    days,
    count(distinct order_id) as order_count,
    count(distinct user_id)  as user_count,
    sum(final_amount)        as final_amount
from (
    select
        order_id,
        user_id,
        final_amount,
        dt
    from ${hive_db}.dwd_trade_order_detail_inc
    where date_sub('$do_date', 30 - 1) <= dt
      and dt <= '$do_date'
     ) as t1
    lateral view explode(array(1, 7, 30)) lv as days
where date_sub('$do_date', days - 1) <= dt
group by days;
"

# 4.2 各省份交易统计
ads_order_by_province="
insert overwrite table ${hive_db}.ads_order_by_province
select *
from ${hive_db}.ads_order_by_province
union
select
    dt,
    days,
    province_id,
    name,
    region_id,
    area_code,
    iso_code,
    iso_3166_2,
    order_count,
    user_count,
    final_amount
from (
    select
        '$do_date',
        days,
        province_id,
        count(distinct order_id) as order_count,
        count(distinct user_id)  as user_count,
        sum(final_amount)        as final_amount
    from (
        select
            order_id,
            user_id,
            province_id,
            final_amount,
            dt
        from ${hive_db}.dwd_trade_order_detail_inc
        where date_sub('$do_date', 30 - 1) <= dt
          and dt <= '$do_date'
         ) as t1
        lateral view explode(array(1, 7, 30)) lv as days
    where date_sub('$do_date', days - 1) <= dt
    group by days, province_id
     ) t1
left join (
    select *
    from ${hive_db}.dim_province_full
    where dt = '$do_date'
          ) province_info
  on t1.province_id = province_info.id;
"

# 5.1 各试卷相关指标统计
ads_examination_paper_avg_stats="
insert overwrite table ${hive_db}.ads_examination_paper_avg_stats
select *
from ${hive_db}.ads_examination_paper_avg_stats
union
select
    dt,
    days,
    t2.paper_id,
    paper_name,
    avg_score,
    avg_duration_sec,
    count_user
from (
    select
        '$do_date'            as dt,
        days,
        paper_id,
        cast(avg(score) as decimal(16, 2)) as avg_score,
        avg(duration_sec)                  as avg_duration_sec,
        count(distinct user_id)            as count_user
    from (
        select
            paper_id,
            score,
            duration_sec,
            user_id,
            dt
        from ${hive_db}.dwd_examination_test_paper_inc
        where date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) lv as days
    where datediff('$do_date', dt) <= days - 1
    group by days, paper_id
     ) t2
left join(
    select
        paper_id,
        paper_name
    from ${hive_db}.dim_course_paper_full
    where dt = '$do_date'
         ) paper_info
  on t2.paper_id = paper_info.paper_id;
"

# 5.2 各课程考试相关指标统计
ads_course_exam_avg_stats="
insert overwrite table ${hive_db}.ads_course_exam_avg_stats
select *
from ${hive_db}.ads_course_exam_avg_stats
union
select
    '$do_date' as dt,
    days            recent_days,
    course_id,
    course_name,
    cast(avg(score) as decimal(16, 2)),
    avg(duration_sec),
    count(distinct user_id)
from (
    select
        course_id,
        score,
        duration_sec,
        user_id,
        course_name,
        dt
    from (
        select
            user_id,
            score,
            duration_sec,
            paper_id,
            dt
        from ${hive_db}.dwd_examination_test_paper_inc
        where date_sub('$do_date', 29) <= dt
         and dt <= '$do_date'
         ) t1
    join (
        select
            paper_id,
            course_id,
            course_name
        from ${hive_db}.dim_course_paper_full
        where dt = '$do_date'
         ) t2
      on t1.paper_id = t2.paper_id
     ) t3 lateral view explode(array(1, 7, 30)) tmp as days
where date_sub('$do_date', days - 1) <= dt
  and dt <= '$do_date'
group by course_id, course_name, days;
"

# 5.3 各试卷分数分布统计
ads_paper_fraction_distribution_stats="
insert overwrite table ${hive_db}.ads_paper_fraction_distribution_stats
select *
from ${hive_db}.ads_paper_fraction_distribution_stats
union
select
    '$do_date' as dt,
    days,
    t2.paper_id,
    paper_name,
    score_range,
    sum_user
from (
    select
        days,
        paper_id,
        if(score_range = 10, 100,
           concat(score_range * 10, '-', (score_range + 1) * 10)) as score_range,
        count(distinct user_id)                                   as sum_user
    from (
        select
            user_id,
            paper_id,
            score,
            floor(score / 10) as score_range,
            dt
        from ${hive_db}.dwd_examination_test_paper_inc
        where date_sub('$do_date', 29) <= dt
          and dt <= '$do_date'
         ) t1 lateral view explode(array(1, 7, 30)) tmp as days
    where date_sub('$do_date', days - 1) <= dt
    group by paper_id, days, score_range
     ) t2
join (
    select
        paper_id,
        paper_name
    from ${hive_db}.dim_course_paper_full
    where dt = '$do_date'
     ) t3
  on t2.paper_id = t3.paper_id;
"

# 5.4 各题目正确率统计
ads_exam_topic_accuracy_stats="
insert overwrite table ${hive_db}.ads_exam_topic_accuracy_stats
select *
from ${hive_db}.ads_exam_topic_accuracy_stats
union
select
    '$do_date'                                                    as dt,
    days,
    question_id,
    concat(bigint(sum(correct_num) / sum(question_num) * 100), '%') as accuracy
from (
    select
        dt,
        question_id,
        sum(if(is_correct = '1', 1, 0)) as correct_num,
        count(question_id)              as question_num
    from ${hive_db}.dwd_examination_test_question_inc
    where date_sub('$do_date', 29) <= dt
      and dt <= '$do_date'
    group by dt, question_id
     ) t1 lateral view explode(array(1, 7, 30)) lv as days
where datediff('$do_date', dt) <= days - 1
group by days, question_id;
"

# 6.1 各章节视频播放情况统计
ads_chapter_video_play_stats="
insert overwrite table ${hive_db}.ads_chapter_video_play_stats
select *
from ${hive_db}.ads_chapter_video_play_stats
union
select
    '$do_date' as dt,
    days,
    chapter_id,
    chapter_name,
    count(*),
    sum(play_sec) / count(distinct user_id),
    count(distinct user_id)
from (
    select
        video_id,
        user_id,
        chapter_id,
        chapter_name,
        play_sec,
        dt
    from ${hive_db}.dwd_learn_play_inc
    where date_sub('$do_date', 29) <= dt
      and dt <= '$do_date'
     ) t1 lateral view explode(array(1, 7, 30)) tmp as days
where date_sub('$do_date', days - 1) <= dt
  and dt <= '$do_date'
group by chapter_id, chapter_name, days;
"

# 6.2 各课程视频播放情况统计
ads_course_video_play_stats="
insert overwrite table ${hive_db}.ads_course_video_play_stats
select *
from ${hive_db}.ads_course_video_play_stats
union
select
    '$do_date' as dt,
    days,
    course_id,
    course_name,
    count(*),
    sum(play_sec) / count(distinct user_id),
    count(distinct user_id)
from (
    select
        course_id,
        course_name,
        play_sec,
        user_id,
        video_id,
        dt
    from ${hive_db}.dwd_learn_play_inc
    where date_sub('$do_date', 29) <= dt
      and dt <= '$do_date'
     ) t1 lateral view explode(array(1, 7, 30)) tmp as days
where date_sub('$do_date', days - 1) <= dt
  and dt <= '$do_date'
group by course_id, course_name, days;
"

# 7.1 各课程完课人数统计
ads_complete_user_count_per_course="
insert overwrite table ${hive_db}.ads_complete_user_count_per_course
select *
from ${hive_db}.ads_complete_user_count_per_course
union
select
    '$do_date' dt,
    recent_days,
    course_complete.course_id,
    count(*)     order_count
from (
    select
        chapter_complete.course_id,
        user_id,
        user_first_complete_date
    from (
        select
            course_id,
            user_id,
            max(first_complete_date)   user_first_complete_date,
            count(first_complete_date) user_first_complete_count
        from ${hive_db}.dwd_learn_play_stats_full
        where dt = '$do_date'
        group by course_id, user_id
         ) chapter_complete
    left join (
        select
            course_id,
            chapter_num as chapter_num
        from ${hive_db}.dim_course_paper_full
        where dt = '$do_date'
              ) dim_course
      on chapter_complete.course_id = dim_course.course_id
    where user_first_complete_count = chapter_num
     ) course_complete lateral view explode(array(1, 7, 30)) tmp as recent_days
where date_sub('$do_date', recent_days - 1) <= user_first_complete_date
group by recent_days, course_id;
"

# 7.2 完课综合指标
ads_complete_course_index_stats="
insert overwrite table ${hive_db}.ads_complete_course_index_stats
select *
from ${hive_db}.ads_complete_course_index_stats
union
select
    '$do_date',
    days,
    count(distinct user_id),
    count(*)
from (
    select
        t1.course_id,
        user_id,
        max_chapter_complete_date
    from (
        select
            course_id,
            user_id,
            max(first_complete_date)   max_chapter_complete_date,
            count(first_complete_date) user_chapter_complete_count
        from ${hive_db}.dwd_learn_play_stats_full
        where dt = '$do_date'
          and first_complete_date is not null
        group by course_id, user_id
         ) t1
    left join (
        select
            course_id,
            chapter_num
        from ${hive_db}.dim_course_paper_full
        where dt = '$do_date'
              ) t2
      on t1.course_id = t2.course_id
    where user_chapter_complete_count = chapter_num
     ) t3 lateral view explode(array(1, 7, 30)) tmp as days
where date_sub('$do_date', days - 1) <= max_chapter_complete_date
group by days;
"

# 7.3 各课程人均完成章节视频数统计
ads_complete_chapter_per_user_by_course="
insert overwrite table ${hive_db}.ads_complete_chapter_per_user_by_course
select *
from ${hive_db}.ads_complete_chapter_per_user_by_course
union
select
    '$do_date'                                as dt,
    days,
    course_id,
    course_name,
    count(chapter_id) / count(distinct user_id) as complete_chapter_per_user
from (
    select
        user_id,
        course_id,
        course_name,
        chapter_id,
        first_complete_date
    from ${hive_db}.dwd_learn_play_stats_full
    where first_complete_date is not null
      and datediff('$do_date', dt) <= 30 - 1
      and dt <= '$do_date'
      and datediff('$do_date', first_complete_date) <= 30 - 1
     ) t1 lateral view explode(array(1, 7, 30)) lv as days
where datediff('$do_date', first_complete_date) <= days - 1
group by days, course_id, course_name;
"

tables=(
    "ads_traffic_stats_by_source"
    "ads_traffic_page_path"
    "ads_register_order_by_source"
    "ads_user_user_change"
    "ads_user_retained_rate"
    "ads_user_user_stats"
    "ads_user_user_action"
    "ads_user_new_buyer_stats"
    "ads_order_user_count_by_age"
    "ads_order_by_category"
    "ads_order_by_subject"
    "ads_order_by_course"
    "ads_course_review_stats_by_course"
    "ads_preview_retained_by_category"
    "ads_preview_retained_by_subject"
    "ads_preview_retained_by_course"
    "ads_order_total"
    "ads_order_by_province"
    "ads_examination_paper_avg_stats"
    "ads_course_exam_avg_stats"
    "ads_paper_fraction_distribution_stats"
    "ads_exam_topic_accuracy_stats"
    "ads_chapter_video_play_stats"
    "ads_course_video_play_stats"
    "ads_complete_user_count_per_course"
    "ads_complete_course_index_stats"
    "ads_complete_chapter_per_user_by_course"
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