# Pizza Runner

## **Problem Task——————————————————————**

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

![Pizza Runner.png](../images/Pizza%20Runner.png)

### **A. Pizza Metrics**

1. How many pizzas were ordered?

```sql
SELECT COUNT(*) AS total_ordered_pizza FROM customer_orders;
```

| total_ordered_pizza |
| --- |
| 16 |

2. How many unique customer orders were made?

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

3. How many successful orders were delivered by each runner?

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

4. How many of each type of pizza was delivered?

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

5. How many Vegetarian and Meatlovers were ordered by each customer?

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

6. What was the maximum number of pizzas delivered in a single order?

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

7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

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

8. How many pizzas were delivered that had both exclusions and extras?

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

9. What was the total volume of pizzas ordered for each hour of the day?

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

10. What was the volume of orders for each day of the week?

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

2. What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

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

3. Is there any relationship between the number of pizzas and how long the order takes to prepare?

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

4. What was the average distance travelled for each customer?

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

5. What was the difference between the longest and shortest delivery times for all orders?

```sql
SELECT MAX(duration_min) - MIN(duration_min) AS difference
FROM runner_orders;
```

| difference |
| --- |
| 30 |

6. What was the average speed for each runner for each delivery and do you notice any trend for these values?

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

7. What is the successful delivery percentage for each runner?

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
2. What was the most commonly added extra?

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

3. What was the most common exclusion?

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

4. Generate an order item for each record in the `customers_orders` table in the format of one of the following:
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

5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

```sql
WITH order_item AS
(
  SELECT pr.pizza_id
       , pizza_name
       , STRING_AGG(topping_name, ', ') AS standard_ingredients
  FROM pizza_recipes pr
    JOIN pizza_names n ON n.pizza_id = pr.pizza_id
    CROSS APPLY STRING_SPLIT(pr.toppings, ',') AS s
    JOIN pizza_toppings t ON TRIM(s.value) = t.topping_id
  GROUP BY pr.pizza_id
         , pizza_name
)

SELECT order_id
     , customer_id
     , CASE

         WHEN CHARINDEX(t.topping_name, standard_ingredients) > 0 AND
           CHARINDEX(e.topping_name, standard_ingredients) > 0 THEN REPLACE(pizza_name + ': ' +
           REPLACE(standard_ingredients, e.topping_name, '2x' + e.topping_name),
           t.topping_name + ', ', ''
           )

         WHEN CHARINDEX(t.topping_name, standard_ingredients) > 0 THEN pizza_name + ': ' + REPLACE(standard_ingredients, t.topping_name + ', ', '')

         WHEN CHARINDEX(e.topping_name, standard_ingredients) > 0 THEN pizza_name + ': ' + REPLACE(standard_ingredients, e.topping_name, '2x' + e.topping_name)

         WHEN CHARINDEX(e.topping_name, standard_ingredients) = 0 THEN pizza_name + ': ' + CONCAT(standard_ingredients, ', ', e.topping_name)
         ELSE pizza_name + ': ' + standard_ingredients
       END AS order_item
FROM order_item o
  JOIN customer_orders c ON o.pizza_id = c.pizza_id
  LEFT JOIN pizza_toppings t ON c.exclusions = t.topping_id
  LEFT JOIN pizza_toppings e ON c.extras = e.topping_id;
```

| order_id | customer_id | order_item |
| --- | --- | --- |
| 1 | 101 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 2 | 101 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3 | 102 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 3 | 102 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 4 | 103 | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 4 | 103 | Meatlovers: Bacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 4 | 103 | Vegetarian: Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 5 | 104 | Meatlovers: 2xBacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 6 | 101 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce |
| 7 | 105 | Vegetarian: Cheese, Mushrooms, Onions, Peppers, Tomatoes, Tomato Sauce, Bacon |
| 8 | 102 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 9 | 103 | Meatlovers: 2xBacon, BBQ Sauce, Beef, Chicken, Mushrooms, Pepperoni, Salami |
| 9 | 103 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, 2xChicken, Mushrooms, Pepperoni, Salami |
| 10 | 104 | Meatlovers: Bacon, BBQ Sauce, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 10 | 104 | Meatlovers: 2xBacon, Beef, Cheese, Chicken, Mushrooms, Pepperoni, Salami |
| 10 | 104 | Meatlovers: Bacon, BBQ Sauce, Beef, 2xCheese, Chicken, Pepperoni, Salami |

6.  What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?

```sql
WITH order_item AS
(
  SELECT ROW_NUMBER() OVER (ORDER BY order_id) AS id
       , order_id
       , c.pizza_id
       , exclusions
       , extras
       , CASE
           WHEN CHARINDEX(exclusions, toppings) > 0 AND
             CHARINDEX(extras, toppings) > 0 THEN REPLACE(CONCAT(toppings, ', ', extras), exclusions + ', ', '')
           WHEN CHARINDEX(exclusions, toppings) > 0 THEN REPLACE(toppings, exclusions + ', ', '')
           WHEN CHARINDEX(extras, toppings) > 0 THEN CONCAT(toppings, ', ', extras)
           ELSE toppings
         END AS cleaned_description
  FROM customer_orders c
    JOIN pizza_recipes pr ON c.pizza_id = pr.pizza_id
)

SELECT topping_name
     , COUNT(TRIM(s.value)) AS count
FROM order_item
  CROSS APPLY STRING_SPLIT(cleaned_description, ',') AS s
  JOIN pizza_toppings t ON TRIM(s.value) = t.topping_id
GROUP BY topping_name
ORDER BY COUNT(TRIM(s.value)) DESC;
```

