--odps sql 
--********************************************************************--
--author:FelixYeung
--create time:2022-05-22 16:38:30
--********************************************************************--

SELECT  t1.create_day --日期
        ,t1.sum_vip_count --现存会员数
        ,t2.total_recharge_num --储值会员数
FROM    (
            SELECT  create_day
                    ,sum(vip_num) over(SORT BY create_day) sum_vip_count    --会员日累计的会员数
            FROM    (
                        SELECT  to_char(f_createtime ,'YYYY-MM-DD') create_day
                                ,count(f_number) AS vip_num
                        FROM    junya_project.dwd_junya_t_member_vip_da
                        WHERE   pt = '${bizdate}'
                        GROUP BY to_char(f_createtime ,'YYYY-MM-DD')
                    ) 
            WHERE   create_day IS NOT NULL
        ) t1
LEFT join (
              SELECT  recharge_day
                      ,sum(day_recharge_num) OVER (ORDER BY recharge_day) total_recharge_num -- Window Function
              FROM    (
                          SELECT  recharge_day
                                  ,count(f_mrvipnumber) day_recharge_num
                          FROM    (
                                      SELECT  min(recharge_day) recharge_day
                                              ,f_mrvipnumber
                                      FROM    (
                                                  SELECT  DISTINCT mrvipnumber AS f_mrvipnumber  --Not Repeated Value
                                                          ,to_char(successtime,"yyyy-mm-DD") AS recharge_day
                                                  FROM    junya_project.dwd_t_mr_vip_recharge_da
                                                  WHERE   pt = '20211010'
                                                  AND     TYPE = "RECHARGE"
                                                  UNION
                                                  SELECT  DISTINCT f_mrvipnumber
                                                          ,to_char(f_successtime,"yyyy-mm-DD") AS recharge_day
                                                  FROM    junya_project.dwd_junya_t_mr_vip_recharge_da
                                                  WHERE   pt = '${bizdate}'
                                                  AND     f_source = 'APP_WECHAT'
                                                  AND     f_status = "COMPLETE"
                                              ) 
                                      GROUP BY f_mrvipnumber
                                  ) 
                          GROUP BY recharge_day
                      ) 
          ) t2
ON      t1.create_day = t2.recharge_day
;

select * from junya_project.dwd_junya_t_member_account_trans_da where pt='${bizdate}' order by f_createtime desc limit 1000;

select pt,count(user_no) from junya_project.dwd_junya_t_member_savings_card_da
where pt <= '${bizdate}'
and status='VALID'
and amount>0
group by pt
;



select COUNT(DISTINCT  f_mrvipnumber)
--    ,to_char(f_successtime,"yyyy-mm") as recharge_month
from junya_project.dwd_junya_t_mr_vip_recharge_da
where pt='20211231'
and f_source = 'APP_WECHAT'
and f_status = "COMPLETE"
and ((f_successtime >='2020-07-01 00:00:00' and f_successtime<='2020-12-31 23:59:59')
or (f_successtime >='2021-04-01 00:00:00' and f_successtime<='2021-12-31 23:59:59'))


















