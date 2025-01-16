# Analyzing Subscription Trends and Customer Retention for Foodie-Fi

## Introduction———————————————————————

In this case study, we focus on analyzing the subscription data of **Foodie-Fi**, a popular subscription-based service. The objective is to explore key business questions related to subscription growth, customer retention, payment trends, and churn behavior. By examining the data, we aim to uncover valuable insights that can inform strategies for improving customer loyalty, enhancing the subscription model, and optimizing overall business performance. This analysis will help Foodie-Fi better understand their customer base and make data-driven decisions to drive sustainable growth.

This report will be divided into three main sections:

- **A. Customer Journey**: Understanding the stages customers go through from awareness to advocacy.
- **B. Data Analysis Questions**: Addressing critical business questions regarding subscription patterns, growth, and churn.
- **C. Payment**: Analyzing payment behaviors and trends to identify areas for improvement.

## **A. Customer Journey———————————————————**

### **1. Awareness Stage**

- **Customer 1**: Signs up for the **trial plan** on **2020-08-01** for **7 days**.
- **Customer 2**: Signs up for the **trial plan** on **2020-09-20** for **7 days**.

### **2. Consideration Stage**

- **Customer 1**: Transitions to the **basic monthly plan** on **2020-08-08** (still active).
- **Customer 2**: Switches to the **pro annual plan** on **2020-09-27** (still active).

### **3. Decision Stage**

- **Customer 11**: Signs up for the **trial plan** on **2020-11-19** and **churns** on **2020-11-26**.
- **Customer 13**: Decides to continue with the **basic monthly plan** on **2020-12-22** for **97 days**.

### **4. Retention Stage**

- **Customer 16**: Continues with the **basic monthly plan** for **136 days** from **2020-06-07** and switches to the **pro annual plan** on **2020-10-21** (still active).
- **Customer 19**: Stays on the **pro monthly plan**, then transitions to **pro annual** on **2020-08-29** (still active).

### **5. Advocacy Stage**

- **Customer 19**: After using the **pro monthly plan**, they switch to **pro annual** on **2020-08-29**, indicating satisfaction. Though explicit advocacy isn't shown, this continued usage and the upgrade can lead to word-of-mouth referrals.

Note: The customers mentioned above are just a sample from a larger customer base and represent different stages of the customer journey.

## B.Exploring Key Subscription Metrics for Foodie-Fi—————

1. How many customers has Foodie-Fi ever had?

1000 customer

1. What is the monthly distribution of `trial` plan `start_date` values for our dataset - use the start of the month as the group by value

| **Month** | **Count of Trial Plan** |
| --- | --- |
| January | 88 |
| February | 68 |
| March | 94 |
| April | 81 |
| May | 88 |
| June | 79 |
| July | 89 |
| August | 88 |
| September | 87 |
| October | 79 |
| November | 75 |
| December | 84 |
- **Most Trial Plans (March - 94 trial plans):**
    
    March saw the highest number of trial plan sign-ups, which suggests that the marketing efforts or seasonal factors during this month were likely more effective in attracting new customers. It could also indicate that customers tend to sign up for trials at the beginning of the year, possibly due to New Year promotions, resolutions, or increased interest in new services.
    
- **Least Trial Plans (February - 68 trial plans):**
    
    February had the lowest number of trial plan sign-ups, which might indicate a slower period for customer acquisition. This could be due to various factors like post-holiday fatigue, lower marketing activity, or fewer promotions during this month. It might also reflect a seasonal dip or a timing issue in the customer journey that resulted in fewer trial sign-ups.
    
1. What plan `start_date` values occur after the year 2020 for our dataset? Show the breakdown by count of events for each `plan_name`

For the year **2021**, we see the following distribution of plan start dates:

- **Churn** had the highest count with **71** events.
- **Pro annual** and **pro monthly** plans had **63** and **60** events respectively.
- **Basic monthly** had the fewest events with **8**.
1. What is the customer count and percentage of customers who have churned rounded to 1 decimal place?

**307 customers** (**30.7%** of the total customers) have churned

1. How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?

**92 customers** (9.2% of the total customers) churned directly after their trial.

1. What is the customer count and percentage breakdown of all 5 `plan_name` values at `2020-12-31`?

| **Plan Name** | **Customer Count** | **Percentage Breakdown** |
| --- | --- | --- |
| **Trial**  | 1000 | 40.87% |
| **Pro Monthly**  | 195 | 7.97% |
| **Basic Monthly**  | 538 | 21.99% |
| **Churned**  | 235 | 9.60% |
| **Pro Annual**  | 479 | 19.57% |
1. How many customers have upgraded to an annual plan in 2020?

**253 customers** upgraded to an annual plan in 2020.

1. How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?

On average, it takes **104 days** for a customer to upgrade to an annual plan from the day they join Foodie-Fi.

1. How many customers downgraded from a pro monthly to a basic monthly plan in 2020?

No one switched from the pro monthly plan to the basic monthly plan in 2020.

### C. Key Takeaways and Recommendations————————————————

- **Q1 and Q4 Churn Patterns**: High churn during the first and last quarters suggests potential **seasonal behavior** or **financial evaluation** by customers. This provides an opportunity to investigate and implement targeted retention campaigns during these periods.
- **ARPU of $118**: This is a healthy ARPU figure, indicating that Foodie-Fi is generating solid revenue per user. However, it's important to monitor if churn is impacting this figure in the long run.
- **Strategies**: Consider **seasonal promotions**, **enhanced customer engagement**, and **targeted marketing** to address churn spikes in Q1 and Q4. Additionally, tracking **ARPU in relation to churn** can help assess whether retention efforts are working effectively.

###