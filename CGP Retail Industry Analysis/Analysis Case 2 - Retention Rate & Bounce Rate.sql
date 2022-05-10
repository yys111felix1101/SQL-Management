# Analysis Case 2: Retention Rate & Bounce Rate 

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
