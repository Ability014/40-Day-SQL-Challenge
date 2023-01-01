-- Q1.

SELECT *
FROM Emloyees
WHERE DATEDIFF(YEAR, HIRE_DATE, GETDATE()) >= 25;

-- Q2.
SELECT *
FROM EMPLOYEES E1
WHERE E1.job_id LIKE '%CLERK%' AND E1.SALARY >= (SELECT AVG(E2.SALARY)
												 FROM EMPLOYEES E2 WHERE E1.DEPARTMENT_ID=E2.DEPARTMENT_ID)
												 
-- Q3.
WITH customer_daily_shoppings As (
SELECT customer_id, FORMAT(order_date, 'yyyy-MM') year_mon, CAST(order_date AS DATE) as date_cast, SUM(quantity) as total
FROM transaction_table
GROUP BY customer_id,FORMAT(order_date, 'yyyy-MM'), CAST(order_date AS DATE)
)
SELECT *
FROM customer_daily_shoppings c1
WHERE total >ALL (SELECT total 
				  FROM customer_daily_shoppings c2 
				  WHERE c1.customer_id=c2.customer_id AND c1.year_mon=c2.year_mon AND c1.date_cast > c2.date_cast)
ORDER BY 1, 3 DESC;

-- Q4.
SELECT CUSTOMER_ID, DATEPART(YEAR FROM TRANSACTION_DATE) TRANX_YEAR, DATEPART(MONTH FROM TRANSACTION_DATE) TRANX_MONTH,
COUNT(CASE WHEN TRANSACTION_TYPE = 'C' THEN AMOUNT END) CREDIT_VOLUME, SUM(CASE WHEN TRANSACTION_TYPE = 'C' THEN AMOUNT END) CREDIT_VALUE,
COUNT(CASE WHEN TRANSACTION_TYPE = 'D' THEN AMOUNT END) DEBIT_VOLUME, SUM(CASE WHEN TRANSACTION_TYPE = 'D' THEN AMOUNT END) DEBIT_VALUE
FROM transaction_table
WHERE resp_code = '00';

-- Q5.
SELECT s.*, g.grade
FROM scores s, grades g
WHERE s.scores >= lower_limit AND s.scores <= upper_limit

-- Q6.
/*
This procedure assumes that an employee comes to the office at least once a week
*/
WITH EMPLOYEE_TIME_DIFF AS (
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, DATENAME(WEEKDAY, TIME_IN) WEEK_DAY,
DATEDIFF(DAY, TIME_IN, LEAD(TIME_IN) OVER(PARTITION BY EMPLOYEE_ID, CONCAT(DATEPART(YEAR FROM TIME_IN), DATEPART(WEEK FROM TIME_IN)) ORDER BY TIME_IN)) DATE_LAG_DIFF
FROM employee_attendance)
SELECT DISTINCT EMPLOYEE_ID, FIRST_NAME, LAST_NAME
FROM EMPLOYEE_TIME_DIFF
WHERE DATE_LAG_DIFF >= 4 AND WEEK_DAY <> 'Wednesday';

-- Q7.
WITH AGGREGATED_DAILY_ORDERS AS (
SELECT CAST(order_date as Date) order_date, SUM(amount) Revenue
FROM sales_fact
WHERE order_date >= '2022-01-01' AND order_status = 'Delivered'
GROUP BY CAST(order_date as Date))
SELECT *, AVG(Revenue) OVER(ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) Seven_days_MA
FROM AGGREGATED_DAILY_ORDERS;

-- Q8.
WITH FIRST_CUST_TRANX AS (
SELECT CUSTOMER_ID, MIN(order_date) FIRST_TRANX_DATE
FROM Sales
GROUP BY CUSTOMER_ID
)
SELECT C.id, Full_name, FIRST_TRANX_DATE, DATEDIFF(day, join_date, FIRST_TRANX_DATE) [duration_before_1st_tranx (In Days)]
FROM Customers C
LEFT JOIN FIRST_CUST_TRANX F
ON C.CUSTOMER_ID=F.CUSTOMER_ID;

