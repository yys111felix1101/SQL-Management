# Analysis Case 1: Customer Acquisition

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