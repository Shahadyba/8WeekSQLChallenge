# Data Cleaning Process

There are two tables, `customer_orders` and `runner_orders`, that require cleaning. I will investigate each table and implement the necessary changes where needed. 

### Table `customer_orders` ————————————————————————

1. The first issue is a data entry problem, as previously noted:
    
    > Note that customers can order multiple pizzas in a single order with varying `exclusions` and `extras` values even if the pizza is the same type!
    > 
    
    This can create a confusion during analysis, potentially treating multiple pizzas as a single item with combined exclusions and extras. To solve it I duplicate the order details for each additional pizza, replicating their exclusions and extras. Then, update the orginal rows by removing the details of the extra pizzas.
    

```sql
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
```

For future considerations, I recommend implementing a different data entry process where each pizza is represented by its own row, even if multiple pizzas share the same pizza_id and order_id.

2. The second issue is inconsistency within the dataset. Various representations of `NULL` exist, including 'null', ' ', and 'NaN'. Standardizing these to a single value, `NULL` is necessary for consistency.

```sql
UPDATE customer_orders
SET extras = NULL
WHERE extras IN ('null', ' ','NaN');

UPDATE customer_orders
SET exclusions = NULL
WHERE exclusions IN ('null', ' ','NaN');
```

### Table `runner_orders` —————————————————————————

After invastiget the data I performed the following tasks 

1. Renamed the 'distance' and 'duration' columns to include their respective units then Removed the units from the values so I can make calulaction where needed.

```sql
EXEC sp_rename 'runner_orders.distance', 'distance_km', 'COLUMN';
EXEC sp_rename 'runner_orders.duration', 'duration_min', 'COLUMN';

UPDATE runner_orders
SET distance_km = REPLACE(distance_km, 'km', '');

UPDATE runner_orders  
SET duration_min = SUBSTRING(duration_min, 1,2)
WHERE duration_min LIKE '%m%';
```

2. Verified the data types and made necessary corrections.

```sql
SELECT 
    c.name AS column_name,
    t.name AS data_type
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('runner_orders');

ALTER TABLE runner_orders
ALTER COLUMN pickup_time datetime2;

ALTER TABLE runner_orders
ALTER COLUMN distance_km DECIMAL(10,2);

ALTER TABLE runner_orders
ALTER COLUMN duration_min int;
```

| column_name | data_type |
| --- | --- |
| order_id | int |
| runner_id | int |
| pickup_time | varchar |
| distance_km | varchar |
| duration_min | varchar |
| cancellation | varchar |

| column_name | data_type |
| --- | --- |
| order_id | int |
| runner_id | int |
| pickup_time | datetime2 |
| distance_km | decimal |
| duration_min | int |
| cancellation | varchar |
1. Standardized the inconsistency in representing NULL values.

```sql
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
```

---
