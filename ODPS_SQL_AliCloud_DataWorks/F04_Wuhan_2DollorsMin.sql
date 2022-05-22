--odps sql 
--********************************************************************--
--author:FelixYeung
--create time:2022-05-22 17:05:11
--********************************************************************--

insert overwrite  table    tmp_audit_cypos_order_detail_wh  -- insert to selected table
SELECT * FROM (
SELECT row_number()over(order by 门店编码,订单号 asc) row_num,*,cast((商品实收金额-会员储值增额) as STRING ) 商品净收余额 from 
(
SELECT 
t11.product_type 显示分类,
t1.f_name 商户名称,
t1.f_code 门店编码,
cast(SUBSTR(oi.f_ordercreatedat,1,10) as string)日期, -- SUBSTR(string,postion,length)
cast(SUBSTR(oi.f_ordercreatedat,12,8)  as string) 时间,
cast(t2.flow_no as STRING )银行流水号,
cast(o.f_bill  as string)订单号, -- change data type
CASE WHEN o.f_mrvipnumber is null or o.f_mrvipnumber='' THEN '否'
ELSE '是' end 是否会员,
case when t7.f_orderid is not null or t3.f_orderitemid is not null or t8.promotion_id  is not null 
            or t6.promotion_id  is not null  or t9.id is not null  or t10.id is not null
            or oi.f_discountamount-nvl(t4.discount_amount,0)!=0 
             then '是'  
        else '否' end 是否优惠 ,
cast(oi.f_name  as string)商品名称,
cast(oi.plu_no  as string)商品sku,
-- t3.f_discounttype 优惠类型,
case when t7.f_orderid is not null then t7.f_discountname 
        when t3.f_orderitemid is not null then t3.f_discountname 
        when t8.promotion_id   is not null  then t8.name
        when t6.promotion_id is not null then t6.name  
        when  oi.f_discountamount-nvl(t4.discount_amount,0)!=0  then '积点优惠'     
        end   优惠名称,
-- t3.f_category 优惠分类,
cast(o.f_mrvipnumber  as string) 会员卡号,
cast(oi.f_count-nvl(t4.count,0) as string)商品数量,
cast(oi.f_originalprice-nvl(t4.total_amount,0)  as string)商品应收金额,
cast(oi.f_discountamount-nvl(t4.discount_amount,0)  as string)商品优惠金额,
cast(oi.f_price-nvl(t4.payable_amount,0)  as string)商品实收金额,
-- cast(case when o.f_paytype in ('VIPCARD','COMBINED') then  (oi.f_price-nvl(t4.payable_amount,0))-((o.f_balance/o.f_price)*(oi.f_price-nvl(t4.payable_amount,0)) )
-- ELSE (oi.f_price-nvl(t4.payable_amount,0) ) end  as string)商品净收余额,
cast(case when o.f_paytype in ('VIPCARD','COMBINED') then  (o.f_balance/o.f_price)*(oi.f_price-nvl(t4.payable_amount,0)) 
else 0.0 end  as string) 会员储值余额,   -- 会员储值余额
cast(case when o.f_paytype in ('VIPCARD','COMBINED') then  (o.f_extra_blance/o.f_price)*(oi.f_price-nvl(t4.payable_amount,0)) 
else 0.0 end  as string) 会员储值增额,   -- 会员储值赠额
CASE WHEN (o.f_paytype='CASH' or ( f_received is not null and f_received !=0  ))THEN '是'
ELSE '否' end 是否现金,
o.f_paytype 支付类型
FROM 
( 
    SELECT * FROM junya_project.dwd_junya_t_order_item_da 
    WHERE pt='${bizdate}' 
    AND f_ordercreatedat BETWEEN '2022-04-01 00:00:00' AND '2022-05-09 00:00:00'   
   
) oi
LEFT JOIN 
(
    SELECT * FROM junya_project.dwd_junya_t_order_da 
    WHERE 
    pt='${bizdate}' 
) o ON o.f_id=oi.f_orderid
LEFT JOIN 
(
    SELECT f_id,f_code,f_name FROM junya_project.stg_junya_goods_t_branch
)t1 ON t1.f_id=oi.f_branchid
LEFT JOIN 
(   SELECT  DISTINCT order_no ,flow_no,type
    FROM junya_project.dwd_junya_t_order_flow_da WHERE pt='${bizdate}' AND  type in('WECHAT','ALIPAY','UNIONPAY') and flow_no is not NULL  
    
)t2 ON t2.order_no=o.f_bill
LEFT JOIN 
(
    SELECT f_discounttype,f_discountname,f_category,f_orderitemid FROM junya_project.dwd_junya_t_order_item_discount_da WHERE  pt='${bizdate}'  
)t3 ON t3.f_orderitemid=oi.f_id
LEFT JOIN 
(
    SELECT id,org_order_item_id,count,total_amount,discount_amount,payable_amount FROM junya_project.dwd_junya_t_refund_order_item_da  WHERE  pt='${bizdate}' AND   from_status!='REFUNDED'
)t4 ON t4.org_order_item_id=oi.f_id
LEFT JOIN (
    SELECT order_id,name,activity_id from junya_project.dwd_junya_t_order_promotion_da where pt='${bizdate}' AND  name NOT IN ('商家活动优惠','三方外卖平台优惠')
)t5 ON t5.order_id=oi.f_orderid
LEFT JOIN 
(
    SELECT *  from junya_project.dwd_junya_t_order_item_promotion_da  where pt='${bizdate}' and name not in('信息部测试优惠' )
)t6 on t6.order_item_id=oi.f_id
left join (select * from 
        junya_project.dwd_junya_t_order_discount_da
             where pt='${bizdate}') t7 on o.f_id=t7.f_orderid
left join junya_project.stg_junya_t_order_promotion_offline t8 on o.f_id=t8.order_id
left join junya_project.stg_junya_t_activity_info t9 on  t8.activity_id  = t9.id
 left join junya_project.stg_junya_t_activity_info  t10 on t6.activity_id = t10.id
 left join (SELECT
        t3.id,
        t2.name product_type,
        t1.name as category_name,
        t3.name as product_name,
        t3.code as product_code
        FROM junya_project.stg_junya_goods_t_goods_category_info t1
        LEFT JOIN junya_project.stg_junya_goods_t_goods_category_info t2
        on t1.parent_id = t2.id
        LEFT JOIN junya_project.stg_junya_goods_t_goods t3
        on t1.id = t3.category_id 
        WHERE t2.name is not null) t11 
    on oi.f_productid=t11.id
 LEFT JOIN junya_project.dim_branch_info  t ON t.f_id = o.f_branchid 
    WHERE o.pos_type=3
    AND o.f_status not in('INIT','CANCEL', 'CLOSED')
    and o.f_branchid not in (9211, 9212) 
    and t4.id is null 
    and t.f_city='武汉市'
) 
)
;