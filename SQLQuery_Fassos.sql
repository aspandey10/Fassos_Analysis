--CREATION OF VARIOUS TABLES


drop table if exists driver;
CREATE TABLE driver(driver_id integer,reg_date date); 

INSERT INTO driver(driver_id,reg_date) 
 VALUES (1,'01-01-2021'),
(2,'01-03-2021'),
(3,'01-08-2021'),
(4,'01-15-2021');


drop table if exists ingredients;
CREATE TABLE ingredients(ingredients_id integer,ingredients_name varchar(60)); 

INSERT INTO ingredients(ingredients_id ,ingredients_name) 
 VALUES (1,'BBQ Chicken'),
(2,'Chilli Sauce'),
(3,'Chicken'),
(4,'Cheese'),
(5,'Kebab'),
(6,'Mushrooms'),
(7,'Onions'),
(8,'Egg'),
(9,'Peppers'),
(10,'schezwan sauce'),
(11,'Tomatoes'),
(12,'Tomato Sauce');

drop table if exists rolls;
CREATE TABLE rolls(roll_id integer,roll_name varchar(30)); 

INSERT INTO rolls(roll_id ,roll_name) 
 VALUES (1	,'Non Veg Roll'),
(2	,'Veg Roll');

drop table if exists rolls_recipes;
CREATE TABLE rolls_recipes(roll_id integer,ingredients varchar(24)); 

INSERT INTO rolls_recipes(roll_id ,ingredients) 
 VALUES (1,'1,2,3,4,5,6,8,10'),
(2,'4,6,7,9,11,12');

drop table if exists driver_order;
CREATE TABLE driver_order(order_id integer,driver_id integer,pickup_time datetime,distance VARCHAR(7),duration VARCHAR(10),cancellation VARCHAR(23));
INSERT INTO driver_order(order_id,driver_id,pickup_time,distance,duration,cancellation) 
 VALUES(1,1,'01-01-2021 18:15:34','20km','32 minutes',''),
(2,1,'01-01-2021 19:10:54','20km','27 minutes',''),
(3,1,'01-03-2021 00:12:37','13.4km','20 mins','NaN'),
(4,2,'01-04-2021 13:53:03','23.4','40','NaN'),
(5,3,'01-08-2021 21:10:57','10','15','NaN'),
(6,3,null,null,null,'Cancellation'),
(7,2,'01-08-2020 21:30:45','25km','25mins',null),
(8,2,'01-10-2020 00:15:02','23.4 km','15 minute',null),
(9,2,null,null,null,'Customer Cancellation'),
(10,1,'01-11-2020 18:50:20','10km','10minutes',null);


drop table if exists customer_orders;
CREATE TABLE customer_orders(order_id integer,customer_id integer,roll_id integer,not_include_items VARCHAR(4),extra_items_included VARCHAR(4),order_date datetime);
INSERT INTO customer_orders(order_id,customer_id,roll_id,not_include_items,extra_items_included,order_date)
values (1,101,1,'','','01-01-2021  18:05:02'),
(2,101,1,'','','01-01-2021 19:00:52'),
(3,102,1,'','','01-02-2021 23:51:23'),
(3,102,2,'','NaN','01-02-2021 23:51:23'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,1,'4','','01-04-2021 13:23:46'),
(4,103,2,'4','','01-04-2021 13:23:46'),
(5,104,1,null,'1','01-08-2021 21:00:29'),
(6,101,2,null,null,'01-08-2021 21:03:13'),
(7,105,2,null,'1','01-08-2021 21:20:29'),
(8,102,1,null,null,'01-09-2021 23:54:33'),
(9,103,1,'4','1,5','01-10-2021 11:22:59'),
(10,104,1,null,null,'01-11-2021 18:34:49'),
(10,104,1,'2,6','1,4','01-11-2021 18:34:49');



--A:Roll Metrices
--B:Driver and Customer Experience
--C:Ingredient Optimisation
--D:Pricing and Rating



--Viewing all the datasets
select * from customer_orders;
select * from driver_order;
select * from ingredients;
select * from driver;
select * from rolls;
select * from rolls_recipes;



--A:Roll metrices

--How many rolls were ordered?
SELECT count(roll_id) 
FROM customer_orders;

--How many unique customer orders were made?
SELECT COUNT(DISTINCT(order_id))
FROM customer_orders;

--How many successful orders were delivered by each driver?


with cte as
(
SELECT driver_id,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS successful_orders
FROM driver_order
)
SELECT driver_id,SUM(successful_orders)
FROM cte
GROUP BY driver_id;


--How many of each type of roll was delivered?
with cte as
(
SELECT co.order_id,co.roll_id,r.roll_name,do.driver_id,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS successful_orders
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
JOIN rolls r
ON co.roll_id=r.roll_id
)
SELECT roll_id,roll_name,sum(successful_orders) as total
FROM cte
WHERE successful_orders=1
GROUP BY roll_id,roll_name;


--How many veg and non veg rolls were ordered by each customer?

SELECT co.customer_id,r.roll_name,count(order_date) as orders
FROM customer_orders co
JOIN rolls r
ON co.roll_id=r.roll_id
GROUP BY customer_id,roll_name
ORDER BY customer_id;

--What was the maximum number of rolls ordered in single time?

SELECT top 1 customer_id,count(roll_id) as total
FROM customer_orders
GROUP BY customer_id
ORDER BY total DESC; 

--What was the maximum number of rolls delivered at a single order?
with cte as
(
SELECT co.order_id,co.roll_id,do.driver_id,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS successful_orders
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
)
SELECT order_id,count(successful_orders) AS delivery
FROM cte
GROUP BY order_id
ORDER BY delivery DESC;

