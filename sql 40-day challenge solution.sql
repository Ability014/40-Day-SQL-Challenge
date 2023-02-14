---------------------------- Please note that all codes here are written in SQL Server flavour of SQL (T-SQL) ---------------------------------------

-- Q1.
/*
Given the table in the word document, write a query to return employees that have spent at least 25 years in the company.
*/

SELECT *
FROM Emloyees
WHERE DATEDIFF(YEAR, HIRE_DATE, GETDATE()) >= 25;

-- Q2.
/*
Using the employee’s table as provided above, write a query to extract information of employees where job_id like CLERK and salary 
above or equal average employee salary in their department.
*/

SELECT *
FROM EMPLOYEES E1
WHERE E1.job_id LIKE '%CLERK%' AND E1.SALARY >= (SELECT AVG(E2.SALARY)
												 FROM EMPLOYEES E2 WHERE E1.DEPARTMENT_ID=E2.DEPARTMENT_ID)
												 
-- Q3.
/*
So an E-commerce company has some customers they intend to track their performance for the month. Here is the business question:

We want to track the days at which customers buy more compared to the preceding days in the month

Table schema looks like this;

	transaction_table(order_id, product_id, quantity, unit_price, order_date, customer_id)

NB: order_date is a datetime field
*/

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
/*
A bank has a table called transaction_table (transaction_id, customer_id, account_id, amount, transaction_type, narration, resp_code, transaction_date) that stores information about customer's financial transactions.

The bank wants to know the monthly volume and value of successful credit and debit transactions of each customer.

The final table should look like this;
CUSTOMER_ID, TRANX_YEAR, TRANX_MONTH, CREDIT_VOLUME, CREDIT_VALUE, DEBIT_VOLUME, DEBIT_VALUE

NB:
	transaction_date is a timestamp
	transaction_type is: C for Credit & D for Debit
	resp_code is the response code for transactions. '00' for successful transactions
*/

SELECT CUSTOMER_ID, DATEPART(YEAR FROM TRANSACTION_DATE) TRANX_YEAR, DATEPART(MONTH FROM TRANSACTION_DATE) TRANX_MONTH,
COUNT(CASE WHEN TRANSACTION_TYPE = 'C' THEN AMOUNT END) CREDIT_VOLUME, SUM(CASE WHEN TRANSACTION_TYPE = 'C' THEN AMOUNT END) CREDIT_VALUE,
COUNT(CASE WHEN TRANSACTION_TYPE = 'D' THEN AMOUNT END) DEBIT_VOLUME, SUM(CASE WHEN TRANSACTION_TYPE = 'D' THEN AMOUNT END) DEBIT_VALUE
FROM transaction_table
WHERE resp_code = '00';

-- Q5.
/*
There are two tables:

scores (student_id, course_id, full_name, mark)
grades (grade, lower_limit, upper_limit)

Write a query to categorize the marks in the scores table into grades given that the marks fall between the lower and upper limit inclusive.
*/

SELECT s.*, g.grade
FROM scores s, grades g
WHERE s.scores >= lower_limit AND s.scores <= upper_limit

-- Q6.
/*
This procedure assumes that an employee comes to the office at least once a week.

Given an employee attendance table, kindly provide a query that shows if an employee was absent 3 days consecutively in a week.
The table structure is given below:

employee_attendance (ID VARCHAR(10), EMPLOYEE_ID INT, TIME_IN DATETIME, TIME_OUT DATETIME, FIRST_NAME VARCHAR(100), LAST_NAME VARCHAR(100))
*/

WITH EMPLOYEE_TIME_DIFF AS (
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, DATENAME(WEEKDAY, TIME_IN) WEEK_DAY,
DATEDIFF(DAY, TIME_IN, LEAD(TIME_IN) OVER(PARTITION BY EMPLOYEE_ID, 
CONCAT(DATEPART(YEAR FROM TIME_IN), DATEPART(WEEK FROM TIME_IN)) ORDER BY TIME_IN)) DATE_LAG_DIFF
FROM employee_attendance)
SELECT DISTINCT EMPLOYEE_ID, FIRST_NAME, LAST_NAME
FROM EMPLOYEE_TIME_DIFF
WHERE DATE_LAG_DIFF >= 4 AND WEEK_DAY <> 'Wednesday';

