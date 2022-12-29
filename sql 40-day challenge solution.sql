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


-- Q18.

-- Q19.

-- Q20.

-- Q21.

-- Q22.

-- Q23.

-- Q24.

-- Q25.