--For each customer, how many delivered rolls had at least one change and no change at all?

with cte as
(
SELECT co.customer_id,co.roll_id,co.not_include_items,co.extra_items_included,
CASE 
	WHEN do.cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS delivery
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
),

cte2 as
(
SELECT customer_id,roll_id,not_include_items,extra_items_included,
CASE 
	WHEN (not_include_items IS NULL OR not_include_items LIKE '%NaN%' OR not_include_items='') AND 
	( extra_items_included IS NULL OR extra_items_included LIKE '%NaN%' OR extra_items_included='') THEN 0
	ELSE 1
	END AS change1
FROM cte
WHERE delivery=1
)
SELECT customer_id,count(roll_id) as total_order,sum(change1) as change,count(roll_id)-sum(change1) as no_change
FROM cte2
GROUP BY customer_id;


--How many rolls were deliverd that has both extras and exclusion
with cte as
(
SELECT co.customer_id,co.roll_id,co.not_include_items,co.extra_items_included,
CASE 
	WHEN do.cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS delivery
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
),
cte2 as
(
SELECT customer_id,roll_id,not_include_items,extra_items_included,
CASE 
	WHEN (not_include_items IS NULL OR not_include_items LIKE '%NaN%' OR not_include_items='') OR 
	( extra_items_included IS NULL OR extra_items_included LIKE '%NaN%' OR extra_items_included='') THEN 0
	ELSE 1
	END AS change1
FROM cte
WHERE delivery=1
)
SELECT customer_id,count(roll_id) as total_orders, sum(change1) as both_change
FROM cte2
GROUP BY customer_id;


--What was the total number of rolls ordered for each hour of the day?
select CONCAT(DATEPART(hour,order_date) ,'-', DATEPART(hour,DATEADD(hour,1,order_date))) as time_interval,count(order_id) as total_orders
FROM customer_orders
GROUP BY CONCAT(DATEPART(hour,order_date) ,'-', DATEPART(hour,DATEADD(hour,1,order_date)))


--What was the number of orders for each day of the week?
SELECT DATENAME(dw,order_date),count(distinct(order_id)) as total_order
FROM customer_orders
GROUP BY DATENAME(WEEKDAY,order_date)
ORDER BY DATENAME(WEEKDAY,order_date);



--B:Driver and Customer Experience
-------------------------------------


--What was the average time in minutes it took for each driver to arrive at fasoos headquater?

SELECT do.driver_id,AVG(DATEDIFF(minute,co.order_date,do.pickup_time)) as time
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
WHERE do.pickup_time IS NOT NULL
GROUP BY do.driver_id;--shows wrong value because order date and pickup time are in different years for last 3 data


--Is there any relationship between the number of rolls and how long does the order takes to prepare?

SELECT co.order_id,DATEDIFF(minute,co.order_date,do.pickup_time) as timetaken,count(roll_id) as number_of_rolls
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
GROUP BY co.order_id,DATEDIFF(minute,co.order_date,do.pickup_time)
ORDER BY number_of_rolls DESC;

-->there is directly proportional relationship between number of rolls and time taken


--What was the average time taken for delivery for each customer?
SELECT co.customer_id,AVG(DATEDIFF(minute,co.order_date,do.pickup_time)) as avg_time
FROM customer_orders co
JOIN driver_order do
ON co.order_id=do.order_id
GROUP By co.customer_id;


--What was the average distance travelled for each customer?

SELECT co.customer_id,ROUND(AVG(CONVERT(float,TRIM(REPLACE(do.distance,'km','')))),2) as average_distance
FROM customer_orders co
JOIN driver_order do 
ON co.order_id=do.order_id
WHERE do.distance IS NOT NULL
GROUP BY co.customer_id;

--What is the difference between the longest and shortest delivery times across all the orders?

SELECT MAX(CONVERT(int,TRIM(REPLACE(REPLACE(REPLACE(duration,'minutes',''),'mins',''),'minute',''))))-
MIN(CONVERT(int,TRIM(REPLACE(REPLACE(REPLACE(duration,'minutes',''),'mins',''),'minute','')))) as date_diff
FROM driver_order 
WHERE duration IS NOT NULL;


with cte as
(
SELECT
CASE
	WHEN duration LIKE '%min%' THEN LEFT(duration,CHARINDEX('m',duration)-1)
	ELSE duration
	END AS dur
FROM driver_order 
WHERE duration IS NOT NULL
)
SELECT MAX(CONVERT(int,dur))-MIN(CONVERT(int,dur))
FROM cte;


--What was the average speed for each driver for each delivery and do you notice any trend in these values?
with cte as
(
SELECT driver_id,CONVERT(float,TRIM(REPLACE(lower(distance),'km',''))) as distance,
CAST(CASE 
	WHEN duration LIKE '%min%' THEN LEFT(duration,CHARINDEX('m',duration)-1)
	ELSE duration
	END AS float) as  dur
FROM driver_order
WHERE distance IS NOT NULL
)
SELECT driver_id,ROUND(AVG(distance/(dur/60)),2) as speed
FROM cte
GROUP BY driver_id;


--What is the successful delivery percentage for each driver?
with cte as
(
SELECT driver_id,order_id,
CASE 
	WHEN cancellation LIKE '%cancel%' THEN 0
	ELSE 1
	END AS cancel
FROM driver_order
)
SELECT driver_id,(CAST(SUM(cancel) AS float)/COUNT(order_id))*100 as success_rate
FROM cte
GROUP BY driver_id;