-- Q7.
/*
The sales of an E-commerce store are recorded in the table called 
sales_fact (order_id varchar(200), order_date datetime, amount float, customer_id varchar(100), order_status varchar(200)). 
The business wants to find the 7 days moving average of delivered orders recorded from January 2022 till date.

NB:
	order_status has values ('Delivered', 'Cancelled', 'In progress')

Write an SQL query that solves the business problem.
*/

WITH AGGREGATED_DAILY_ORDERS AS (
SELECT CAST(order_date as Date) order_date, SUM(amount) Revenue
FROM sales_fact
WHERE order_date >= '2022-01-01' AND order_status = 'Delivered'
GROUP BY CAST(order_date as Date))
SELECT *, AVG(Revenue) OVER(ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) Seven_days_MA
FROM AGGREGATED_DAILY_ORDERS;

-- Q8.
/*
The business wants to know how long it took a customer to perform his/her first transaction from the time the customer was registered 
on the platform.

Customers (id INT, join_date datetime, Full_name Varchar(200));

Sales (order_id INT, customer_id INT, order_date datetime, Amount INT, order_status VARCHAR(50));

NB: Join date is the date the customer registered on the platform
*/

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
/*
The business requires the highest performing employee per department each month. The tables required to solve this problem is as highlighted below:

department (id, name, location);
employee (id, first_name, last_name, manager_id, dept_id);
sales_table (order_id, customer_id, employee_id, amount, order_date, order_status);

NB: order_status: {'delivered', 'cancelled'}
*/

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
/*
Given an employee table, write a query to generate the last name of employees that start with R and end with e.
*/
SELECT *
FROM employee
WHERE last_name LIKE 'R%e';

-- Q11.
/*
Given a football stat table, where the time is stored as varchar, write a query to add a new column to store the result as integer.

The sample rows of the time column is given below:

'30', '44', '90+3', '89', '105+1', '120+2', '67'

The result column should be:
30, 44, 93, 89, 106, 122, 67
*/

SELECT SUBSTRING(time, 1, CHARINDEX('+', time)-1) + SUBSTRING(time, CHARINDEX('+', time)+1, LEN(time)) As New_Time
FROM FOOTBALL

-- Q12.
/*
Bank XYZ wants to campaign its customers on the available transaction channels, so it needed to know what channel(s) its customers transact on. 
The given table to get this metric is provided below:

TRANX_TABLE (tranx_id, customer_id, account_id, amount, tranx_date, channel, resp_code, resp_mssg)
The result table should consist of just two columns, the customer_id, followed by the channel(s) used by the customer a comma-separated list in 
ascending order of channel(s).

NB:
	channels: {'POS', 'ATM', 'MOBILE', 'WEB', 'INTERNET BANKING', 'OTC', 'USSD'}
	Successful transactions are with resp_mssg = 'successful'
*/

WITH customer_channel AS (
SELECT customer_id, channel
FROM TRANX_TABLE
WHERE resp_mssg = 'successful'
GROUP BY customer_id, channel)
SELECT customer_id, STRING_AGG(channel, ' ,') comma_sep_channels
FROM customer_channel
GROUP BY customer_id;

-- Q13.
/*
Company ABC posted a Hackathon on Zindi with data professionals all over the world participating. The Hackathon was planned to run for 30 days. 
After the end of the 30 days, company ABC is interested in extracting the first time a hacker had its maximum score for all submissions. 
The table to answer this metric is as provided below:

submissions (submission_id varchar(10), hacker_id varchar(10), submission_date datetime, score int);

NB:
	A Hacker can make multiple submissions in a day
	Kindly refer to the word document for sample input and output
*/

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
/*
An E-commerce company Radical is planning to measure the effectiveness of its campaigns on customer transactions. 
It is called a campaign evaluation.
The given table is given below to provide an SQL query that answers the metric:

customers (id varchar(40), first_name varchar(100), last_name varchar(100), age int, dob date, gender varchar(1), mobile varchar(20));
campaign (campaign_id varchar(40), customer_id varchar(40), campaign_manager varchar(200), campaign_name varchar(200), start_date date, end_date date);
transaction (id varchar(40), customer_id varchar(40), amount int, channel varchar(100), tran_date date);

Metric(s) to track
The revenue generated pre-campaign (14 days before the campaign start date), during the campaign (between start_date and end_date), 
and post-campaign (14 days after the campaign end date).
*/

