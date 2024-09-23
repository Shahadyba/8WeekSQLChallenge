# Danny's Diner

## Problem Task——————————————————————

The case study seeks to utilize customer data to unveil visiting patterns, expenditure habits, and preferred menu items for enhanced customer engagement. These insights will inform decisions on expanding the loyalty program. Basic datasets are required for convenient data inspection. Utilizing sample data from sales, menu, and members datasets

## **Overview————————————————————————**

Topics Covered:

- Common Table Expressions
- Group By Aggregates
- Window Functions for ranking
- Table Joins

Key Datasets:

- sales 
- menu
- members

![image](../images/Danny%27s%20Diner.png)


## **Case Study Questions———————————————————**

#### 1. What is the total amount each customer spent at the restaurant?

```sql
SELECT
    s.customer_id,
    SUM(m.price) AS total_amount
FROM
    sales s
LEFT JOIN
    menu m ON s.product_id = m.product_id
GROUP BY
    s.customer_id;
```

| customer_id | total_amount |
| --- | --- |
| A | 76 |
| B | 74 |
| C | 36 |

---

#### 2. How many days has each customer visited the restaurant?

```sql
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS number_of_days
FROM
    sales
GROUP BY
    customer_id;
```

| customer_id | number_of_days |
| --- | --- |
| A | 4 |
| B | 6 |
| C | 2 |
#### 3. What was the first item from the menu purchased by each customer?

```sql
WITH First_item AS
(
  SELECT s.customer_id
       , s.order_date
       , ROW_NUMBER() OVER (
         PARTITION BY s.customer_id
         ORDER BY
         s.order_date
         ) AS ranked
       , m.product_name
  FROM sales s
    JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id
     , product_name
FROM First_item
WHERE ranked = 1;
```

| customer_id | product_name |
| --- | --- |
| A | sushi |
| B | curry |
| C | ramen |

---

#### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

```sql
WITH most_purchased AS
(
  SELECT m.product_name
       , s.product_id
       , COUNT(s.product_id) AS times
  FROM sales s
    JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.product_id
         , m.product_name
)

SELECT product_name
     , times
FROM most_purchased
WHERE times = (SELECT MAX(times) FROM most_purchased); 
```

| product_name | times |
| --- | --- |
| ramen | 8 |

---

#### 5. Which item was the most popular for each customer?

```sql
WITH most_popular AS
(
  SELECT s.customer_id
       , m.product_name
       , COUNT(s.product_id) AS times
       , ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranked
  FROM sales s
    JOIN menu m ON s.product_id = m.product_id
  GROUP BY s.customer_id
         , m.product_name
)

SELECT customer_id
     , product_name
     , times
FROM most_popular
WHERE ranked = 1;
```

| customer_id | product_name | times |
| --- | --- | --- |
| A | ramen | 3 |
| B | sushi | 2 |
| C | ramen | 3 |

---

#### 6. Which item was purchased first by the customer before they became a member?

```sql
WITH purcheased_before_membership AS
(
  SELECT s.customer_id
       , m.join_date
       , s.order_date
       , s.product_id
       , n.product_name
       , ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS ranked

  FROM menu n
    JOIN sales s ON n.product_id = s.product_id
    JOIN members m ON s.customer_id = m.customer_id
  WHERE m.join_date > s.order_date
)
SELECT customer_id
     , join_date
     , order_date
     , product_name
FROM purcheased_before_membership
WHERE ranked = 1;
```

| customer_id | join_date | order_date | product_name |
| --- | --- | --- | --- |
| A | 2021-01-07 | 2021-01-01 | sushi |
| A | 2021-01-07 | 2021-01-01 | curry |
| B | 2021-01-09 | 2021-01-04 | sushi |

---

#### 7. Which item was purchased first by the customer after they became a member?

```sql
WITH purcheased_after_membership AS
(
  SELECT s.customer_id
       , m.join_date
       , s.order_date
       , s.product_id
       , n.product_name
       , RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date) AS ranked

  FROM menu n
    JOIN sales s ON n.product_id = s.product_id
    JOIN members m ON s.customer_id = m.customer_id
  WHERE m.join_date < s.order_date
)
SELECT customer_id
     , join_date
     , order_date
     , product_name
FROM purcheased_after_membership
WHERE ranked = 1;
```

| customer_id | join_date | order_date | product_name |
| --- | --- | --- | --- |
| A | 2021-01-07 | 2021-01-10 | ramen |
| B | 2021-01-09 | 2021-01-11 | sushi |

---

#### 8.  What is the total items and amount spent for each member before they became a member?

