USE pizza_runner;
-------------------------Data Cleaning--------------------------------------
ALTER TABLE pizza_recipes
ALTER COLUMN toppings varchar(50);

ALTER TABLE pizza_toppings
ALTER COLUMN topping_name varchar(50);

INSERT INTO customer_orders ("order_id", "customer_id", "pizza_id", "exclusions", "extras", "order_time")
SELECT order_id
     , customer_id
     , pizza_id
     , SUBSTRING(exclusions, CHARINDEX(',', exclusions) + 2, 1)
     , SUBSTRING(extras, CHARINDEX(',', extras) + 2, 1)
     , order_time
FROM customer_orders
WHERE (order_id = 9 AND extras LIKE '%,%')
  OR (order_id = 10 AND extras LIKE '%,%');


UPDATE customer_orders
SET extras = SUBSTRING(extras, 1, 1)
  , exclusions = SUBSTRING(exclusions, 1, 1)
WHERE (order_id = 9 AND extras LIKE '%,%')
  OR (order_id = 10 AND extras LIKE '%,%');

UPDATE customer_orders
SET extras = NULL
WHERE extras IN ('null', ' ','NaN');

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', ' ','NaN');

SELECT 
    c.name AS column_name,
    t.name AS data_type
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('customer_orders');
-------------------------------------------------------
-- runner_orders
EXEC sp_rename 'runner_orders.distance', 'distance_km', 'COLUMN';
EXEC sp_rename 'runner_orders.duration', 'duration_min', 'COLUMN';

UPDATE runner_orders
SET distance_km = REPLACE(distance_km, 'km', '');

UPDATE runner_orders  
SET duration_min = SUBSTRING(duration_min, 1,2)
WHERE duration_min LIKE '%m%';

SELECT * from runner_orders
WHERE (pickup_time, distance_km, duration_min) IN ('null', ' ','NaN');

UPDATE runner_orders
SET 
    cancellation = NULL
    
WHERE 
	LEN(cancellation) < 5

UPDATE runner_orders
SET 
    pickup_time = NULL,
    distance_km = NULL,
    duration_min = NULL
    
WHERE 
	cancellation IS NOT NULL

SELECT 
    c.name AS column_name,
    t.name AS data_type
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('runner_orders');


ALTER TABLE runner_orders
ALTER COLUMN pickup_time datetime2
ALTER TABLE runner_orders
ALTER COLUMN distance_km DECIMAL(10,2)
ALTER TABLE runner_orders
ALTER COLUMN duration_min int;

----------------------------------------------------------------------------------------
-- A. Pizza Metrics
-- How many pizzas were ordered?
SELECT COUNT(*) FROM customer_orders;
-- How many unique customer orders were made?
SELECT COUNT(*)
FROM (
    SELECT DISTINCT order_id, customer_id, pizza_id, exclusions, extras, order_time 
    FROM customer_orders
) AS unique_order

-- How many successful orders were delivered by each runner?
SELECT runner_id, COUNT(*) FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;

-- How many of each type of pizza was delivered?
SELECT COUNT(*) FROM customer_orders c join runner_orders r on c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
SELECT pizza_name,COUNT(*) FROM customer_orders c join pizza_names p on c.pizza_id =p.pizza_id
GROUP BY pizza_name;

-- What was the maximum number of pizzas delivered in a single order?
SELECT MAX(number_of_pizza) FROM (

SELECT c.order_id, COUNT(*) number_of_pizza FROM customer_orders c join runner_orders r on c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY c.order_id) AS subquery;

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
SELECT c.customer_id,COUNT(*)FROM customer_orders c join runner_orders r on c.order_id = r.order_id
WHERE cancellation IS NULL AND extras IS NOT NULL or exclusions IS NOT NULL
GROUP BY c.customer_id;

-- How many pizzas were delivered that had both exclusions and extras?
SELECT c.customer_id,COUNT(*)FROM customer_orders c join runner_orders r on c.order_id = r.order_id
WHERE  cancellation IS NULL AND extras IS NOT NULL AND exclusions IS NOT NULL
GROUP BY c.customer_id;
-- What was the total volume of pizzas ordered for each hour of the day?
SELECT pickup_time,DATEPART(HOUR, pickup_time),DATEPART(DAY, pickup_time) AS extracted_hour
FROM runner_orders;

-- What was the volume of orders for each day of the week?
SELECT DATENAME(WEEKDAY, order_time) AS day_name,
		COUNT(order_id)
