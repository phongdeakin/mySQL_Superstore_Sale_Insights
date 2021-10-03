
-- 1. Return the list of all unique products in each Sub-Category that have
-- - Product ID, Product name, Product Sub category, Product Price
-- - Product price = sales/quantity 
-- - Avg sub-category product price using unique product prices only in each sub-category (Not sales)
-- - A column saying that if product price is greater or less than AVG Sub-category price 

with product as
(select 
	Product_ID
	, Product_Name
    , Sub_Category
    , round(avg((Sales/(1-discount))/quantity),2) as product_price
from phong.orders
group by Product_ID
	, Product_Name
    , Sub_Category
)
, category as
(select sub_category
	, avg(product_price) as avg_sub_category
from product
group by sub_category
)
select 
	p.product_id
	, product_name
    , p.sub_category
    , p.product_price
    , c.avg_sub_category
    , if(p.product_price >= avg_sub_category, 'Higher', 'Lower') as comparison
from product as p
	left join category as c
		on p.sub_category = c.sub_category
;
-- 2. Using Orders table. Return the list of all unique customer in each region that have
-- - Region, Customer ID, Customer Name, Total Orders, Total Technology Sales, Total Office Supply Sales, Total Furniture Sales, Total Sales
-- - AVG Number Orders per customer, and AVG Total Sales per Customer in each region
-- - Max & Min Total Number Orders per customer, Max & Min Total Sales per Customer in each region
-- - only keep customers that have either ONE of these condition
-- 	+ Total Number Orders = Min/Max Total Number Orders per customer in each region
-- 	+ Total Number Orders within the range of +/- 10% of AVG Number Orders per customer in each region

-- ctrl + Space
with customer as (
select customer_ID
	, customer_Name
    , region
    , count(distinct order_id) as total_orders
    , sum(sales) as total_sales
    , sum(case when category = 'Technology' then sales end) as tech_sales
    , sum(case when category  = 'Office Supplies' then sales end) as OS_sales
    , sum(if(category = 'Furniture', sales,null)) as fur_sales
from phong.orders
group by customer_ID
	, customer_Name
    , region
)
,avg_region as (
select region
	, count(distinct order_id)/ count(distinct customer_id) as orders_per_customer
    , sum(sales)/ count(distinct customer_id) as sales_per_customer
from phong.orders
group by region
)
, min_max as (
select region
	, max(total_orders) as max_total_orders
    , min(total_orders) as min_total_orders
    , max(total_sales) as max_total_sales
    , min(total_sales) as min_total_sales
from customer
group by region
)
select 
	c.customer_id
    , c.region
    , c.total_orders
    , c.total_sales
    , c.tech_sales
    , c.OS_sales
    , c.fur_sales
    , ar.orders_per_customer
    , ar.sales_per_customer
    , mm.max_total_orders
    , mm.min_total_orders
    , mm.max_total_sales
    , mm.min_total_sales
from customer as c
	left join avg_region as ar
		on c.region = ar.region
	left join min_max as mm
		on c.region = mm.region
where c.total_orders = min_total_orders
	or c.total_orders = max_total_orders
    or c.total_orders between ar.orders_per_customer * 0.9 and ar.orders_per_customer * 1.1
;
select *
from phong.orders
;
-- 3. Get a full list of customers which has
-- - Monthly total revenue, total profit
-- - For each customer, get a rank for each month based on total Sales against all other customers in the same Segment
-- - For each customer, get the difference of Total Sales against the Top 1 Customer in the same Segment each month.
-- - For each customer, get the % growth of current month total sales compared to previous month total sales

/*=> Table should have Customer_ID, Name, Segment, Month, Total Sales, Total Profit, 
monthly sales, monthly sales rank, monthly sales difference, Pre-month sales, Growth percentage
*/