-- NB: A customer might occur in more than one campaign
SELECT campaign_id,
SUM(CASE WHEN tran_date >= DATEADD(DAY, -14, start_date) AND tran_date < start_date THEN amount END) PRE_CAMPAIGN_REVENUE,
SUM(CASE WHEN tran_date >= start_date AND tran_date <= end_date THEN amount END) CAMPAIGN_REVENUE,
SUM(CASE WHEN tran_date > end_date AND tran_date <= DATEADD(DAY, 14, end_date) THEN amount END) POST_CAMPAIGN_REVENUE
FROM campaign CG
LEFT JOIN transaction T
ON CG.customer_id = T.customer_id
GROUP BY campaign_id;

-- Q15.
/*
An E-commerce company wants to know how much revenue they make for every order each month. Here are the tables that are needed for this analysis:

orders (order_id (PK), order_date, customer_id, product_id, location, description)
products (id (PK), name, description, supplier_id, available_quantity, unit_price)
order_details (order_id, product_id, quantity)
*/

SELECT DATEPART(YEAR FROM order_date) ORDER_YEAR, DATEPART(MONTH FROM order_date) ORDER_MONTH,
SUM(quantity*unit_price) REVENUE
FROM orders O
JOIN order_details OD
ON O.order_id=OD.order_id
JOIN products P
ON OD.product_id=P.id
GROUP BY DATEPART(YEAR FROM order_date), DATEPART(MONTH FROM order_date)

-- Q16.
/*
A retail company is interested in categorizing its customers into four groups based on monthly customer transaction revenue. 
The four groups are as highlighted below:

1. Bronze: (<=50,000)
2. Silver: (>50,000 & <=250,000)
3. Gold: (>250,000 & <=1,000,000)
4. Platinum: (>1,000,000)

The transaction table required for this metric is as highlighted below:

transaction (id, customer_id, tranx_date, amount, channel, status)

NB:
	status = 'successful' indicates a successful transaction
*/

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
Given a sales table as described below, write a query that fetches the daily cumulative sales for the sales team.

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
cancelled_at: Time at which the passenger cancelled the ride 
started_at: Time at which the driver started the trip
dropoff_at: Time the trip was completed
*/
-- Waiting time should be the time it took for driver to arrive at pickup location after request time.
SELECT DATEDIFF(MINUTE, request_time, driver_arrived) WAITING_TIME,
(drivers_distance_at_acceptance_KM * 1000)/(DATEDIFF(SECOND, request_time, driver_arrived)) As [SPEED_B4_ARRIVAL (m/s)]
FROM rides;

-- Q21.
/*
Use table from 20 to answer this metric: Number of successful/cancelled trips for each month as a pivot
*/
SELECT DATEPART(YEAR FROM trip_date) TRIP_YEAR, DATEPART(MONTH FROM trip_date) TRIP_MONTH,
COUNT(CASE WHEN cancelled_at IS NULL THEN id END) SUCCESSFUL_TRIPS, 
COUNT(CASE WHEN cancelled_at IS NOT NULL THEN id END) CANCELLED_TRIPS
FROM rides
GROUP BY DATEPART(YEAR FROM trip_date), DATEPART(MONTH FROM trip_date);

-- Q22.
/*
Use table from 20 to answer this metric: Number of successful trips and average travel time per driver
*/
SELECT driver_id, COUNT(id) SUCCESSFUL_TRIPS, AVG(DATEDIFF(MINUTE, dropoff_at, started_at)) AVG_TRAVEL_TIME
FROM rides
WHERE cancelled_at IS NULL 
GROUP BY driver_id;

-- Q23.
/*
Use table from 20 to answer this metric: Top 10 drivers (percentage of successful trips compared to total ride requests).
Only consider total trips per driver that exceeds the average number of trips for all drivers.
*/
WITH AGG_DRIVER_STAT AS (
SELECT driver_id, COUNT(CASE WHEN cancelled_at IS NULL THEN id END) SUCCESSFUL_TRIPS, 
COUNT(id) TOTAL_TRIPS
FROM rides
GROUP BY driver_id)
SELECT TOP 10 *, SUCCESSFUL_TRIPS/TOTAL_TRIPS * 100 PERCENT_SUCCESSFUL_TRIPS
FROM AGG_DRIVER_STAT
WHERE TOTAL_TRIPS > (SELECT AVG(TOTAL_TRIPS) FROM AGG_DRIVER_STAT)
ORDER BY PERCENT_SUCCESSFUL_TRIPS DESC;