-- Q9.
WITH EMPLOYEE_MONTHLY_AGGREGATED_SALES AS
(
SELECT dept_id, employee_id, DATEPART(YEAR FROM order_date) ORDER_YEAR, DATEPART(MONTH FROM order_date) ORDER_MONTH, SUM(amount) Revenue
FROM sales_table s
JOIN employee e
ON s.employee_id=e.id
GROUP BY employee_id, DATEPART(YEAR FROM order_date), DATEPART(MONTH FROM order_date)
),
Highest_per_dept As (
SELECT dept_id, d.name, ORDER_YEAR, ORDER_MONTH,
MAX(EM.Revenue) highest_rev
FROM employee e
LEFT JOIN EMPLOYEE_MONTHLY_AGGREGATED_SALES EM
ON e.id = EM.employee_id
GROUP BY  dept_id, d.name, ORDER_YEAR, ORDER_MONTH)
SELECT H.*, e.first_name, e.last_name
FROM Highest_per_dept H
JOIN EMPLOYEE_MONTHLY_AGGREGATED_SALES EM
ON H.dept_id=EM.dept_id AND H.ORDER_YEAR=EM.ORDER_YEAR AND H.ORDER_MONTH=EM.ORDER_MONTH AND H.highest_rev=EM.Revenue
JOIN employee e
ON EM.employee_id=e.id;

-- Q10.
SELECT *
FROM employee
WHERE last_name LIKE 'R%e';

-- Q11.
SELECT SUBSTRING(time, 1, CHARINDEX('+', time)-1) + SUBSTRING(time, CHARINDEX('+', time)+1, LEN(time)) As New_Time
FROM FOOTBALL

-- Q12.
WITH customer_channel AS (
SELECT customer_id, channel
FROM TRANX_TABLE
WHERE resp_mssg = 'successful'
GROUP BY customer_id, channel)
SELECT customer_id, STRING_AGG(channel, ' ,') comma_sep_channels
FROM customer_channel
GROUP BY customer_id;

-- Q13.
WITH FIRST_MAX_SCORE AS (
SELECT submission_id, hacker_id, 
submission_date,
RANK() OVER(PARTITION BY hacker_id ORDER BY score DESC, submission_date) FIRST_TIME, 
MAX(score) OVER(PARTITION BY hacker_id) MAX_SCORE
FROM submissions)
SELECT submission_id, hacker_id, submission_date, MAX_SCORE
FROM FIRST_MAX_SCORE
WHERE FIRST_TIME = 1;

-- Q14.


customers (id varchar(40), first_name varchar(100), last_name varchar(100), age int, dob date, gender varchar(1), mobile varchar(20));

campaign (campaign_id varchar(40), customer_id varchar(40), campaign_manager varchar(200), campaign_name varchar(200), start_date date, end_date date);

transaction (id varchar(40), customer_id varchar(40), amount int, channel varchar(100), tran_date date);

Metric(s) to track
The revenue generated pre-campaign (14 days before the campaign start date), during the campaign (between start_date and end_date), 
and post-campaign (14 days after the campaign end date).

-- Q15.
SELECT DATEPART(YEAR FROM order_date) ORDER_YEAR, DATEPART(MONTH FROM order_date) ORDER_MONTH,
SUM(quantity*unit_price) REVENUE
FROM orders O
JOIN order_details OD
ON O.order_id=OD.order_id
JOIN products P
ON OD.product_id=P.id
GROUP BY DATEPART(YEAR FROM order_date), DATEPART(MONTH FROM order_date)

-- Q16.
WITH MONTHLY_REV AS (
SELECT customer_id, DATEPART(YEAR FROM tranx_date) TRANX_YEAR, DATEPART(MONTH FROM tranx_date) TRANX_MONTH, SUM(amount) REVENUE
FROM transaction
WHERE status = 'successful'
GROUP BY customer_id, DATEPART(YEAR FROM tranx_date), DATEPART(MONTH FROM tranx_date)
)
SELECT TRANX_YEAR, TRANX_MONTH, customer_id, REVENUE,
CASE WHEN REVENUE <= 50000 THEN 'BRONZE'
	 WHEN REVENUE <= 250000 THEN 'SILVER'
	 WHEN REVENUE <= 1000000 THEN 'GOLD'
	 ELSE 'PLATINUM'
END REV_CATEGORY
FROM MONTHLY_REV

-- Q17.
/*
A company wants to build an SQL-based loyalty model which tracks the activities of customers using two months intervals 
(current month and previous month). The company wants to know customers that fall in these categories:

1. Customers that subscribed to a product in both months
2. Customers that subscribed in the previous month but not in the current month
3. Customers that subscribed in the current month but not in the previous month
4. Customers that didn't subscribe in both months

Assumptions
Current month - August 2022
Previous month - July 2022

The table(s) to answer these metrics is as highlighted below:

customers (id, firstName, lastName, phone, age, address, gender)
subscriptions (id, customer_id, sub_date, amount, plan, description)
*/

