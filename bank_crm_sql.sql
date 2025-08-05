show databases;

use bank_crm;

show tables;

select * from activecustomer;
select * from bank_churn;
select * from creditcard;
select * from customerinfo;
select * from exitcustomer;
select * from gender;
select * from geography;

-- xlsx to csv - import data done

DELETE FROM activecustomer
WHERE ActiveID =' ';

SET SQL_SAFE_UPDATES = 0
-- ---------------------

-- ----------------------------------- OBJECTIVE QUESTIONS -------------------------------------
-- 1. What is the distribution of account balances across different regions? (Visual answer in DOC  ) 
-- ------------------------
-- 2. Identify the top 5 customers with the highest Estimated Salary in the last quarter of the year


-- Changing column name to Bank_DOJ


alter table customerinfo rename column `Bank DOJ` to Bank_DOJ ;

alter table customerinfo
modify column Bank_DOJ date;

SELECT 
  surname, 
  QUARTER(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS Q,
  STR_TO_DATE(Bank_DOJ, '%d-%m-%Y') AS formatted_date
FROM customerinfo;


SELECT 
  CustomerId, 
  Surname, 
  EstimatedSalary, 
  STR_TO_DATE(Bank_DOJ, '%d-%m-%Y') AS Bank_DOJ
FROM customerinfo
WHERE QUARTER(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) = 4
ORDER BY EstimatedSalary DESC
LIMIT 5;
-- ---------------------
-- 3.	Calculate the average number of products used by customers who have a credit card;

select avg(NumofProducts) as Avg_numof_products
from bank_churn
where HasCrCard = 1;

-- -----------------------
-- 4.Determine the churn rate by gender for the most recent year in the dataset.(POWER BI using measure)
-- -----------------------

-- 5.	Compare the average credit score of customers who have exited and those who remain;

select ec.ExitCategory, avg(bc.CreditScore) as Avg_Creditscore
from bank_churn bc
join exitcustomer ec on bc.exited=ec.exitId 
group by ec.ExitCategory;

-- ------------------------
-- 6.Which gender has a higher average estimated salary, and how does it relate to the number of active accounts?

select GenderCategory,round(avg(EstimatedSalary),2) as Avg_estimated_sal
from customerinfo ci
join gender g on ci.genderID=g.genderID
group by GenderCategory;

select GenderCategory,round(avg(EstimatedSalary),2) as Avg_estimated_sal, count(bc.CustomerId) as Active_Customers
from customerinfo ci
join gender g on ci.genderID=g.genderID
join bank_churn bc on bc.customerID=ci.customerID
join activecustomer ac on  bc.IsActiveMember=ac.ActiveID
where ActiveCategory='Active Member'
group by GenderCategory;

-- --------------------------
-- 7.	Segment the customers based on their credit score and identify the segment with the highest exit rate;

with creditscoresegment as (
    select CustomerId, Exited,
    case when creditscore between 781 and 850 then 'Excellent'
        when creditscore between 701 and 780 then 'Very Good'
        when creditscore between 611 and 700 then 'Good'
        when creditscore between 510 and 610 then 'Fair' 
        else 'Poor'
    end as CreditScoreSegment
    from bank_churn)

select CreditScoreSegment,
    avg(case when Exited = 1 then 1 else 0 end) as Exit_Rate
from creditscoresegment
group by creditscoresegment
order by exit_rate desc
limit 1;

-- ----------------------------
-- 8.Find out which geographic region has the highest number of active customers with a tenure greater than 5 years.


select g.GeographyLocation, count(b.CustomerId) as Active_Customers
from geography g
join customerinfo c on g.geographyid = c.geographyid
join bank_churn b on c.customerid = b.customerid
where b.tenure > 5 and b.IsActiveMember=1
group by g.geographylocation
order by active_customers desc
limit 1;
-- ------------------------------
-- 9. What is the impact of having a credit card on customer churn, based on the available data?(visual answer) 
-- 10. For customers who have exited, what is the most common number of products they have used?(visual answer ) 
-- ---------------------------------
-- 11.Examine the trend of customers joining over time and identify any seasonal patterns (yearly or monthly) 
		-- Prepare the data through SQL and then visualize it.

SELECT 
  YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS join_year,
  COUNT(*) AS customers_joined
FROM customerinfo
GROUP BY YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y'));

SELECT  
  YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS Year,
  MONTH(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')) AS Month,
  COUNT(*) AS Customers_Joined
FROM customerinfo 
GROUP BY 
  YEAR(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y')),
  MONTH(STR_TO_DATE(Bank_DOJ, '%d-%m-%Y'))
ORDER BY 
  Year, Month;
-- ------------------------------------
-- 12.Analyze the relationship between the number of products and the account balance for customers who have exited.(DOC has the answer)
-- 13.Identify any potential outliers in terms of balance among customers who have remained with the bank.(DOC has the answer)
-- 14.How many different tables are given in the dataset, out of these tables which table only consists of categorical variables?(DOC has the answer)
-- ----------------------------------------
-- 15.	 Using SQL, write a query to find out the gender-wise average income of males and females in each geography id. 
		-- Also, rank the gender according to the average value;

select geo.GeographyLocation,  GenderCategory,round(avg(c.estimatedsalary),2) as Avg_salary,
rank() over (partition by GeographyLocation order by avg(c.EstimatedSalary) desc) as 'Rank'
from customerinfo c
join geography geo on c.geographyid = geo.geographyid
join gender gn on gn.genderid=c.genderid
group by geo.geographylocation, GenderCategory
order by geo.geographylocation;
-- ---------------------------

-- 16.	Using SQL, write a query to find out the average tenure of the people who have exited in each age bracket (18-30, 30-50, 50+).

select case when age between 18 and 30 then 'Adults'
	when age between 31 and 50 then 'Middle-aged'
    else 'Old-aged' end as Age_brackets,
	avg(b.tenure) as Avg_tenure
from customerinfo c
join bank_churn b on c.customerid = b.customerid
where b.exited = 1
group by Age_brackets
order by Age_brackets;

-- ---------------------
 
-- 17. Is there any direct correlation between salary and the balance of the customers? And is it different for people who have exited or not?(Ans in DOC)
-- 18. Is there any correlation between the salary and the Credit score of customers?(Ans in DOC ) 
-- -------------------

-- 19.	Rank each bucket of credit score as per the number of customers who have churned the bank.

with creditscoresegment as (
    select customerid, exited,
    case when creditscore between 781 and 850 then 'excellent'
        when creditscore between 701 and 780 then 'very good'
        when creditscore between 611 and 700 then 'good'
        when creditscore between 510 and 610 then 'fair' else 'poor'
    end as creditscoresegment
    from bank_churn)

select creditscoresegment,
    count(case when exited = 1 then 1 else 0 end) as churned_cnt
from creditscoresegment
group by creditscoresegment
order by churned_cnt desc;
-- ----------------

-- 20.According to the age buckets find the number of customers who have a credit card.Also retrieve those buckets that have lesser than average number of credit cards per bucket;

with creditinfo as (
    select case when age between 18 and 30 then 'Adult'
		when age between 31 and 50 then 'Middle-aged'
		else 'Old-aged' end as agebrackets,
		count(c.customerid) as CrCard_holders
    from customerinfo c
    join bank_churn b on c.customerid = b.customerid
    where b.hascrcard = 1  
    group by agebrackets
)
select *
from creditinfo
where CrCard_holders < (
    select avg(CrCard_holders) 
    from creditinfo	);


-- ------------------------------
-- (Ans in DOC) :
--  21.Rank the Locations as per the number of people who have churned the bank and average balance of the customers.
--  22.As we can see that the “CustomerInfo” table has the CustomerID and Surname, now if we have to join it with a table where the primary key is also a combination of CustomerID and Surname, come up with a column where the format is “CustomerID_Surname”.

-- ------------------------------

-- 23.	Without using “Join”, can we get the “ExitCategory” from ExitCustomers table to Bank_Churn table? If yes do this using SQL.

select customerid, creditscore, tenure, balance, numofproducts, hascrcard, isactivemember, exited,
    (select ExitCategory from exitcustomer ec where bc.exited = ec.exitID) as ExitCategory
from bank_churn bc;

-- -------------------

-- 24.Were there any missing values in the data, using which tool did you replace them and what are the ways to handle them?(Ans in DOC) 

-- --------------------
-- 25.	Write the query to get the customer IDs, their last name, and whether they are active  or not for the customers whose surname ends with “on”;

select c.CustomerId, c.Surname as Last_name,  
    case when b.isactivemember = 1 then 'active' 
    else 'inactive' end as activitystatus
from customerinfo c
join bank_churn b on c.customerid = b.customerid
where c.surname like '%on'
order by c.surname;

-- ---------------------------------

-- 26.	Can you observe any data disrupency in the Customer’s data? As a hint it’s present in the IsActiveMember and Exited columns.One more point to consider is that the data in the Exited Column is absolutely correct and accurate.

select * from bank_churn b join customerinfo c on b.customerid = c.customerid
where b.exited =1 and b.isactivemember =1;

-- ------------------------------------

-- ----------------------------------------------------------- SUBJECTIVE QUESTIONS ------------------------------------------------------------------------------------------ 
-- questions  1 to 8 , 10,11,12,13 are answered in the DOC file using power bi for analysis and visuals ;
-- -------------------------------------

-- 9.	Utilize SQL queries to segment customers based on demographics and account details.

select GeographyLocation, 
    case when estimatedsalary < 50000 then 'Low'
        when estimatedsalary < 100000 then 'Medium'
        else 'High'end as Income_Segment,
		GenderCategory ,
    count(c.customerid) as NumberofCustomers
from customerinfo c
join geography g on c.geographyid = g.geographyid
join gender gn on c.genderid=gn.genderid
group by  geographylocation, Income_Segment, GenderCategory
order by geographylocation;

-- ------------------------------------
-- 14.	In the “Bank_Churn” table how can you modify the name of the “HasCrCard” column to “Has_creditcard”?


alter table Bank_Churn
rename column HasCrCard to Has_creditcard ;

select *
from bank_churn;

alter table Bank_Churn
rename column Has_creditcard to HasCrCard ;

-- ------------------------------------------------------------------------- END ----------------------------------------------------------------------------------------


