-- -------------------************ EXPLORATORY DATA ANALYSIS ************-------------------------------
-- 1.What is the count of distinct cities in the dataset?
Select count(distinct city) as city_count from amazon;

-- 2.For each branch, what is the corresponding city?
select branch,city from amazon
group by branch,city;

-- 3.What is the count of distinct product lines in the dataset?
select count(distinct product_line) as productline_count from amazon;

-- 4.Which payment method occurs most frequently?
select payment_method,count(payment_method) as How_frequent from amazon
group by payment_method 
order by how_frequent desc;

-- 5.Which product line has the highest sales?
select  product_line,sum(total) as total_sales from amazon
group by product_line
order by total_sales desc
limit 1;

-- 6.How much revenue is generated each month?
select month_name,sum(total) as monthly_revenue from amazon
group by month_name
order by monthly_revenue desc;

-- 7.In which month did the cost of goods sold reach its peak?
select month_name,sum(cogs) as peak_cogs from amazon
group by month_name
order by peak_cogs desc
limit 1;

-- 8.Which product line generated the highest revenue?
select  product_line,sum(total) as total_revenue from amazon
group by product_line
order by total_revenue desc
limit 1;

-- 9.In which city was the highest revenue recorded?
select  city,sum(total) as total_revenue from amazon
group by city
order by total_revenue desc
limit 1;

-- 10.Which product line incurred the highest Value Added Tax?
select product_line, sum(vat) as total_vat from amazon
group by product_line 
order by total_vat desc
limit 1;

-- 11.For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

with product_sales as (
    select product_line, sum(total) as total_sales
    from amazon
    group by product_line
),
avg_sales as (
    select avg(total_sales) as avg_sales_val from product_sales
)
select *, 
    case 
        when total_sales > avg_sales_val then 'Good'
        else 'Bad'
    end as performance
from product_sales, avg_sales;

-- 12.Identify the branch that exceeded the average number of products sold.
SELECT branch, AVG(quantity) AS avg_qty_sold
FROM amazon
GROUP BY branch
HAVING AVG(quantity) >(
select avg(avg_branch_qty) from(select branch,avg(quantity) as avg_branch_qty from amazon
group by branch) as sub);

/*Calculates the average quantity sold per branch.
Then compares each branch’s average with the overall average of branch-level averages.
Only those branches performing above average are returned.*/


-- 13.Which product line is most frequently associated with each gender?
select product_line,gender,purchase_count,rn
from (select product_line,gender,count(*) as purchase_count,
row_number() over(partition by gender order by count(*) desc) as rn from amazon
group by product_line,gender

) as ranked
where rn =1;
/*count(*): counts the number of records (purchases).
partition by gender: separates data by each gender.
order by count(*) DESC: ranks product lines from most to least frequent.
row_number()=1: selects only the top-ranked product line for each gender.*/

-- 14.Calculate the average rating for each product line.
select product_line,round(avg(rating),2) as avg_rating from amazon
group by product_line;

-- 15.Count the sales occurrences for each time of day on every weekday.
select day_name,time_of_day,count(invoice_id) as sales_count from amazon
where day_name in ("mon","tue","wed","thur","fri")
group by day_name,time_of_day
order by  
  CASE day_name
    when 'Mon' then 1
    when 'Tue' then 2
    when 'Wed' then 3
    when 'Thur' then 4
    when 'Fri' then 5
  END,
  time_of_day;


-- 16.Identify the customer type contributing the highest revenue.
select customer_type,sum(total) as sales_revenue from amazon
group by customer_type
order by sales_revenue desc;

-- 17.Determine the city with the highest VAT percentage.
select city,round(max((vat/total)*100),3) as vat_percentage from amazon
group by city
order by vat_percentage desc
LIMIT 1;

-- 18 Identify the customer type with the highest VAT payments.
select customer_type,sum(vat) as vat_paid from amazon
group by customer_type
order by vat_paid desc
limit 1;

-- 19.What is the count of distinct customer types in the dataset?
select count(distinct customer_type) as cus_type_count from amazon;

-- 20.What is the count of distinct payment methods in the dataset?
select count(distinct payment_method) as pay_method_count from amazon;

-- 21.Which customer type occurs most frequently?
select customer_type,count(*) as how_frequent from amazon
group by customer_type
order by how_frequent desc
limit 1;

-- 22.Identify the customer type with the highest purchase frequency.
select customer_type,count(invoice_id) as purchase_freq from amazon
group by customer_type
order by purchase_freq desc
limit 1;

-- 23.Determine the predominant gender among customers.
select gender,count(*) as gender_count from amazon
group by gender
order by gender_count desc
limit 1;

-- 24.Examine the distribution of genders within each branch.
select branch,gender,count(gender) as gender_count from amazon
group by branch,gender
order by branch;

-- 25.Identify the time of day when customers provide the most ratings.
select time_of_day, count(rating) as most from amazon
group by time_of_day
order by most desc;

-- 26.Determine the time of day with the highest customer ratings for each branch.
select branch,time_of_day,highest_branch_rating 
from (
	select branch,time_of_day,count(rating) as highest_branch_rating,
		rank() over (partition by branch order by count(rating) desc) as rn
	from amazon
	group by branch,time_of_day
) as branch_rating
where rn=1

/*Groups the data by branch and time_of_day.
Counts the number of ratings (count(rating)).
Ranks the times per branch using RANK() to handle ties.
Filters to keep only the top-ranked (rn = 1) for each branch.*/;

-- 27.Identify the day of the week with the highest average ratings.
select day_name,round(avg(rating),2) as highest_avg_rating from amazon
group by day_name
order by highest_avg_rating desc
limit 1;

-- 28.Determine the day of the week with the highest average ratings for each branch.
select branch,day_name,highest_avg_rating 
from (
	select branch,day_name,round(avg(rating),2) as highest_avg_rating,
		rank() over (partition by branch order by avg(rating) desc) as rn
    from amazon
	group by branch,day_name
) as highest_rating
where rn = 1;
-- This shows which day performs best in customer satisfaction (rating-wise) per branch.
/*
CONCLUSION:Based on the analysis, we can conclude that customer buying behavior varies across 
branches and times of the day. Marketing efforts can be optimized by targeting peak hours and 
promoting high-profit product lines. Enhancing stock levels and staffing during weekends may 
improve customer satisfaction and revenue.*/
