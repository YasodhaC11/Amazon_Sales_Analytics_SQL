/*********************AMAZON SALES AND CUSTOMER ANALYTICS USING MYSQL *********************************
Objective: To explore and analyze Amazon sales data to uncover patterns in customer behavior, 
sales trends, and product performance using MYSQL.
*/
create database Amazondb;
drop table if exists Amazon;
create table Amazon(
invoice_id varchar(30) NOT NULL,
branch varchar(5) NOT NULL,
city varchar(30) NOT NULL,
customer_type varchar(30) NOT NULL,
gender varchar(10) NOT NULL,
product_line varchar(100) NOT NULL,
unit_price decimal(10,2) NOT NULL,
quantity int NOT NULL,
VAT decimal(6,4) NOT NULL,
total decimal(10,2) NOT NULL,
Purchase_date date NOT NULL,
time time NOT NULL,
payment_method varchar(15) NOT NULL,
cogs decimal(10,2) NOT NULL,
gross_margin_percentage decimal(11,9) NOT NULL,
gross_income decimal(10,2) NOT NULL,
rating decimal(2,1) NOT NULL
);

/*---------------------************ DATA WRANGLING ************-------------------------------

This is the first step where we inspect the dataset to identify missing or NULL values. 
Since each column in our table is defined with NOT NULL, such values are already filtered 
out at the data entry stage.

-- -------------------************FEATURE ENGINEERING************-------------------------------*/
-- 1. CREATING A NEW COLUMN TIME_OF_DAY AND ADDING ITS VALUES
alter table amazon
add column time_of_day varchar(10);

/*In safe update mode, MySQL prevents accidental updates to the whole table without a WHERE clause.
-- Hence keeping sql_safe_update as 0. otherwise we can also keep Dummy where condition.*/
set SQL_SAFE_UPDATES = 0;

update amazon
set time_of_day=case
	when hour(time) between 6 and 11 then "Morning"
    when hour(time) between 12 and 15 then "Afternoon"
    when hour(time) between 16 and 19 then "Evening"
    else "Night"
end;


-- 2.CREATING A NEW COLUMN DAY_NAME AND ADDING ITS VALUES
/*Added a new column named day_name that stores the day of the week (Mon, Tue, Wed, etc.) 
for each transaction. This helps us understand which days are busiest for each branch*/

alter table amazon
add column day_name varchar(5);

update amazon
set day_name=date_format(Purchase_date,"%a");

-- 3.CREATING A NEW COLUMN MONTH_NAME AND ADDING ITS VALUES
alter table amazon
add column month_name varchar(5);

update amazon
set month_name=date_format(Purchase_date,"%b");

set SQL_SAFE_UPDATES = 1;
/* Turning safe updates back on.
================================================================================================
-- -------------------************ PRODUCT ANALYSIS ************-------------------------------*/

-- 1.To find out which product lines make the most profit.
select product_line,total_gross_income,
		rank() over (order by total_gross_income desc) as Top_performing
from (
	select product_line,round(sum(gross_income),2) as total_gross_income from amazon 
	group by product_line
) as gross_income_per_productline;
-- Insights : Health and beauty has the highest gross income, making it the top-performing product line.

-- 2.To find out avg rating per product line.
select product_line,
	round(avg(rating),2) as avg_rating from amazon
group by product_line
order by avg_rating desc;
-- Insights: Food and beverages has the highest average rating, indicating better customer satisfaction in this category.

-- 3.To identify the top-performing product line (based on gross income) in each city
with Ranked_products as(
select city,product_line,sum(gross_income) as total_profit,
	row_number() over(partition by city order by sum(gross_income) desc) as ranks
 from amazon 
group by city,product_line
)
select city,product_line,total_profit from ranked_products where ranks=1
order by total_profit desc;
/* Insights: Naypyitaw: Highest profit from Food and beverages-indicates a thriving food consumption market.
Yangon: Home and lifestyle-indicates consistent customer demand for lifestyle and home products.
Mandalay: Health and Beauty-this may suggest strong demand for wellness-related products.*/

-- ================================================================================================
-- -------------------************ SALES ANALYSIS ************-------------------------------
-- 1.To find out monthly sales
select product_line,date_format(purchase_date,"%Y-%m") as purchase_month,
    count(invoice_id) as No_of_transactions,sum(vat) as monthly_vat,
    sum(total) as total_purchase from amazon
group by product_line,purchase_month
order by product_line,purchase_month;

/* Insights: Top-performing product lines by Total Purchase (Revenue):
 January 2019:Sports and Travel – ₹21,667.09
 February 2019:Food and Beverages – ₹20,000.39
 March 2019:Home and Lifestyle – ₹20,932.81   */

-- 2. To find out which day of week was busiest in each branch
with ranked_days as(
select day_name,branch,sum(total) as total_purchase,
row_number() over(partition by branch order by sum(total) desc) as ranks
 from amazon
group by day_name,branch
)
select branch,day_name,total_purchase from ranked_days where ranks=1;

/*Insights: Saturday is the busiest day for branches B and C, while Sunday is the peak day for Branch A. 
This indicates that weekends generally perform better, but customer behavior varies slightly by location. 
Stores should optimize staffing and promotions accordingly."
=================================================================================================*/