-- Q24.
/*
Use table from 20 to answer this metric: Waiting time between a passenger cancelled order and the next order request.
*/
WITH AGG_DRIVER_STAT AS (
SELECT passenger_id, 
	  (LEAD(trip_date) OVER(PARTITION BY passenger_id, CAST(trip_date AS DATE) ORDER BY trip_date)) next_order_time, cancelled_at
FROM rides)
SELECT *, DATEDIFF(mm, cancelled_at, next_order_time) waiting_time_before_next_req
FROM AGG_DRIVER_STAT
WHERE DATEDIFF(mm, cancelled_at, next_order_time) IS NOT NULL;

-- Q25.
/*
A transportation business just lauched its mobile app for customers to order rides to 
diffferent destinations. This application is been monitored for quality assurance purpose
and logs of the ride orders are logged into ride_logs table. Highlighted below is the 
structure of the table:

ride_logs (log_id, trip_id, trip_date, passenger_id, passenger_cancelled, pickup, destination);

The business needs to be aware based on historical log data available, is the distribution
of monthly cancelled rides a decreasing sequence? Write a query to answer the business question.

NB: passenger_cancelled is the time at which a passenger calcelled the order else NULL
*/
WITH MONTHLY_CANC_TRIPS AS (
SELECT DATEPART(YEAR FROM trip_date) TRIP_YEAR, DATEPART(MONTH FROM trip_date) TRIP_MONTH, 
COUNT(CASE WHEN passenger_cancelled IS NOT NULL THEN trip_id END) NO_CANCELED_TRIPS
FROM ride_logs
GROUP BY DATEPART(YEAR FROM trip_date), DATEPART(MONTH FROM trip_date)),
Monthly_Diff_of_Canc_Trips As (
SELECT *, CASE WHEN (LEAD(NO_CANCELED_TRIPS) OVER(ORDER BY TRIP_YEAR, TRIP_MONTH) - NO_CANCELED_TRIPS) > 0 THEN 1 ELSE 0 END As Monthly_Difference
FROM MONTHLY_CANC_TRIPS)
SELECT CASE WHEN SUM(Monthly_Difference) = 0 THEN TRUE ELSE FALSE END As DECREASING_SEQUENCE 
FROM Monthly_Diff_of_Canc_Trips;

-- Q26.
/*
A financial institution is planning a reward model for its customers that do not spend up to
50% of their inflow in the previous month. Write an SQL query to identify such customers
from the transaction table.

Constraints: The customer credit transaction for the month must be at least 50,000.

NB: A customer can have more than 1 account
*/
SELECT CUSTOMER_ID, SUM(CASE WHEN TRAN_TYPE = 'C' THEN AMOUNT END) INFLOW, SUM(CASE WHEN TRAN_TYPE = 'D' THEN AMOUNT END) OUTFLOW
FROM TRANX_TABLE
WHERE TRAN_DATE > CAST(dateadd(d, -1, dateadd(mm,datediff(m,0,getdate())-1,0)) AS DATE) AND TRAN_DATE <  CAST(dateadd(mm,datediff(m,0,getdate())-0,0) AS DATE)
GROUP BY CUSTOMER_ID
HAVING (SUM(CASE WHEN TRAN_TYPE = 'C' THEN AMOUNT END)/2) < SUM(CASE WHEN TRAN_TYPE = 'D' THEN AMOUNT END); 

