USE foodie_fi;

-- A. Customer Journey
SELECT customer_id, plan_name,start_date FROM subscriptions s join plans p on p.plan_id = s.plan_id
WHERE customer_id IN (1,2,11,13,15,16,18,19)
order by customer_id;


-- B. Data Analysis Questions
-- How many customers has Foodie-Fi ever had?
SELECT COUNT(DISTINCT customer_id) AS number_customer FROM subscriptions
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
SELECT MONTH(start_date),COUNT(plan_id) FROM subscriptions
WHERE plan_id = 0 
GROUP BY MONTH(start_date)
ORDER BY MONTH(start_date)
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
SELECT YEAR(start_date),plan_name,COUNT(s.plan_id) 
FROM subscriptions s join plans p on p.plan_id = s.plan_id
WHERE YEAR(start_date) > '2020'
GROUP BY YEAR(start_date),plan_name
order BY YEAR(start_date),plan_name

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
SELECT 
    FORMAT(COUNT(CASE WHEN plan_id = 4 THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id), 'N1') AS Percentage,
    COUNT(DISTINCT customer_id) AS TotalCustomers
FROM 
    subscriptions;
-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
WITH TrialChurn AS (
    SELECT 
        customer_id,
        plan_id,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan
    FROM 
        subscriptions
)
SELECT 
    FORMAT(
        COUNT(DISTINCT CASE WHEN plan_id = 0 AND next_plan = 4 THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id), 
        'N1'
    ) AS Percentage,
    COUNT(DISTINCT customer_id) AS TotalCustomers,
    COUNT(DISTINCT CASE WHEN plan_id = 0 AND next_plan = 4 THEN customer_id END) AS ChurnedAfterTrial
FROM 
    TrialChurn;


-- What is the number and percentage of customer plans after their initial free trial?
WITH PlanChanges AS (
    SELECT 
        customer_id,
        plan_id,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
    FROM subscriptions
)
SELECT 
    FORMAT(COUNT(DISTINCT CASE WHEN plan_id = 0 AND next_plan_id = 4 THEN customer_id END) * 100.0 / COUNT(DISTINCT customer_id), 'N1')
FROM PlanChanges;
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
SELECT * FROM subscriptions where start_date ='2020-12-31';

SELECT 
    plan_id, 
    COUNT(*) AS customer_count,
    (COUNT(*) * 100.0) / (SELECT COUNT(*) FROM subscriptions WHERE start_date <'2020-12-31') AS percentage_breakdown
FROM 
    subscriptions
WHERE 
    start_date < '2020-12-31'
GROUP BY 
    plan_id;
-- How many customers have upgraded to an annual plan in 2020?
WITH PlanChanges AS (
    SELECT 
        customer_id,
        plan_id,
        YEAR(start_date) AS plan_year,  -- Alias the year of the start_date
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
    FROM subscriptions
)
SELECT 
    COUNT(DISTINCT CASE WHEN plan_id != 3 AND next_plan_id = 3 THEN customer_id END) AS customers_changing_to_plan_3
FROM PlanChanges
WHERE plan_year = 2020;  -- Use the aliased column for filtering

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
WITH A AS(
    SELECT 
        customer_id,
        plan_id,
        start_date,
        MAX(CASE WHEN plan_id = 3 THEN start_date END) OVER (PARTITION BY customer_id) AS first_date,
		CASE WHEN LEAD(plan_id, 1) OVER (PARTITION BY customer_id ORDER BY start_date) = 3
THEN DATEDIFF(DAY,start_date,LEAD(start_date, 1) OVER (PARTITION BY customer_id ORDER BY start_date)) end as k
    FROM subscriptions
	where plan_id IN (0,3))
	SELECT AVG(k) from A

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
SELECT 
    COUNT(CASE WHEN plan_id = 2 AND next_plan_id = 1 THEN customer_id END)
FROM (
    SELECT 
        customer_id,
        plan_id,
        LEAD(plan_id) OVER (PARTITION BY customer_id ORDER BY start_date) AS next_plan_id
    FROM subscriptions
) AS P;

-- C. Challenge Payment Question --
-- The Foodie-Fi team wants you to create a new payments table for the year 2020 that includes amounts paid by each customer in the subscriptions table with the following requirements:

