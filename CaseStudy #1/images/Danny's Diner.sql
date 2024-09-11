-- What is the total amount each customer spent at the restaurant?
SELECT
    s.customer_id,
    SUM(m.price) AS total_amount
FROM
    sales s
LEFT JOIN
    menu m ON s.product_id = m.product_id
GROUP BY
    s.customer_id;
	

-- How many days has each customer visited the restaurant?
SELECT
    customer_id,
    COUNT(DISTINCT order_date) AS number_of_days
FROM
    sales
GROUP BY
    customer_id;

-- What was the first item from the menu purchased by each customer?
WITH First_item AS (
    SELECT
        s.customer_id,
        s.order_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.order_date) AS ranked,
        m.product_name
    FROM
        sales s
    JOIN
        menu m ON s.product_id = m.product_id
)

SELECT
    customer_id,
    product_name
FROM
    First_item
WHERE
    ranked = 1;

-- What is the most purchased item on the menu and how many times was it purchased by all customers?
WITH most_purchased AS (
    SELECT
        m.product_name,
        s.product_id,
        COUNT(s.product_id) AS times
    FROM
        sales s
    JOIN
        menu m ON s.product_id = m.product_id
    GROUP BY
        s.product_id, m.product_name
)

SELECT
    product_name,
    times
FROM
    most_purchased
WHERE
    times = (SELECT MAX(times) FROM most_purchased); 


-- Which item was the most popular for each customer?
WITH most_popular AS (
    SELECT
        s.customer_id,
        m.product_name,
        COUNT(s.product_id) AS times,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) AS ranked
    FROM
        sales s
    JOIN
        menu m ON s.product_id = m.product_id
    GROUP BY
        s.customer_id, m.product_name
)

SELECT
    customer_id,
    product_name,
    times
FROM
    most_popular
WHERE
    ranked = 1;

-- Which item was purchased first by the customer after they became a member?
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

-- Which item was purchased just before the customer became a member?
WITH purcheased_before_membership AS
(
  SELECT s.customer_id
       , m.join_date
       , s.order_date
       , s.product_id
       , n.product_name
       , RANK() OVER (PARTITION BY s.customer_id ORDER BY order_date DESC) AS ranked


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

-- What is the total items and amount spent for each member before they became a member?
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

-- If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
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
     , SUM(point)
FROM points
GROUP BY customer_id;

--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
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

-- EXTRA
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

-- EXTRA
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
         WHEN members = 'y' THEN DENSE_RANK() OVER (PARTITION BY customer_id, members ORDER BY order_date)
         ELSE NULL
       END AS ranked
FROM ranking;