| topping_name | count |
| --- | --- |
| Bacon | 16 |
| Mushrooms | 15 |
| Cheese | 13 |
| Chicken | 13 |
| Pepperoni | 12 |
| Salami | 12 |
| Beef | 12 |
| BBQ Sauce | 11 |
| Peppers | 4 |
| Onions | 4 |
| Tomato Sauce | 4 |
| Tomatoes | 4 |
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

2. What if there was an additional $1 charge for any pizza extras?

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

3. The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, how would you design an additional table for this new dataset - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.

```sql
CREATE TABLE runner_rating (
      order_id INT
    , customer_id INT
    , runner_id INT
    , rating INT
);

INSERT INTO runner_rating (order_id, customer_id, runner_id, rating)
SELECT order_id
     , customer_id
     , runner_id
     , ABS(CHECKSUM(NEWID()) % 5) + 1 AS rating
FROM (
  SELECT DISTINCT c.order_id
                , c.customer_id
                , r.runner_id
  FROM customer_orders c
    JOIN runner_orders r ON c.order_id = r.order_id
  WHERE cancellation IS NULL
) AS new_data;
```

| order_id | customer_id | runner_id | rating |
| --- | --- | --- | --- |
| 1 | 101 | 1 | 3 |
| 2 | 101 | 1 | 5 |
| 3 | 102 | 1 | 3 |
| 4 | 103 | 2 | 1 |
| 5 | 104 | 3 | 4 |
| 7 | 105 | 2 | 2 |
| 8 | 102 | 2 | 2 |
| 10 | 104 | 1 | 2 |

4. Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
    - `customer_id`
    - `order_id`
    - `runner_id`
    - `rating`
    - `order_time`
    - `pickup_time`
    - Time between order and pickup
    - Delivery duration
    - Average speed
    - Total number of pizzas

```sql
SELECT c.customer_id
     , r.order_id
     , rating
     , r.runner_id
     , order_time
     , pickup_time
     , (DATEDIFF(MINUTE, order_time, pickup_time)) AS time_differ_min
     , duration_min
     , CAST(AVG(distance_km / duration_min) AS DECIMAL(10, 2)) AS avg_speed
     , COUNT(pizza_id) AS total_pizza
FROM customer_orders c
  JOIN runner_orders r ON c.order_id = r.order_id
  JOIN runner_rating t ON r.order_id = t.order_id
GROUP BY c.customer_id
       , r.order_id
       , rating
       , r.runner_id
       , order_time
       , pickup_time
       , duration_min;
```

| customer_id | order_id | rating | runner_id | order_time | pickup_time | time_differ_min | duration_min | avg_speed | total_pizza |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 101 | 1 | 3 | 1 | 2020-01-01 18:05:02.000 | 2020-01-01 18:15:34.0000000 | 10 | 32 | 0.63 | 1 |
| 101 | 2 | 5 | 1 | 2020-01-01 19:00:52.000 | 2020-01-01 19:10:54.0000000 | 10 | 27 | 0.74 | 1 |
| 102 | 3 | 3 | 1 | 2020-01-02 23:51:23.000 | 2020-01-03 00:12:37.0000000 | 21 | 20 | 0.67 | 2 |
| 102 | 8 | 2 | 2 | 2020-01-09 23:54:33.000 | 2020-01-10 00:15:02.0000000 | 21 | 15 | 1.56 | 1 |
| 103 | 4 | 1 | 2 | 2020-01-04 13:23:46.000 | 2020-01-04 13:53:03.0000000 | 30 | 40 | 0.59 | 3 |
| 104 | 5 | 4 | 3 | 2020-01-08 21:00:29.000 | 2020-01-08 21:10:57.0000000 | 10 | 15 | 0.67 | 1 |
| 104 | 10 | 2 | 1 | 2020-01-11 18:34:49.000 | 2020-01-11 18:50:20.0000000 | 16 | 10 | 1 | 3 |
| 105 | 7 | 2 | 2 | 2020-01-08 21:20:29.000 | 2020-01-08 21:30:45.0000000 | 10 | 25 | 1 | 1 |

5. If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled - how much money does Pizza Runner have left over after these deliveries?

```sql
SELECT DISTINCT r.order_id
              , CASE
                  WHEN pizza_name = 'Meatlovers' THEN 12 - distance_km * 0.30
                  WHEN pizza_name = 'Vegetarian' THEN 10 - distance_km * 0.30
                END AS left_over
FROM runner_orders r
  JOIN customer_orders c ON c.order_id = r.order_id
  JOIN pizza_names p ON p.pizza_id = c.pizza_id
WHERE cancellation IS NULL;
```

| order_id | left_over |
| --- | --- |
| 1 | 6 |
| 2 | 6 |
| 3 | 5.98 |
| 3 | 7.98 |
| 4 | 2.98 |
| 4 | 4.98 |
| 5 | 9 |
| 7 | 2.5 |
| 8 | 4.98 |
| 10 | 9 |
