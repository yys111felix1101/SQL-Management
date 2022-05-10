# Analysis Case 3: Consumer Behaviour 
# Time Series Analysis
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


