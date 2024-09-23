# Pizza Runner

##**Problem Task——————————————————————**

Danny, inspired by a post about the future of pizza and 80s retro styling on Instagram, launched Pizza Runner to revolutionize pizza delivery. He recruited runners to deliver pizza from his house and developed a mobile app to accept customer orders, aiming to expand his Pizza Empire and secure seed funding.

My task involves conducting a thorough analysis of pizza sales metrics, runner and customer experiences. Additionally, it entails exploring ingredient optimization, pricing strategies, and customer ratings. 

## **Overview————————————————————————**

Topics Covered:

- Common table expressions
- Group by aggregates
- Table joins
- String transformations
- Dealing with null values
- Regular expressions

Key Datasets:

- runner
- customer_orders
- runner_orders
- pizza_names
- pizza_recipes
- pizza_toppings

![Pizza Runner.png](Pizza_Runner.png)

### **A. Pizza Metrics**

1. How many pizzas were ordered?

```sql
SELECT COUNT(*) AS total_ordered_pizza FROM customer_orders;
```

| total_ordered_pizza |
| --- |
| 16 |
1. How many unique customer orders were made?

```sql
SELECT COUNT(*) AS unique_order
FROM (
  SELECT DISTINCT order_id
                , customer_id
                , pizza_id
                , exclusions
                , extras
                , order_time
  FROM customer_orders
) AS unique_order
```

| unique_order |
| --- |
| 15  |
1. How many successful orders were delivered by each runner?

```sql
SELECT runner_id
     , COUNT(*) AS successful_orders
FROM runner_orders
WHERE cancellation IS NULL
GROUP BY runner_id;
```

| runner_id | successful_orders |
| --- | --- |
| 1 | 4 |
| 2 | 3 |
| 3 | 1 |
1. How many of each type of pizza was delivered?

```sql
SELECT pizza_id, COUNT(*) AS number_of_orders
FROM customer_orders c
  JOIN runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
GROUP BY pizza_id;
```

| pizza_id | number_of_orders |
| --- | --- |
| 1 | 10 |
| 2 | 3 |
1. How many Vegetarian and Meatlovers were ordered by each customer?

```sql
SELECT customer_id,pizza_name
     , COUNT(*) AS number_of_orders
FROM customer_orders c
  JOIN pizza_names p ON c.pizza_id = p.pizza_id
GROUP BY pizza_name,customer_id;
```

| customer_id | pizza_name | number_of_orders |
| --- | --- | --- |
| 101 | Meatlovers | 2 |
| 101 | Vegetarian | 1 |
| 102 | Meatlovers | 2 |
| 102 | Vegetarian | 1 |
| 103 | Meatlovers | 4 |
| 103 | Vegetarian | 1 |
| 104 | Meatlovers | 4 |
| 105 | Vegetarian | 1 |
1. What was the maximum number of pizzas delivered in a single order?

```sql
SELECT MAX(number_of_pizza) AS max_pizza_number
FROM (

  SELECT c.order_id
       , COUNT(*) number_of_pizza
  FROM customer_orders c
    JOIN runner_orders r ON c.order_id = r.order_id
  WHERE cancellation IS NULL
  GROUP BY c.order_id
) AS pizza_count;
```

|  max_pizza_number |
| --- |
| 3 |

1. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

```sql
SELECT c.customer_id
     , COUNT(*) AS number_of_pizza
FROM customer_orders c
  JOIN runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
  AND (extras IS NOT NULL
  OR exclusions IS NOT NULL)
GROUP BY c.customer_id;

```

| customer_id | number_of_pizza |
| --- | --- |
| 103 | 3 |
| 104 | 3 |
| 105 | 1 |
1. How many pizzas were delivered that had both exclusions and extras?

```sql
SELECT c.customer_id
     , COUNT(*) AS number_of_pizza
FROM customer_orders c
  JOIN runner_orders r ON c.order_id = r.order_id
WHERE cancellation IS NULL
  AND (extras IS NOT NULL
  AND exclusions IS NOT NULL)
GROUP BY c.customer_id;
```

| customer_id | number_of_pizza |
| --- | --- |
| 104 | 2 |
1. What was the total volume of pizzas ordered for each hour of the day?