-- monthly payments always occur on the same day of month as the original start_date of any monthly paid plan
-- upgrades from basic to monthly or pro plans are reduced by the current paid amount in that month and start immediately
-- upgrades from pro monthly to pro annual are paid at the end of the current billing period and also starts at the end of the month period
-- once a customer churns they will no longer make payments

CREATE TABLE customer_payments (
    customer_id INT,
    plan_id INT,
    plan_name VARCHAR(255),
    payment_date DATE,
    amount DECIMAL(10, 2),
    payment_order INT
);


WITH monthly_payments AS
(
  -- Base case: Create the first monthly payment based on the subscription start date
  SELECT c.customer_id
       , c.plan_id
       , p.plan_name
       , c.start_date AS payment_date
       , p.price AS amount
       , 1 AS payment_order
  FROM subscriptions c
    JOIN plans p ON c.plan_id = p.plan_id
  WHERE c.start_date >= '2020-01-01'
    AND c.start_date <= '2020-12-31'
    AND p.plan_id NOT IN (0, 3, 4)

  UNION ALL

  -- Recursive case: Generate subsequent payments for monthly plans
  SELECT c.customer_id
       , c.plan_id
       , p.plan_name
       , DATEADD(MONTH, 1, mp.payment_date) AS payment_date
       , p.price AS amount
       , mp.payment_order + 1 AS payment_order
  FROM monthly_payments mp
    JOIN subscriptions c ON mp.customer_id = c.customer_id
      AND mp.plan_id = c.plan_id
    JOIN plans p ON c.plan_id = p.plan_id
  WHERE DATEADD(MONTH, 1, mp.payment_date) <= '2020-12-31'
    AND NOT EXISTS (
      -- Check if the customer upgraded to an annual plan after the current payment_date
      SELECT 1
      FROM subscriptions s
      WHERE s.customer_id = c.customer_id
        AND s.plan_id = 3  -- Annual plan
        AND MONTH(s.start_date) = MONTH(mp.payment_date) -- Ensure the upgrade happens after the current monthly payment date
    )
    AND NOT EXISTS (
      -- Prevent monthly payments if the customer has churned
      SELECT 1
      FROM subscriptions s
      WHERE s.customer_id = c.customer_id
        AND s.plan_id = 4  -- Churned plan
        AND s.start_date <= DATEADD(MONTH, 1, mp.payment_date)  -- Ensure no payments after churn
    )
),

-- Annual payments: Generate payments only once a year for 'pro annual'
annual_payments AS
(
  SELECT c.customer_id
       , c.plan_id
       , p.plan_name
       , c.start_date AS payment_date
       , p.price AS amount
       , 1 AS payment_order
  FROM subscriptions c
    JOIN plans p ON c.plan_id = p.plan_id
  WHERE p.plan_name = 'pro annual'
    AND c.start_date >= '2020-01-01'
    AND c.start_date <= '2020-12-31'
)

-- Combine monthly payments and annual payments, ensuring no payments are made after churn
SELECT payments.customer_id
     , payments.plan_id
     , payments.plan_name
     , payments.payment_date
     , CASE
         WHEN payments.plan_id > LAG(payments.plan_id) OVER (PARTITION BY payments.customer_id ORDER BY payments.payment_date) AND
           MONTH(payments.payment_date) = MONTH(LAG(payments.payment_date) OVER (PARTITION BY payments.customer_id ORDER BY payments.payment_date)) THEN payments.amount - LAG(payments.amount) OVER (PARTITION BY payments.customer_id ORDER BY payments.payment_date)
         ELSE payments.amount
       END AS amount
     , payments.payment_order
INTO #temp_payments -- Temporary table to handle the union of monthly and annual payments
FROM (
  SELECT *
  FROM monthly_payments
  UNION ALL
  SELECT *
  FROM annual_payments
) AS payments

-- Insert into the final table customer_payments
INSERT INTO customer_payments (
    customer_id,
    plan_id,
    plan_name,
    payment_date,
    amount,
    payment_order
)
SELECT customer_id
     , plan_id
     , plan_name
     , payment_date
     , amount
     , payment_order
FROM #temp_payments

-- Drop temporary table after insert
DROP TABLE #temp_payments;