# Option 1: Using CTE 
with month_base as (
select Customer_ID
	, Customer_Name
    , Segment
    , date_format(order_date, '%Y-%m-01') as month_date
    , sum(Sales) as total_sales
    , sum(Profit) as total_profit
    , count(distinct order_id) as number_of_orders
--     Rank customers by monthly sales in the same Segment
    #, row_number() over (partition by Segment, date_format(order_date, '%Y-%m-01') order by sum(Sales) desc) as monthly_sales_rank 
from phong.orders
group by Customer_ID
	, Customer_Name
    , Segment
    , date_format(order_date, '%Y-%m-01')
)
select *
	, row_number() over (partition by segment, month_date order by total_sales desc) as sales_rank
# Top 1 Monthly Sales in the same Segment
    , max(total_sales) over(partition by segment, month_date order by total_sales desc) as max_total_sales
# Another way to find Top 1
	# first_value(total_sales) over(partittion by segment, month_date order by total_sales desc) as max_total_sales
# Difference between Total sales of each customer and Top 1
    , (total_sales - max(total_sales) over (partition by segment, month_date order by total_sales desc)) as sales_difference
#  Top 1 Monthly Profit in the same Segment
    , max(total_profit) over (partition by segment, month_date order by total_profit desc) as max_total_profit
# Pre-month Total Sales
    , lag(total_sales, 1) over (partition by customer_id order by month_date asc) as pre_sales 
# % Growth of Current month compared to Pre Month (Round to 2 decimal places)
    , round((total_sales - lag(total_sales, 1) over (partition by customer_id order by month_date asc))/ (lag(total_sales, 1) over (partition by customer_id order by month_date asc)),2) as monthly_growth
from month_base    
;

-- 4. Customer Retention Analysis. 
-- In one query, build a datasource that could answer following questions
-- - Customer spent on each order
-- - Customers who spent more than $1000 in total and did not buy anything in the last 180 days (Use 2017-12-30 as current day and use Function to calculate 180 days)
-- - How many customers have the Gap Days between 2 consecutive orders more than 90 days?
-- - How many time one customer return after 90 days
-- - How much customer spent on the First order and the Last Orders

# Creating a base Table for querying other requirements.

with base as (

select customer_id
	, customer_name
	, order_id
    , order_date
    , sum(sales) as total_sales
from phong.orders
group by customer_id
	, order_id
    , order_date
)
select count(*)
 , count(distinct order_id)
from base
;

, min_max_order as (
select customer_id as customer_id1
	, max(order_date) as max_order_date
    , min(order_date) as min_order_date
    , datediff('2017-12-30',max(order_date)) as days_since_last_order
    from base
    group by customer_id
) 
, consecutive as (
select customer_id
	, order_id
    , order_date
    , lag(order_date) over (partition by customer_id order by order_date asc) as pre_order_date
    , datediff(order_date,(lag(order_date) over (partition by customer_id order by order_date asc))) as days_diff
    #, count(distinct if(days_diff >= 90, order_id, null)) over (partition by customer_id) as total_returns_after_90_days
    from base
)
, first_last_order as (
select base.customer_id
	, sum(case when base.order_date = mm.max_order_date then total_sales end)  last_order_sales
    , sum(case when base.order_date = mm.min_order_date then total_sales end) first_order_sales
from base
	left join min_max_order mm
		on mm.customer_id1 = base.customer_id
group by base.customer_id
)
select base.customer_id
	, base.customer_name
    , base.order_date
    , base.total_sales
    , mm.max_order_date
    , mm.min_order_date
    , mm.days_since_last_order
    , con.pre_order_date
    , con.days_diff
    , fl.last_order_sales
    ,fl.first_order_sales
from base
	left join min_max_order mm
		on base.customer_id = mm.customer_id1
    left join consecutive con
		on base.customer_id = con.customer_id
        and base.order_id = con.order_id         
    left join first_last_order fl
		on base.customer_id = fl.customer_id
;

-- select *,
-- 	count(if(days_diff >= 90, order_id, null)) over (partition by customer_id) as total_returns_after_90_days
-- from consecutive