```sql
WITH total_item AS
(
  SELECT s.customer_id
       , m.join_date
       , s.order_date
       , s.product_id
       , n.product_name
       , n.price
  FROM menu n
    JOIN sales s ON n.product_id = s.product_id
    JOIN members m ON s.customer_id = m.customer_id
  WHERE m.join_date > s.order_date
)
SELECT customer_id
     , SUM(price) AS total_amount
     , COUNT(product_id) AS total_items

FROM total_item
GROUP BY customer_id;
```

---

| customer_id | total_amount | total_item |
| --- | --- | --- |
| A | 25 | 2 |
| B | 40 | 3 |
#### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

```sql
WITH points AS
(
  SELECT s.customer_id
       , m.price AS total_amount
       , product_name
       , CASE product_name
           WHEN 'sushi' THEN price * 20
           ELSE price * 10
         END AS point
  FROM sales s
    LEFT JOIN menu m ON s.product_id = m.product_id
)
SELECT customer_id
     , SUM(point) AS point
FROM points
GROUP BY customer_id;
```

| customer_id | point |
| --- | --- |
| A | 860 |
| B | 940 |
| C | 360 |

---

#### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have

```sql
WITH points AS
(
  SELECT s.customer_id
       , m.join_date
       , s.order_date
       , s.product_id
       , n.product_name
       , n.price,
		CASE 
            WHEN n.product_name = 'sushi' OR DAY(s.order_date) >= DAY(m.join_date) THEN 20 * n.price
            WHEN DAY(s.order_date) >= DAY(m.join_date) THEN 20 * n.price
            ELSE 10 * n.price 
        END AS point
  FROM menu n
    JOIN sales s ON n.product_id = s.product_id
    JOIN members m ON s.customer_id = m.customer_id
)
SELECT customer_id, SUM(point) total 
FROM points
GROUP BY customer_id;
```

| customer_id | point |
| --- | --- |
| A | 1370 |
| B | 1060 |

## **Bonus Question**——————————————————————

The following questions are related creating basic data tables that can be can use to quickly derive insights without needing to join the underlying tables using SQL.

#### 1. Join All The Things

Recreate the following table output using the available data:

![image.png](../images/image%202.png)

```sql
SELECT s.customer_id
     , s.order_date
     , s.product_id
     , n.product_name
     , n.price
     , CASE
         WHEN m.join_date <= s.order_date THEN 'y'
         ELSE 'n'
       END AS members
FROM menu n
  JOIN sales s ON n.product_id = s.product_id
  LEFT JOIN members m ON s.customer_id = m.customer_id;
```

#### 2. Rank All The Things

Recreate the following table output using the available data and include information about the ranking of member’s products only:

![image.png](images/image%201.png)

```sql
WITH ranking AS
(
  SELECT s.customer_id
       , s.order_date
       , s.product_id
       , n.product_name
       , n.price
       , CASE
           WHEN m.join_date <= s.order_date THEN 'y'
           ELSE 'n'
         END AS members
  FROM menu n
    JOIN sales s ON n.product_id = s.product_id
    LEFT JOIN members m ON s.customer_id = m.customer_id
)
SELECT customer_id
     , order_date
     , product_id
     , product_name
     , price
     , members
     , CASE
         WHEN members = 'y' THEN RANK() OVER (PARTITION BY customer_id, members ORDER BY order_date)
         ELSE NULL
       END AS ranked
FROM ranking;
```

## Notes——————————————————————

#### Window function for ranking 

the `ROW_NUMBER()` function is used to assign a sequential integer to each row within the partition based on the order spsefied. On the other hand, The `RANK()` function would assign the same rank to rows with the same values 

Example #1: [Which item was purchased first by the customer before they became a member?](https://github.com/Shahadyba/8WeekSQLChallenge/edit/main/CaseStudy%231/Case%20Study%231%201ee492825acc48319ccd0595286e05e7.md#6-which-item-was-purchased-first-by-the-customer-after-they-became-a-member)

Here the `ROW_NUMBER()` function assigns a unique number to each row based on the specified ordering, allowing us to filter for the row with the most recent purchase before membership by selecting rows where the ranked value is equal to 1.

Example #2: [Which item was purchased first by the customer after they became a member?](https://github.com/Shahadyba/8WeekSQLChallenge/edit/main/CaseStudy%231/Case%20Study%231%201ee492825acc48319ccd0595286e05e7.md#6-which-item-was-purchased-first-by-the-customer-after-they-became-a-member)

Here the `RANK()` function used to assign a ranking to each row based on the order date in descending order. This helps identify the chronological order of purchases made by each customer before their membership date, by selecting rows where the ranked value equals 1.