```sql
SELECT DATEPART(HOUR, pickup_time) AS hour
	 , COUNT(order_id) AS total_volume
FROM runner_orders
WHERE  pickup_time IS NOT NULL
GROUP BY DATEPART(HOUR, pickup_time);
```

| hour | total_volume |
| --- | --- |
| 0 | 2 |
| 13 | 1 |
| 18 | 2 |
| 19 | 1 |
| 21 | 2 |
1. What was the volume of orders for each day of the week?

```sql
SELECT DATENAME(WEEKDAY, order_time) AS day_name
     , COUNT(order_id)
FROM customer_orders
GROUP BY DATENAME(WEEKDAY, order_time);

```

| day_name | total_volume |
| --- | --- |
| Friday | 2 |
| Saturday | 6 |
| Thursday | 3 |
| Wednesday | 5 |

### **B. Runner and Customer Experience**

1. How many runners signed up for each 1 week period? (i.e. week starts `2021-01-01`)

```sql
SELECT DATEPART(WEEK, registration_date) AS registration_week
     , COUNT(runner_id) AS runner_signup
FROM runners
GROUP BY DATEPART(WEEK, registration_date);
```

| registration_week | runner_signup |
| --- | --- |
| 1 | 1 |
| 2 | 2 |
| 3 | 1 |
1. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

```sql
SELECT c.order_id
     , runner_id
     , AVG(DATEDIFF(MINUTE, order_time, pickup_time)) AS MinuteDiff
FROM runner_orders r
  INNER JOIN customer_orders c ON c.order_id = r.order_id
 WHERE cancellation IS NULL
GROUP BY runner_id
       , c.order_id;
```

| order_id | runner_id | MinuteDiff |
| --- | --- | --- |
| 1 | 1 | 10 |
| 2 | 1 | 10 |
| 3 | 1 | 21 |
| 4 | 2 | 30 |
| 5 | 3 | 10 |
| 7 | 2 | 10 |
| 8 | 2 | 21 |
| 10 | 1 | 16 |
1. Is there any relationship between the number of pizzas and how long the order takes to prepare?

```sql
SELECT c.order_id
     , number_of_pizza
     , r.duration_min
FROM runner_orders r
  INNER JOIN (
    SELECT order_id
         , COUNT(order_id) AS number_of_pizza
    FROM customer_orders
    GROUP BY order_id
  ) c ON r.order_id = c.order_id
  WHERE pickup_time IS NOT NULL;

```

| order_id | number_of_pizza | duration_min |
| --- | --- | --- |
| 1 | 1 | 32 |
| 2 | 1 | 27 |
| 3 | 2 | 20 |
| 4 | 3 | 40 |
| 5 | 1 | 15 |
| 7 | 1 | 25 |
| 8 | 1 | 15 |
| 10 | 3 | 10 |
1. What was the average distance travelled for each customer?

```sql
SELECT c.customer_id
     , CAST(AVG(distance_km) AS DECIMAL(10, 2)) AS avg_distance
FROM runner_orders r
  INNER JOIN customer_orders c ON c.order_id = r.order_id
GROUP BY c.customer_id;
```

| customer_id | avg_distance |
| --- | --- |
| 101 | 20 |
| 102 | 16.73 |
| 103 | 23.4 |
| 104 | 10 |
| 105 | 25 |
1. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration_min) - MIN(duration_min) AS difference
FROM runner_orders;
```

| difference |
| --- |
| 30 |
1. What was the average speed for each runner for each delivery and do you notice any trend for these values?

```sql
SELECT runner_id
     , CAST(AVG(distance_km / duration_min) AS DECIMAL(10, 2)) AS avg_speed
FROM runner_orders
GROUP BY runner_id;
```

| runner_id | avg_speed |
| --- | --- |
| 1 | 0.76 |
| 2 | 1.05 |
| 3 | 0.67 |
1. What is the successful delivery percentage for each runner?

```sql
SELECT runner_id
     , CAST(ROUND(SUM(CASE
         WHEN cancellation IS NULL THEN 1
         ELSE 0
       END) * 100.0 / COUNT(*), 2) AS DECIMAL(10, 2)) AS delivery_percentage
