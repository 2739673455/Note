#!/bin/bash
[ $# -lt 1 ] && echo "<all|tableName> date" && exit
[ -n "$2" ] && do_date="$2" || { echo "please input date"; exit; }
hive_db=edu

# 交易域加购事务事实表
dwd_trade_cart_add_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${hive_db}.dwd_trade_cart_add_inc partition (dt)
select
    data.id                                     id,
    data.user_id                                user_id,
    data.course_id                              course_id,
    date_format(data.create_time, 'yyyy-MM-dd') date_id,
    data.create_time                            create_time,
    data.cart_price                             cart_price,
    date_format(data.create_time, 'yyyy-MM-dd') dt
from ${hive_db}.ods_cart_info_inc
where dt = '$do_date'
  and type = 'bootstrap-insert';
"

# 交易域下单事务事实表
dwd_trade_order_detail_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${hive_db}.dwd_trade_order_detail_inc partition (dt)
select
    order_info.order_id,
    order_info.user_id,
    order_time,
    order_date,
    origin_amount,
    coupon_reduce,
    final_amount,
    age,
    province_id,
    source_id,
    source_name,
    order_detail.course_id,
    course_name,
    subject_id,
    subject_name,
    category_id,
    category_name,
    order_date
from (
    select
        data.id                                     as order_id,
        data.user_id,
        data.origin_amount,
        data.coupon_reduce,
        data.final_amount,
        data.session_id,
        data.province_id,
        data.create_time                            as order_time,
        date_format(data.create_time, 'yyyy-MM-dd') as order_date
    from ${hive_db}.ods_order_info_inc
    where dt = '$do_date'
      and type = 'bootstrap-insert'
     ) as order_info
join(
    select
        data.order_id,
        data.course_id,
        data.course_name
    from ${hive_db}.ods_order_detail_inc
    where dt = '$do_date'
      and type = 'bootstrap-insert'
    ) as order_detail
  on order_info.order_id = order_detail.order_id
left join(
    select
        user_id,
        bigint(datediff('$do_date', birthday) / 365) as age
    from ${hive_db}.dim_user_zip
    where dt = '9999-12-31'
         ) as user_info
  on order_info.user_id = user_info.user_id
left join(
    select
        course_id,
        subject_id,
        subject_name,
        category_id,
        category_name
    from ${hive_db}.dim_course_paper_full
    where dt = '$do_date'
         ) as course_info
  on order_detail.course_id = course_info.course_id
left join (
    select distinct
        common.sid,
        common.sc as source_id
    from ${hive_db}.ods_log_inc
    where dt = '$do_date'
          ) log
  on order_info.session_id = log.sid
left join (
    select
        id,
        source_site as source_name
    from ${hive_db}.dim_source_full
    where dt = '$do_date'
          ) as source_info
  on log.source_id = source_info.id;
"

# 交易域支付成功事务事实表
dwd_trade_pay_detail_suc_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${hive_db}.dwd_trade_pay_detail_suc_inc partition (dt)
select
    odt.id,
    od.id,
    user_id,
    course_id,
    province_id,
    date_format(create_time, 'yyyy-MM-dd') date_id,
    alipay_trade_no,
    trade_body,
    payment_type,
    payment_status,
    callback_time,
    origin_amount,
    coupon_reduce,
    final_amount,
    date_format(create_time, 'yyyy-MM-dd') dt
from (
    select
        data.id,
        data.order_id,
        data.user_id,
        data.course_id,
        data.origin_amount,
        data.coupon_reduce,
        data.final_amount,
        data.create_time
    from ${hive_db}.ods_order_detail_inc
    where dt = '$do_date'
      and type = 'bootstrap-insert'
     ) odt
left join(
    select
        data.id,
        data.province_id
    from ${hive_db}.ods_order_info_inc
    where dt = '$do_date'
      and type = 'bootstrap-insert'
         ) od
  on odt.order_id = od.id
join(
    select
        data.alipay_trade_no,
        data.trade_body,
        data.order_id,
        data.payment_type,
        data.payment_status,
        data.callback_time
    from ${hive_db}.ods_payment_info_inc
    where dt = '$do_date'
      and type = 'bootstrap-insert'
      and data.callback_time is not null
    ) pi
  on od.id = pi.order_id;
"

# 交易域试听下单累计快照事实表
dwd_trade_course_order_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${hive_db}.dwd_trade_course_order_inc partition (dt)
select
    user_id,
    order_id,
    play_time,
    play_date,
    order_time,
    order_date,
    course_info.course_id,
    course_name,
    subject_id,
    subject_name,
    category_id,
    category_name,
    if(order_date is null, '9999-12-31', order_date) as dt
from (
    select
        play.user_id,
        play.course_id,
        order_id,
        play_time,
        play_date,
        order_time,
        order_date
    from (
        select
            user_id,
            course_id,
            min(create_time)                            as play_time,
            date_format(min(create_time), 'yyyy-MM-dd') as play_date
        from ${hive_db}.ods_user_chapter_process_full
        where dt = '$do_date'
        group by user_id, course_id
         ) as play
    left join(
        select
            user_id,
            course_id,
            min(order_info.order_id)                   as order_id,
            min(order_time)                            as order_time,
            date_format(min(order_time), 'yyyy-MM-dd') as order_date
        from (
            select
                data.id as order_id,
                data.user_id
            from ${hive_db}.ods_order_info_inc
            where dt = '$do_date'
              and type = 'bootstrap-insert'
              and data.order_status = '1002'
             ) as order_info
        join(
            select
                data.course_id,
                data.order_id,
                data.create_time as order_time
            from ${hive_db}.ods_order_detail_inc
            where dt = '$do_date'
              and type = 'bootstrap-insert'
            ) as order_detail
          on order_info.order_id = order_detail.order_id
        group by user_id, course_id
             ) as order_course
      on play.user_id = order_course.user_id
        and play.course_id = order_course.course_id
    where play_time < order_time
       or order_time is null
     ) as play_order
left join (
    select
        course_id,
        course_name,
        subject_id,
        subject_name,
        category_id,
        category_name
    from ${hive_db}.dim_course_paper_full
    where dt = '$do_date'
          ) as course_info
  on play_order.course_id = course_info.course_id;
"

# 用户域用户注册事务事实表
dwd_user_register_inc="
set hive.exec.dynamic.partition.mode=nonstrict;
insert overwrite table ${hive_db}.dwd_user_register_inc partition (dt)
select
    register.user_id,
    register_time,
    register_date,
    province_id,
    phone_brand,
    channel,
    phone_model,
    mid,
    os,
    source_id,
    source_name,
    register_date
from (
    select
        user_id,
        create_time                            as register_time,
        date_format(create_time, 'yyyy-MM-dd') as register_date
    from ${hive_db}.dim_user_zip
    where dt = '9999-12-31'
     ) register
left join(
    select *
    from (
        select
            row_number() over (partition by common.uid order by ts) as rk,
            common.uid                                              as user_id,
            common.ar                                               as province_id,
            common.ba                                               as phone_brand,
            common.ch                                               as channel,
            common.md                                               as phone_model,
            common.mid,
            common.os,
            common.sc                                               as source_id,
            common.sid                                              as session_id
        from ${hive_db}.ods_log_inc
        where dt = '$do_date'
         ) t1
    where rk = 1
         ) log
  on register.user_id = log.user_id
left join (
    select
        id,
        source_site as source_name
    from ${hive_db}.dim_source_full
    where dt = '$do_date'
          ) as source_info
  on log.source_id = source_info.id;
"

# 用户域用户登录事务事实表
dwd_user_login_inc="
insert overwrite table ${hive_db}.dwd_user_login_inc partition (dt = '$do_date')
select
    user_id,
    date_format(from_utc_timestamp(ts, 'GMT+8'), 'yyyy-MM-dd') login_date,
    date_format(from_utc_timestamp(ts, 'GMT+8'), 'yyyy-MM-dd hh:mm:ss') login_time,
    rkt.id source_id,
    rkt.source_site source_site,
    province_id,
    version_code,
    mid_id,
    brand,
    model,
    operate_system
from (
     select
         user_id,
         province_id,
         version_code,
         mid_id,
         brand,
         model,
         operate_system,
         source.id,
         source.source_site,
         row_number() over (partition by session_id order by ts) rk,
         ts
     from (
          select
              common.ar  province_id,
              common.ba  brand,
              common.md  model,
              common.mid mid_id,
              common.os  operate_system,
              common.sid session_id,
              common.vc  version_code,
              common.uid user_id,
              common.sc source_id,
              ts
          from ${hive_db}.ods_log_inc
          where page is not null
            and common.uid is not null
            and dt = '$do_date'
          ) log
     left join (
         select
             id,
             source_site
             from ${hive_db}.dim_source_full
             where dt = '$do_date'
               )source
     on log.source_id = source.id
     ) rkt
where rk = 1;
"

# 流量域页面浏览事务事实表
dwd_traffic_page_view_inc="
set hive.cbo.enable=false;
insert overwrite table ${hive_db}.dwd_traffic_page_view_inc partition (dt = '$do_date')
select common.mid,
       common.ar      province_id,
       common.ba      brand,
       common.ch      channel,
       common.is_new,
       common.md      model,
       common.os,
       common.sid     session_id,
       common.uid     user_id,
       common.vc      version_code,
       common.sc,
       page.during_time,
       page.item      page_item,
       page.item_type page_item_type,
       page.page_id,
       page.last_page_id,
       ts
from ${hive_db}.ods_log_inc
where dt = '$do_date'
  and page is not null;
set hive.cbo.enable=true;
"

# 学习域播放事务事实表
dwd_learn_play_inc="
insert overwrite table ${hive_db}.dwd_learn_play_inc partition (dt='$do_date')
select
    mid,
    province_id,
    brand,
    is_new,
    model,
    os,
    session_id,
    user_id,
    version_code,
    sc,
    dim_video.video_id,
    video_name,
    chapter_id,
    chapter_name,
    dim_course.course_id,
    course_name,
    play_sec,
    ts
from (
     select
         common.mid,
         common.ar              province_id,
         common.ba              brand,
         common.is_new,
         common.md              model,
         common.os,
         common.sid             session_id,
         common.uid             user_id,
         common.vc              version_code,
         common.sc,
         appvideo.video_id,
         sum(appvideo.play_sec) play_sec,
         max(ts)                ts
     from ${hive_db}.ods_log_inc
     where dt = '$do_date'
       and appvideo.video_id is not null
     group by common.mid,
              common.ar,
              common.ba,
              common.is_new,
              common.md,
              common.os,
              common.sid,
              common.uid,
              common.vc,
              common.sc,
              appvideo.video_id
     ) aggred
left join
(
select
    video_id,
    video_name,
    chapter_id,
    chapter_name,
    course_id,
    dt
from ${hive_db}.dim_chapter_video_full
where dt = '$do_date'
) dim_video
on aggred.video_id = dim_video.video_id
left join
(
select
    course_id,
    course_name
from ${hive_db}.dim_course_paper_full
where dt = '$do_date'
) dim_course
on dim_video.course_id = dim_course.course_id;
"

# 学习域播放周期快照事实表
dwd_learn_play_stats_full="
insert overwrite table ${hive_db}.dwd_learn_play_stats_full partition (dt = '$do_date')
select
    user_id,
    video_id,
    video_name,
    chapter_id,
    chapter_name,
    course_id,
    course_name,
    total_play_sec,
    position_sec,
    max_position_sec,
    nvl(first_sec_complete_date,
        if(total_play_sec / during_sec >= 0.9, '$do_date', null))   first_sec_complete_date,
    nvl(first_process_complete_date,
        if(max_position_sec / during_sec >= 0.9, '$do_date', null)) first_process_complete_date,
    nvl(first_complete_date,
        if(total_play_sec / during_sec >= 0.9 and
           max_position_sec / during_sec >= 0.9, '$do_date', null)) first_complete_date
from (
     select
         nvl(new.user_id, old.user_id)                             user_id,
         nvl(new.video_id, old.video_id)                           video_id,
         nvl(new.video_name, old.video_name)                       video_name,
         nvl(new.chapter_id, old.chapter_id)                       chapter_id,
         nvl(new.chapter_name, old.chapter_name)                   chapter_name,
         nvl(new.course_id, old.course_id)                         course_id,
         nvl(new.total_play_sec, 0L) + nvl(old.total_play_sec, 0L) total_play_sec,
         nvl(new.position_sec, old.position_sec)                   position_sec,
         if(new.max_position_sec is null, old.max_position_sec,
            if(old.max_position_sec is null, new.max_position_sec,
               if(new.max_position_sec > old.max_position_sec,
                  new.max_position_sec, old.max_position_sec)))    max_position_sec,
         old.first_sec_complete_date,
         old.first_process_complete_date,
         old.first_complete_date,
         during_sec,
         course_name
     from (
          select
              calculated.user_id  user_id,
              calculated.video_id video_id,
              video_name,
              chapter_id,
              chapter_name,
              course_id,
              total_play_sec,
              position_sec,
              max_position_sec,
              during_sec,
              course_name
          from (
               select
                   user_id,
                   video_id,
                   video_name,
                   chapter_id,
                   chapter_name,
                   course_id,
                   total_play_sec,
                   max_position_sec,
                   during_sec,
                   course_name
               from (
                    select
                        user_id,
                        aggred.video_id,
                        video_name,
                        chapter_id,
                        chapter_name,
                        course_id,
                        total_play_sec,
                        max_position_sec,
                        during_sec,
                        course_name
                    from (
                         select
                             common.uid                 user_id,
                             appvideo.video_id,
                             sum(appvideo.play_sec)     total_play_sec,
                             max(appvideo.position_sec) max_position_sec
                         from ${hive_db}.ods_log_inc
                         where appvideo is not null
                           and dt = '$do_date'
                         group by common.uid, appvideo.video_id
                         ) aggred
                    left join (
                              select
                                  video_id,
                                  video_name,
                                  chapter_id,
                                  chapter_name,
                                  course_id,
                                  course_name,
                                  during_sec
                              from ${hive_db}.dim_chapter_video_full
                              where dt = '$do_date'
                              ) dim_video
                    on aggred.video_id = dim_video.video_id
                    ) joined
               ) calculated
          left join (
                    select
                        user_id,
                        video_id,
                        position_sec
                    from (
                         select
                             common.uid            user_id,
                             appvideo.video_id,
                             appvideo.position_sec,
                             row_number() over (partition by common.uid, appvideo.video_id
                                 order by ts desc) rk
                         from ${hive_db}.ods_log_inc
                         where appvideo is not null
                           and dt = '$do_date'
                         ) origin
                    where rk = 1
                    ) curpos
          on calculated.user_id = curpos.user_id
              and calculated.video_id = curpos.video_id
          ) new
     full outer join
     (
     select
         user_id,
         video_id,
         video_name,
         chapter_id,
         chapter_name,
         course_id,
         total_play_sec,
         position_sec,
         max_position_sec,
         first_sec_complete_date,
         first_process_complete_date,
         first_complete_date
     from ${hive_db}.dwd_learn_play_stats_full
     where dt = date_sub('$do_date', 1)
     ) old
     on new.user_id = old.user_id
         and new.video_id = old.video_id
     ) final
where video_id is  not null;
"

# 考试域答卷事务事实表
dwd_examination_test_paper_inc="
set hive.exec.dynamic.partition.mode = nonstrict;
insert overwrite table ${hive_db}.dwd_examination_test_paper_inc partition (dt)
select
    data.id,
    data.paper_id,
    data.user_id,
    date_format(data.create_time, 'yyyy-MM-dd'),
    data.score,
    data.duration_sec,
    data.create_time,
    data.submit_time,
    data.update_time,
	date_format(data.create_time, 'yyyy-MM-dd') as dt
from ${hive_db}.ods_test_exam_inc
where dt = '$do_date'
  and type = 'bootstrap-insert'
  and data.deleted = '0';
"

# 考试域答题事务事实表
dwd_examination_test_question_inc="
set hive.exec.dynamic.partition.mode = nonstrict;
insert overwrite table ${hive_db}.dwd_examination_test_question_inc partition (dt)
select
    data.id,
    data.user_id,
    data.paper_id,
    data.question_id,
    date_format(data.create_time, 'yyyy-MM-dd'),
    data.answer,
    data.is_correct,
    data.score,
    data.create_time,
    data.update_time,
	date_format(data.create_time, 'yyyy-MM-dd') as dt
from ${hive_db}.ods_test_exam_question_inc
where dt = '$do_date'
  and type = 'bootstrap-insert'
  and data.deleted = '0';
"

# 互动域课程评价事务事实表
dwd_interaction_review_inc="
set hive.exec.dynamic.partition.mode = nonstrict;
insert overwrite table ${hive_db}.dwd_interaction_review_inc partition (dt)
select
    data.id,
    data.user_id,
    data.course_id,
    date_format(from_utc_timestamp(ts * 1000, 'GMT+8'), 'yyyy-MM-dd'),
    data.review_stars,
    data.create_time,
	date_format(data.create_time, 'yyyy-MM-dd') as dt
from ${hive_db}.ods_review_info_inc
where dt = '$do_date'
  and type = 'bootstrap-insert';
"

tables=(
	"dwd_trade_cart_add_inc"
	"dwd_trade_order_detail_inc"
	"dwd_trade_pay_detail_suc_inc"
	"dwd_trade_course_order_inc"
	"dwd_user_register_inc"
	"dwd_user_login_inc"
	"dwd_traffic_page_view_inc"
	"dwd_learn_play_inc"
	"dwd_learn_play_stats_full"
	"dwd_examination_test_paper_inc"
	"dwd_examination_test_question_inc"
	"dwd_interaction_review_inc"
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