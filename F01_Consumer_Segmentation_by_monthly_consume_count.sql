--odps sql 
--********************************************************************--
--author:FelixYeung
--create time:2022-02-28 14:08:57
--********************************************************************--

select 
    distinct tt1.f_mrvipnumber
    ,to_char(tt2.f_birthday,'yyyy-mm-dd') real_birthday
    ,concat(SUBSTR(to_char(GETDATE(),'yyyy-mm-dd'),1,4), SUBSTR(to_char(tt2.f_birthday,'yyyy-mm-dd'),5,10) ) birthday
from 
(

 select f_mrvipnumber,sum(f_price) f_price from sexytea_project.stg_flipos_t_order_da 
    where pt='20211008'
    and DATEDIFF(to_date(GETDATE()),TO_DATE(f_createdat))<=365
    and f_mrvipnumber is not null
    group by f_mrvipnumber having sum(f_price)>=20

union all


------------------------------  消费剔除拼单 ------------------------------ 
  select
         t1.f_mrvipnumber 
         ,sum(t1.f_price)-sum(nvl(t2.refund_total_amount,0)) 
         
     from 
       sexytea_project. dwd_sexytea_t_order_da t1
     left join (select * from sexytea_project. dwd_sexytea_t_refund_order_da where pt='${bizdate}') t2 on t1.f_id=t2.order_id
     where 
        t1.pt='${bizdate}'
        and t1.type!=1
        and t1.pos_type=3
        and t1.f_status not in( 'INIT' ,'CANCEL' ,'CLOSED')
        AND t1.f_branchid not in (9211, 9212)
        and t1.f_mrvipnumber is not null
        and t1.f_mrvipnumber !=''
        and DATEDIFF(to_date(GETDATE()),TO_DATE(t1.f_createdat ))<=365
        
        group by  t1.f_mrvipnumber
    having sum(t1.f_price)-sum(nvl(t2.refund_total_amount,0)) >=20


union all 
------------------------------  消费拼单数据 ------------------------------ 
  select
         t2.user_no 
         ,sum(t2.price)
         
     from 
            sexytea_project.dwd_sexytea_t_order_da t1
     left join (select * from  sexytea_project.dwd_sexytea_t_order_group_user_da where pt='${bizdate}') t2 on t1.group_buy_no=t2.group_buy_no
     where 
        t1.pt='${bizdate}'
        and t1.type=1
        and t1.pos_type=3
        and t1.f_status not in( 'INIT' ,'CANCEL' ,'CLOSED')
        AND t1.f_branchid not in (9211, 9212)
        and t1.f_mrvipnumber is not null
        and DATEDIFF(to_date(GETDATE()),TO_DATE(t2.create_time ))<=365
        group by  t2.user_no
    having sum(t2.price) >=20




union all

-------------------------------------------------- 有积点发放 -------------------------------------------------- 

    select
             t2.f_number
             ,sum(case when f_type='CONVERT_POINT' then abs(f_pointcount) 
                    when f_type='CONVERT_POINT_REFUND' then -abs(f_pointcount)  end )  point_num
        from    sexytea_project.dwd_sexytea_t_member_point_trans_da t1
            left join (select * from sexytea_project.dwd_sexytea_t_member_vip_account_da where pt='${bizdate}') t2 on t1.f_accountid=t2.f_id
        
            where t1.pt='${bizdate}'
            and t1.f_type in ('CONVERT_POINT','CONVERT_POINT_REFUND')
            and t2.f_number is not null
            and DATEDIFF(to_date(GETDATE()),TO_DATE(t1.f_createtime ))<=365
            group by  t2.f_number
            HAVING sum(case when f_type='CONVERT_POINT' then abs(f_pointcount) 
                    when f_type='CONVERT_POINT_REFUND' then -abs(f_pointcount)  end )>=1



union all 


------------------- 充值>=20 -------------------
SELECT
  t1.f_mrvipnumber 会员号
  , sum(f_amount) - sum(refund_amount)  amount
FROM
        sexytea_project.dwd_sexytea_t_mr_vip_recharge_da t1 
   where t1.pt='${bizdate}'  and f_status = 'COMPLETE' and refund_sign = 0 and DATEDIFF(to_date(GETDATE()),TO_DATE(t1.f_createtime ))<=365
  group by  t1.f_mrvipnumber
  having sum(f_amount) - sum(refund_amount) >= 20

) tt1 
inner join (

    select 
            t1.f_number,f_birthday
        from    sexytea_project.dwd_sexytea_t_member_vip_da t1
    where t1.pt='${bizdate}' 
        and substr(TO_CHAR(t1.f_birthday, "yyyy-mm-dd"),6,10)='02-29'

) tt2 on tt1.f_mrvipnumber=tt2.f_number
;