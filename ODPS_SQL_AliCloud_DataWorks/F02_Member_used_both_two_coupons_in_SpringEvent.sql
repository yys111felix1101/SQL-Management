--author:FelixYeung
--create time:2022-05-22 11:50:40
--********************************************************************--

--Purpose :春困活动两款优惠券均核销的会员数 How many member used both two coupons in SpringEvent?

SELECT 
    COUNT(已使用优惠券数量) 实用两张优惠券的会员数
FROM 
(
    SELECT 
        f_mrvipnumber
        ,COUNT(f_templateno) 已使用优惠券数量
    FROM junya_project.dwd_junya_t_mr_coupon_da 
    WHERE pt='${bizdate}'
        AND f_status='USED'
        AND f_templateno in('CT3299','CT3298')
    GROUP BY f_mrvipnumber
)
WHERE 已使用优惠券数量=2