FROM 
    customer_orders
GROUP BY DATENAME(WEEKDAY, order_time);

-----------------------------------------------------------------------------------
-----B. Runner and Customer Experience
-- How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`)
SELECT 
  DATEPART(WEEK, registration_date) AS registration_week,
  COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY DATEPART(WEEK, registration_date);
-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
SELECT c.order_id,runner_id,AVG(DATEDIFF(MINUTE, order_time,pickup_time)) AS MinuteDiff
FROM runner_orders  r INNER JOIN customer_orders c on c.order_id = r.order_id
GROUP BY runner_id,c.order_id;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
SELECT c.order_id, number_of_pizza,r.duration_min
FROM runner_orders r 
INNER JOIN (
    SELECT order_id, COUNT(order_id) as number_of_pizza
    FROM customer_orders
    GROUP BY order_id
) c ON r.order_id = c.order_id;
-- What was the average distance travelled for each customer?
SELECT c.customer_id
     ,CAST(AVG(distance_km)AS DECIMAL(10, 2))
FROM runner_orders r INNER JOIN customer_orders c on c.order_id = r.order_id
GROUP BY c.customer_id;
-- What was the difference between the longest and shortest delivery times for all orders?
SELECT MAX(duration_min) - MIN(duration_min)
FROM runner_orders;
-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
SELECT runner_id
     ,AVG(distance_km/duration_min)
FROM runner_orders
GROUP BY runner_id;
-- What is the successful delivery percentage for each runner?
SELECT runner_id
     , CAST(ROUND(SUM(CASE
         WHEN cancellation IS NULL THEN 1
         ELSE 0
       END) * 100.0 / COUNT(*), 2) AS DECIMAL(10, 2))
FROM runner_orders
GROUP BY runner_id;
-------------------------------------------------------------------
-- C. Ingredient Optimisation
-- What are the standard ingredients for each pizza?
SELECT pr.pizza_id, STRING_AGG(topping_name, ', ') AS standard_ingredients
FROM pizza_recipes pr 
CROSS APPLY STRING_SPLIT(pr.toppings, ',') AS s
JOIN pizza_toppings t on TRIM(s.value) = t.topping_id
GROUP BY pr.pizza_id;
-- What was the most commonly added extra?
SELECT TOP 1 extras,topping_name,COUNT(extras)FROM customer_orders
JOIN pizza_toppings t on extras = t.topping_id
GROUP BY extras,topping_name
order by COUNT(extras) desc;
-- What was the most common exclusion?
SELECT TOP 1 exclusions,topping_name,COUNT(exclusions)FROM customer_orders
JOIN pizza_toppings t on exclusions = t.topping_id
GROUP BY exclusions,topping_name
order by COUNT(exclusions) desc;
-- Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

    SELECT co.order_id,
	    CASE
        WHEN extras IS NULL AND exclusions IS NULL THEN NULL
        WHEN extras IS NULL THEN pizza_name+' - Extra ' + x.topping_name
        WHEN exclusions IS NULL THEN pizza_name+' - Exclude ' + e.topping_name
        ELSE CONCAT(pizza_name,' - Extra ',e.topping_name,  ' , Exclude ', x.topping_name)
    END AS order_item 
    FROM customer_orders co
    LEFT JOIN pizza_toppings e ON co.extras = e.topping_id
    LEFT JOIN pizza_toppings x ON co.exclusions = x.topping_id
	LEFT JOIN pizza_names p ON co.pizza_id = p.pizza_id

-----------------------------------------------------------------------
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - 
-- how much money has Pizza Runner made so far if there are no delivery fees?
SELECT 
    SUM(
        CASE 
            WHEN pizza_name = 'Meat Lovers' THEN 12
            WHEN pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END
    ) as total
FROM customer_orders c
JOIN pizza_names n on c.pizza_id = n.pizza_id;

-- What if there was an additional $1 charge for any pizza extras?
   -- Add cheese is $1 extra
  SELECT 
    SUM(
        CASE 
            WHEN pizza_name = 'Meat Lovers' THEN 12
            WHEN pizza_name = 'Vegetarian' THEN 10
            ELSE 0
        END
    ) +
    SUM(
        CASE 
            WHEN e.topping_name = 'Cheese' THEN 1
            ELSE 0
        END
    ) as total
FROM customer_orders c
JOIN pizza_names n on c.pizza_id = n.pizza_id
LEFT JOIN pizza_toppings e ON c.extras = e.topping_id;






