# DATA PRE PROCESSING CODE SHEET 

# Check table's limited data 
USE Test1;
desc sales_source_data_combined_0411_0415;
select * from sales_source_data_combined_0411_0415 limit 5;

# Change table header's name
-- avoid header's name is same as MySQL FUNCTION, easy to be confused. 
alter table sales_source_data_combined_0411_0415 change timestamp timestamps int(14);
desc sales_source_data_combined_0411_0415;

# Check null value
select * from sales_source_data_combined_0411_0415 where Sales_Amount is null;
select * from sales_source_data_combined_0411_0415 where StoreCode is null;
select * from sales_source_data_combined_0411_0415 where ProductCode is null;

# Check duplicate value
-- You do not want to have duplicated ID number(usually as PK) in the Parent Table, when you will link FK to other table in the future.
Select store_id, store_name from Store_infor
GROUP BY store_id, store_name
HAVING count(*)>1;

# Deduplication 去重
alter table Store_infor add duplicate_id int first;
select * from Store_infor limit 5;
alter table Store_infor modify id int primary key auto_increment;

delete Store_infor from
Store_infor,
(
Select store_id, store_name,min(duplicate_id) from Store_infor
GROUP BY store_id, store_name
HAVING count(*)>1
) t2
where Store_infor.store_id=t2.store_id
and Store_infor.store_name=t2.store_name
	-- and other important column should be same (duplicate)
and Store_infor.duplicate_id>t2.duplicate_id

# Change buffer value
show VARIABLES like '%_buffer%';
set GLOBAL innodb_buffer_size = ? 
	-- unit is bytes
	-- usually as 50%~80% of physical RAM 
	-- usually as the total size of your imported source table 
	-- 配置缓冲池的大小，在内存允许的情况下，DBA往往会建议调大这个参数，越多数据和索引放到内存里，数据库的性能会越好。（一般为物理内存的50%~80%）

# Add date time hour 
-- When you need to analyze data in dates or times in a day. 
-- Datetime
alter table sales_source_data_combined_0411_04151 add datetimes TIMESTAMP(0);
update sales_source_data_combined_0411_04151 set datetimes = FROM_UNIXTIME(timestamps);
	-- This function in MySQL helps to return date /DateTime representation of a Unix timestamp. The format of returning value will be ‘YYYY-MM-DD HH:MM:SS’ or ‘YYYYMMDDHHMMSS’, depending on the context of the function.
select * from sales_source_data_combined_0411_04151 limit 5; 
-- Date 
alter table sales_source_data_combined_0411_04151 add dates char(10);
alter table sales_source_data_combined_0411_04151 add hours char(10);
alter table sales_source_data_combined_0411_04151 add times char(10);
update sales_source_data_combined_0411_04151 set dates = substring(datetimes,1,10);
update sales_source_data_combined_0411_04151 set hours = substring(datetimes,12,8);
update sales_source_data_combined_0411_04151 set times = substring(datetimes,12,1);
	-- substring(expression, position, length)
select * from sales_source_data_combined_0411_04151 limit 5; 

# Outlier Execution
-- check if the date&time period of extracted source data is same as the target period.
select max(datetimes),min(datetimes) from sales_source_data_combined_0411_04151;
delete from sales_source_data_combined_0411_04151
where datetimes < "?"
or datetimes > "?";

# Count how many rows
-- check if you make critical delete mistake 
select * from sales_source_data_combined_0411_0415 limit 5;
select count(1) from sales_source_data_combined_0411_0415;

