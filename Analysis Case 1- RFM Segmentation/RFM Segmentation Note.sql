-- RFM analysis for Customer Segmentation
-- RFM stands for Recency, Frequency, and Monetary value, each corresponding to some key customer trait. These RFM metrics are important indicators of a customer’s behavior because frequency and monetary value affects a customer’s lifetime value, and recency affects retention, a measure of engagement.
-- RFM is a data-driven customer segmentation technique that allows marketers to take tactical decisions. It empowers marketers to quickly identify and segment users into homogeneous groups and target them with differentiated and personalized marketing strategies. This in turn improves user engagement and retention.

drop table if exists rfm_model;
create table rfm_model(
user_id int,
frequency int,
recent char(10)
);

insert into rfm_model
select user_id
,count(user_id) 'Recency'
,max(dates) 'Frequency'
from user_behavior
where behavior_type='buy'  -- from real purchased history. In my case, I only anlyse the registered member in app to scale the the model.
group by user_id
order by 2 desc,3 desc;

-- Marking the customer group by Frequency 
alter table rfm_model add column fscore int;

update rfm_model
set fscore = case
when frequency between 100 and 262 then 5  -- 262 is the max frequency time 
when frequency between 50 and 99 then 4
when frequency between 20 and 49 then 3
when frequency between 5 and 20 then 2
else 1
end

-- Marking the customer group by Purchase Time
alter table rfm_model add column rscore int;

update rfm_model
set rscore = case
when recent = '2017-12-03' then 5  -- example for analyse a weekly performance (28/11 - 03/12)
when recent in ('2017-12-01','2017-12-02') then 4
when recent in ('2017-11-29','2017-11-30') then 3
when recent in ('2017-11-27','2017-11-28') then 2
else 1
end

select * from rfm_model

-- Labeling segments
set @f_avg=null;
set @r_avg=null;
select avg(fscore) into @f_avg from rfm_model;
select avg(rscore) into @r_avg from rfm_model;

select *
,(case
when fscore>@f_avg and rscore>@r_avg then 'Champions 价值用户'
when fscore>@f_avg and rscore<@r_avg then 'At Risk Customers 保持用户'
when fscore<@f_avg and rscore>@r_avg then 'Needs Attention 发展用户'
when fscore<@f_avg and rscore<@r_avg then 'Hibernating 挽留用户'
end) class
from rfm_model

-- Update table
alter table rfm_model add column class varchar(40);
update rfm_model
set class = case
when fscore>@f_avg and rscore>@r_avg then 'Champions 价值用户'
when fscore>@f_avg and rscore<@r_avg then 'At Risk Customers 保持用户'
when fscore<@f_avg and rscore>@r_avg then 'Needs Attention 发展用户'
when fscore<@f_avg and rscore<@r_avg then 'Hibernating 挽留用户'
end

select class,count(user_id) from rfm_model
group by class

-- Increase relative importance by nature of business: For example, my previous company is doing retail business selling milk products, a customer who searches and purchases products every month will have a higher recency and frequency score than monetary score. Accordingly, the RFM score could be calculated by giving more weight to R and F scores than M.
-- Action according the RFM analysis： personalized messaging, differentiated media interaction, thanksgiving activity for Loyalists, New launches, Price Discrimination, etc.
