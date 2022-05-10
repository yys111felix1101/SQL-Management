# CGP Retail Industry Analysis Theory
----------------------------------------------------------------
# 1.Customer Acquisition

-- Create temporary table by part of data to test coding accuracy. Do not use total data at first to avoid the cache's burden.
create table temp_behavior like sales_source_data_combined_0411_0415;
insert into temp_behavior
select * from user_behavior limit 100; -- only use first 100 to test

-- PV (Page Views), UV (Unique Visitors)
-- Page Depth = PV/UV
select dates
,count(*) 'pv' 
,count(distinct user_id) 'uv' 
,round(count(*)/count(distinct user_id),1) 'pv/uv' 
from temp_behavior
where behavior_type='pv'
GROUP BY dates;

select * from temp_behavior; -- It's important to check accuracy

-- Now you can use the total target data

---------------------------------------------------------------- 
# 2.Retention

-- Data Cleaning 
select * from user_behavior where dates is null;
delete from user_behavior where dates is null;

select user_id,dates 
from temp_behavior
group by user_id,dates;

-- Self join to compare every action (purchase/visit) that customers made in sequence.
select * from 
(select user_id,dates 
from temp_behavior
group by user_id,dates
) a
,(select user_id,dates 
from temp_behavior
group by user_id,dates
) b
-- Filter the unwanted outliers(a.dates>b.dates), it would be error in further calculation. 
where a.user_id=b.user_id and a.dates<b.dates;

-- Find Retening Value
select a.dates
,count(if(datediff(b.dates,a.dates)=0,b.user_id,null)) retention_0
,count(if(datediff(b.dates,a.dates)=1,b.user_id,null)) retention_1
,count(if(datediff(b.dates,a.dates)=3,b.user_id,null)) retention_3 from

(select user_id,dates 
from temp_behavior  -- Use temporary data to test coding accuracy
group by user_id,dates
) a
,(select user_id,dates 
from temp_behavior 
group by user_id,dates
) b
where a.user_id=b.user_id and a.dates<=b.dates
group by a.dates

-- Find Retening Rate
	-- = ((E‐N)/S)) x 100
 	-- E = number of customers at end of period
	-- N = number of new customers acquired during period
	-- S = number of customers at start of period
select a.dates
,count(if(datediff(b.dates,a.dates)=1,b.user_id,null))/count(if(datediff(b.dates,a.dates)=0,b.user_id,null)) retention_1
from
(select user_id,dates 
from temp_behavior  -- Use temporary data to test coding accuracy
group by user_id,dates
) a
,(select user_id,dates 
from temp_behavior
group by user_id,dates
) b
where a.user_id=b.user_id and a.dates<=b.dates
group by a.dates

-- Use total target data and save result
create table retention_rate (
dates char(10),
retention_1 float 
);

insert into retention_rate 
select a.dates
,count(if(datediff(b.dates,a.dates)=1,b.user_id,null))/count(if(datediff(b.dates,a.dates)=0,b.user_id,null)) retention_1
from
(select user_id,dates -- Use total target data
from user_behavior  
group by user_id,dates
) a
,(select user_id,dates 
from user_behavior
group by user_id,dates
) b
where a.user_id=b.user_id and a.dates<=b.dates
group by a.dates

select * from retention_rate -- Check

-- Bounce Rate
	-- = (Single Visit/Total Visit)x100
--  Single Visit Value  -- 88
select count(*) 
from 
(
select user_id from user_behavior
group by user_id
having count(behavior_type)=1
) a
-- Total Visit Value
select sum(pv) from pv_uv_puv; -- 89660670

--  = 0.00009815%

---------------------------------------------------------------- 
# 3.Consume Behaviour 
# 时间序列分析
create table date_hour_behavior(
dates char(10),
hours char(2),
pv int,
cart int,
fav int,
buy int);

insert into date_hour_behavior
select dates,hours
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
from user_behavior
group by dates,hours
order by dates,hours

# 用户转化率分析
-- 统计各类行为用户数 

# 行为路径分析
create view user_behavior_view as  
select user_id,item_id
,count(if(behavior_type='pv',behavior_type,null)) 'pv'
,count(if(behavior_type='fav',behavior_type,null)) 'fav'
,count(if(behavior_type='cart',behavior_type,null)) 'cart'
,count(if(behavior_type='buy',behavior_type,null)) 'buy'
from temp_behavior
group by user_id,item_id

-- Standardised user behavior  
create view user_behavior_standard as  -- Create View for repeated queries
select user_id
,item_id
,(case when pv>0 then 1 else 0 end) Page_Viewed
,(case when fav>0 then 1 else 0 end) Favorited
,(case when cart>0 then 1 else 0 end) Put_in_cart
,(case when buy>0 then 1 else 0 end) Purchased
from user_behavior_view

-- Create User behavior path id of successful purchase history
create view user_behavior_path as
select *,
concat(Page_Viewed,Favorited,Put_in_cart,Purchased) user_behavior_path_id
from user_behavior_standard as a
where a.Purchased>0

-- Create path_count
create view path_count as
select user_behavior_path_id
,count(*) Quant
from user_behavior_path
group by user_behavior_path
order by Quant desc

-- User Behavior Classification
create table user_behavior_classification(
path_type char(4),
description varchar(40));

insert into user_behavior_classification 
values('0001','直接购买了'),
('1001','浏览后购买了'),
('0011','加购后购买了'),
('1011','浏览加购后购买了'),
('0101','收藏后购买了'),
('1101','浏览收藏后购买了'),
('0111','收藏加购后购买了'),
('1111','浏览收藏加购后购买了')

-- Join Path and Classification
select * from path_count p 
join user_behavior_classification r 
on p.user_behavior_path_id=r.path_type 
order by Quant desc


