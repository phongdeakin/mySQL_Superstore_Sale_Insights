# mySQL_Superstore_Sale_Insights

Getting some insights from Superstore dataset with the below questions: 
1. Return the list of all unique products in each Sub-Category that have
- Product ID, Product name, Product Sub category, Product Price
- Product price = sales/quantity 
- Avg sub-category product price using unique product prices only in each sub-category (Not sales)
- A column saying that if product price is greater or less than AVG Sub-category price 

2. Using Orders table. Return the list of all unique customer in each region that have
- Region, Customer ID, Customer Name, Total Orders, Total Technology Sales, Total Office Supply Sales, Total Furniture Sales, Total Sales
- AVG Number Orders per customer, and AVG Total Sales per Customer in each region
- Max & Min Total Number Orders per customer, Max & Min Total Sales per Customer in each region
- Only keep customers that have either ONE of these condition
 	+ Total Number Orders = Min/Max Total Number Orders per customer in each region
 	+ Total Number Orders within the range of +/- 10% of AVG Number Orders per customer in each region

3. Get a full list of customers which has
- Monthly total revenue, total profit
- For each customer, get a rank for each month based on total Sales against all other customers in the same Segment
- For each customer, get the difference of Total Sales against the Top 1 Customer in the same Segment each month.
- For each customer, get the % growth of current month total sales compared to previous month total sales

4. Customer Retention Analysis. 
In one query, build a datasource that could answer following questions
- Customer spent on each order
- Customers who spent more than $1000 in total and did not buy anything in the last 180 days (Use 2017-12-30 as current day)
- How many customers have the Gap Days between 2 consecutive orders is more than 90 days?
- How many time one customer return after 90 days
- How much customer spent on the First order and the Last Orders