-- Q27.
/*
As an analyst for a sport company, you are requested to present the football data available
in the database as: Form of last five matches of each football team in the football table
as a pivot table.

Form implies either W, D or L. Where W: win, D: Draw, L: Lose
*/
WITH ALL_FORM AS
(
SELECT [DATE], Home_Team Team, CASE WHEN Home_Score > Away_Score THEN 'W' 
									WHEN Home_Score < Away_Score THEN 'L'
									ELSE 'D' END FORM
FROM matches
WHERE [DATE] BETWEEN DATEADD(month, -90, GETDATE()) AND GETDATE() --USING LAST 90 DAYS AS A THRESHOLD
UNION ALL
SELECT [DATE], Away_Team Team, CASE WHEN Home_Score < Away_Score THEN 'W' 
									WHEN Home_Score > Away_Score THEN 'L'
									ELSE 'D' END FORM
FROM matches
WHERE [DATE] BETWEEN DATEADD(month, -90, GETDATE()) AND GETDATE()
),
RANK_FORM AS 
(SELECT *, RANK() OVER(PARTITION BY Team ORDER BY [DATE] DESC) RNK
FROM ALL_FORM)
SELECT *
FROM (SELECT Team, FORM, RNK 
FROM RANK_FORM
WHERE RNK <= 5) T1
PIVOT (MAX(FORM) FOR RNK IN ([1],[2],[3],[4],[5])) PVT;


-- Q28.
/*A transportation business is interested in understanding its customers so as to provide a
more personalized experience. The business needs to identify customers that ordered a return
ride to their pick up location.

A typical scenario will be used in this conext. We assume that Pickup_location will be same as Dropoff_location in a return ride scenario.

trips(trip_id, passenger_id, driver_id, pickup_datetime, dropoff_datetime, Trip_distance, 
pickup_location, Standard_rate, dropoff_location, Payment_type, Fare_amount, Tolls_amount, Total_amount)
*/
--Assumption: A ride is referred as return ride if the return ride was on the same day
--This trip returns all return trips for eah passengers, and tells time out & time in of pickup location.
WITH RANKED_TRIPS AS (
SELECT trip_id, passenger_id, pickup_location, dropoff_location,
FORMAT(pickup_datetime,'yyyy-MM-dd') pickup_date,
FORMAT(dropoff_datetime,'yyyy-MM-dd') droppodff_date,
pickup_datetime, dropoff_datetime,
RANK() OVER(PARTITION BY passenger_id, FORMAT(pickup_datetime,'yyyy-MM-dd') ORDER BY pickup_datetime) pickup_rank,
RANK() OVER(PARTITION BY passenger_id, FORMAT(pickup_datetime,'yyyy-MM-dd') ORDER BY dropoff_datetime) droppoff_rank
FROM trips)
SELECT RT1.trip_id, RT1.passenger_id, RT1.pickup_location, RT2.dropoff_location, RT1.pickup_datetime, RT2.dropoff_datetime
FROM RANKED_TRIPS RT1
JOIN RANKED_TRIPS RT2
ON RT1.passenger_id = RT2.passenger_id AND RT1.pickup_date=RT2.pickup_date AND RT1.pickup_location=RT2.dropoff_location AND RT1.pickup_rank > RT2.droppoff_rank;

-- Q29.
/*
You have been provided with employees table, and you are charged to create an Org chart with it.
How do you write a query to identify the hierachy of employees from the employees table?

The sample of employees data is attached to this post.
*/
WITH EMPLOYEE_HIERARCHY AS 
(
SELECT 1 As Hierarchy, *
FROM EMPLOYEES
WHERE MANAGER_ID IS NULL
UNION ALL
SELECT Hierarchy+1, M.*
FROM EMPLOYEE_HIERARCHY E
JOIN EMPLOYEES M
ON E.EMPLOYEE_ID=M.MANAGER_ID
)
SELECT * FROM EMPLOYEE_HIERARCHY;

-- Q30.
/*
Write a query to return employees with lowest salary in each department;
*/
WITH RANK_DEPT_SALARY AS
(
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, SALARY, RANK() OVER(PARTITION BY DEPT_ID ORDER BY SALARY) RANKED_DEPT_SALARY
FROM EMPLOYEES
)
SELECT EMPLOYEE_ID, FIRST_NAME, LAST_NAME, SALARY
FROM RANK_DEPT_SALARY
WHERE RANKED_DEPT_SALARY = 1;

-- Bonus Questions
-- Q31.
/*
Is there anything wrong with the SQL statement below?

SELECT customer_id, sum(amount) revenue
FROM customer_tranx
GROUP BY customer_id
WHERE sum(amount) > 20000;
*/
--1. WHERE clause should be used before a GROUP BY
--2. Aggregate functions shouldn't be used in a WHERE clause