WITH CURRENT_MONTH_SUB AS (
SELECT id AS customer_id, 
CASE WHEN id IS NULL THEN 0 ELSE 1 END CURR_SUB_CLASS
FROM customers C
LEFT JOIN subscriptions S
ON C.id=S.customer_id
WHERE sub_date > '2022-07-31' AND sub_date < '2022-09-01'
),
PREVIOUS_MONTH_SUB AS (
SELECT id AS customer_id, 
CASE WHEN id IS NULL THEN 0 ELSE 1 END PREV_SUB_CLASS
FROM customers C
LEFT JOIN subscriptions S
ON C.id=S.customer_id
WHERE sub_date > '2022-06-30' AND sub_date < '2022-08-01'
)
SELECT C.customer_id, CURR_SUB_CLASS, PREV_SUB_CLASS,
CASE WHEN CURR_SUB_CLASS = 0 AND PREV_SUB_CLASS = 1 THEN 'Previous Subscriber'
	 WHEN CURR_SUB_CLASS = 1 AND PREV_SUB_CLASS = 0 THEN 'Current Subscriber'
	 WHEN CURR_SUB_CLASS = 1 AND PREV_SUB_CLASS = 1 THEN 'Constant Subscriber'
	 ELSE 'Churn Subscriber' END Subscriber_Class
FROM CURRENT_MONTH_SUB C
JOIN PREVIOUS_MONTH_SUB P
ON C.customer_id=P.customer_id;

-- Q18.
/*
18.Given a sales table as described below, write a query that fetches the daily cumulative sales for the sales team.

sales (id, sales_date, amount, order_id, customer_id, description);
*/
WITH DAILY_SALES AS (
SELECT CAST(sales_date as date) sales_date, SUM(amount) revenue
FROM sales
GROUP BY CAST(sales_date as date)
)
SELECT sales_date, SUM(revenue) OVER(ORDER BY sales_date) cum_sales
FROM DAILY_SALES;

-- Q19.
/*
Consider a Lending company interested in tracking some business metrics as highlighted below

# Number of loan applications by customers
# Number of active and cleared loan applications per customer
# Number of default loan applications per customer (Only cleared loan applications)
# Number of late payments per application and customer

Using the tales highlighted below:

loan_application(id, customer_id, first_name, last_name, amount, duration, start_date, end_date, pay_day, status);
loan_repayment(id, application_id, customer_id, amount, expected_amount, payment_date, expected_payment_date, pay_num);

Write a single query that answers the above metrics.

NB:
status: {active, cleared}.
pay_day: The day in the month expected to pay.
duration: integer value specifying the duration of the loan in months.
pay_num: Integer value corresponding to the nth payment of the applicant.
default loan means that the applicant cleared the loan after the expected end date.
late payment means paying after the expected payment date.

*/
-- The lines of code below answers the first three metrics
SELECT customer_id, COUNT(id) NUM_OF_LOAN_APPLICATIONS,
COUNT(CASE WHEN status = 'active' THEN id END) ACTIVE_LOANS,
COUNT(CASE WHEN status = 'cleared' THEN id END) CLEARED_LOANS,
COUNT(CASE WHEN end_date > DATEADD(MONTH, duration, start_date) THEN id END) DEFAULT_LOANS
FROM loan_application
GROUP BY customer_id;

-- The lines of code  below answers the last metric
SELECT LA.customer_id, LA.id As Application_Id, 
COUNT(CASE WHEN payment_date > expected_payment_date THEN application_id END) NUM_OF_LATE_PAYMENTS
FROM loan_application LA
JOIN loan_repayment LP 
ON LA.id = LP.application_id
GROUP BY LA.customer_id, LA.id;

-- Q20.
/*
A transportation company is interested in answering some business metrics in its data.

Highlighted below are some of the metrics that are needed to be captured.

1a. Waiting time (in minutes) for each customer ride order. 

1b. Speed in m/s of the driver between arrival time and request time.

The table to capture this metric is as highlighted below:

rides (id VARCHAR(20) PK, trip_date DATETIME, passenger_id VARCHAR(20), request_time DATETIME, driver_arrived DATETIME, cancelled_at DATETIME, driver_id VARCHAR(20), started_at DATETIME, drivers_distance_at_acceptance_KM FLOAT, dropoff_at DATETIME, region VARCHAR(200));

NB:
trip_date: Time at which the trip was initiated
request_time: Time at which passenger successfully requested a ride
driver_arrived: Time the driver got to the pickup location
cancelled_at: Time at which the passenger cancelled the ride started_at: Time at which the driver started the trip
dropoff_at: Time the trip was completed
*/
-- Waiting time should be the time it took for driver to arrive at pickup location after request time.
SELECT DATEDIFF(MINUTE, request_time, driver_arrived) WAITING_TIME,
(drivers_distance_at_acceptance_KM * 1000)/(DATEDIFF(SECOND, request_time, driver_arrived)) SPEED_B4_ARRIVAL
FROM rides;

-- Q21.

-- Q22.

-- Q23.

-- Q24.

-- Q25.