FROM runner_orders
GROUP BY runner_id;
```

| runner_id | delivery_percentage |
| --- | --- |
| 1 | 100 |
| 2 | 75 |
| 3 | 50 |

### **C. Ingredient Optimisation**

1. What are the standard ingredients for each pizza?

```sql
SELECT pr.pizza_id
     , STRING_AGG(topping_name, ', ') AS standard_ingredients
FROM pizza_recipes pr
  CROSS APPLY STRING_SPLIT(pr.toppings, ',') AS s
  JOIN pizza_toppings t ON TRIM(s.value) = t.topping_id
GROUP BY pr.pizza_id;
```

| pizza_id | standard_ingredients |
| --- | --- |
| 1 | Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2 | Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
1. What was the most commonly added extra?

```sql
SELECT TOP 1 topping_name
           , COUNT(extras) AS times
FROM customer_orders
  JOIN pizza_toppings t ON extras = t.topping_id
GROUP BY extras
       , topping_name
ORDER BY COUNT(extras) DESC;
```

| topping_name | times |
| --- | --- |
| Bacon | 4 |
1. What was the most common exclusion?

```sql
SELECT TOP 1 topping_name
           , COUNT(exclusions) AS times
FROM customer_orders
  JOIN pizza_toppings t ON exclusions = t.topping_id
GROUP BY exclusions
       , topping_name
ORDER BY COUNT(exclusions) DESC;
```

| topping_name | times |
| --- | --- |
| Cheese | 4 |
1. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
    - `Meat Lovers`
    - `Meat Lovers - Exclude Beef`
    - `Meat Lovers - Extra Bacon`
    - `Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers`
    
    ```sql
    SELECT co.order_id
         , CASE
             WHEN (extras IS NULL AND
               exclusions IS NULL) THEN pizza_name
             WHEN extras IS NULL THEN pizza_name + ' - Extra ' + x.topping_name
             WHEN exclusions IS NULL THEN pizza_name + ' - Exclude ' + e.topping_name
             ELSE CONCAT(pizza_name, ' - Extra ', e.topping_name, ' , Exclude ', x.topping_name)
           END AS order_item
    FROM customer_orders co
      LEFT JOIN pizza_toppings e ON co.extras = e.topping_id
      LEFT JOIN pizza_toppings x ON co.exclusions = x.topping_id
      LEFT JOIN pizza_names p ON co.pizza_id = p.pizza_id
    ```
    

| order_id | order_item |
| --- | --- |
| 1 | Meatlovers |
| 2 | Meatlovers |
| 3 | Meatlovers |
| 3 | Vegetarian |
| 4 | Meatlovers - Extra Cheese |
| 4 | Meatlovers - Extra Cheese |
| 4 | Vegetarian - Extra Cheese |
| 5 | Meatlovers - Exclude Bacon |
| 6 | Vegetarian |
| 7 | Vegetarian - Exclude Bacon |
| 8 | Meatlovers |
| 9 | Meatlovers - Extra Bacon , Exclude Cheese |
| 9 | Meatlovers - Exclude Chicken |
| 10 | Meatlovers |
| 10 | Meatlovers - Extra Bacon , Exclude BBQ Sauce |
| 10 | Meatlovers - Extra Cheese , Exclude Mushrooms |

### **D. Pricing and Ratings**

1. If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?

```sql
SELECT SUM(
  CASE
    WHEN pizza_name = 'Meat Lovers' THEN 12
    WHEN pizza_name = 'Vegetarian' THEN 10
    ELSE 0
  END
  ) AS total
FROM customer_orders c
  JOIN pizza_names n ON c.pizza_id = n.pizza_id;
```

| total |
| --- |
| 40 |
1. What if there was an additional $1 charge for any pizza extras?

```sql
  SELECT SUM(
  CASE
    WHEN pizza_name = 'Meat Lovers' THEN 12
    WHEN pizza_name = 'Vegetarian' THEN 10
    ELSE 0
  END
  ) +
  SUM(
  CASE
    WHEN extras IS NOT NULL THEN 1
    ELSE 0
  END
  ) AS total_extra
FROM customer_orders c
  JOIN pizza_names n ON c.pizza_id = n.pizza_id
  LEFT JOIN pizza_toppings e ON c.extras = e.topping_id;
```

| total_extra |
| --- |
| 46 |