-- Q32.
/*
Given that an employee table has details of about 50 employees with an ID ranging from 1 - 50, what is the appropriate operator in the query below to select details of all 
employees whose salary is above all employees with an ID above 40?

SELECT *

FROM EMPLOYEES E1

WHERE SALARY _____ (SELECT SALARY FROM EMPLOYEES E2 WHERE ID > 40);
*/
SELECT *
FROM EMPLOYEES E1
WHERE SALARY >ALL (SELECT SALARY FROM EMPLOYEES E2 WHERE ID > 40);

-- Q33.
/*
Is this query valid? If yes, what is the behaviour?

SELECT first_name, last_name, SALARY/(SELECT SUM(SALARY) FROM EMPLOYEES) 
FROM EMPLOYEES
WHERE SALARY/(SELECT SUM(SALARY) FROM EMPLOYEES) > 0.005;
*/
--Yes, the query is valid. It returns details of employees whose salary is above 0.5% of all employees salaries.

-- Q34.
/*
Given a table cust_tranx with 1,000,000 records, what is the result/behaviour of the query below 
and why?

SELECT SUM(1)
FROM cust_tranx;
*/
--The query returns 1,000,000. It sums 1 as a scalar value in 1 million places.

-- Q35.
/*
What is the behavior of the UPDATE statement below?

UPDATE EMPLOYEES
SET SALARY = (CASE WHEN ID > 3 THEN SALARY*2 END);
*/
--The query doubles the salary of employees with ID greater than 3 while the other employee salaries is replaced with NULL

-- Q36.
/*
What is the behavior of this query?

SELECT MAX(CASE WHEN SALARY > 300000 THEN 1 ELSE 0 END)
FROM EMPLOYEES;
*/
--This query is trying to check if there is any employee with salary above 300,000

-- Q37.
/*
What is the result of the query below?

SELECT NAME, SALARY
FROM EMPLOYEES
HAVING SALARY > 10000;
*/
--The query throws an error as the salary column is neither an aggregate or in a GROUP BY clause. A WHERE clause is appropriate in this case.

-- Q38.
/*
Given table TRANX having 50000 records, what is the result of the query below?

SELECT 2*COUNT(2), 2*SUM(2) FROM TRANX;
*/
--2*COUNT(2) = 2*50000 = 100000
--2*SUM(2) = 2*50000*2 = 200000

-- Q39.
/*
A phone call is considered an international call when the person calling is in a different country than the person receiving the call.

What percentage of phone calls are international? Round the result to 1 decimal.

Assumption:

The caller_id in phone_info table refers to both the caller and receiver.

phone_calls(caller_id, receiver_id, call_time)

phone_info(caller_id, country_id, network, phone_no)
*/
SELECT 
  ROUND(
    100.0 * (COUNT(CASE  WHEN pic.country_id <> pir.country_id THEN 1 ELSE NULL END) )
  / COUNT(*), 1) AS international_calls_pct
FROM phone_calls AS pc
LEFT JOIN phone_info AS pic
  ON pc.caller_id = pic.caller_id
LEFT JOIN phone_info AS pir
  ON pc.receiver_id = pir.caller_id;

-- Q40.
/*
Your team at JPMorgan Chase is soon launching a new credit card. You are asked to estimate how many cards you'll issue in the first month.

Before you can answer this question, you want to first get some perspective on how well new credit card launches typically do in their first month.

Write a query that outputs the name of the credit card, and how many cards were issued in its launch month. 
The launch month is the earliest record in the monthly_cards_issued table for a given card. Order the results starting from the biggest issued amount.

monthly_cards_issued(issue_year, issue_month, card_name, issued_amount)
*/
WITH card_launch AS (
SELECT 
  card_name,
  issued_amount,
  CAST(CONCAT_WS('-', issue_year, issue_month, 1)) AS issue_date,
  MIN(CAST(CONCAT_WS('-', issue_year, issue_month, 1))) OVER (PARTITION BY card_name) AS launch_date
FROM monthly_cards_issued
)
SELECT card_name, issued_amount
FROM card_launch
WHERE issue_date = launch_date
ORDER BY issued_amount DESC;