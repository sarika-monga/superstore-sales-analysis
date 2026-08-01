CREATE TABLE Orders (
    row_id INT,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(50),
    city VARCHAR(50),
    state VARCHAR(50),
    postal_code VARCHAR(20),
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),
    sales DECIMAL(10,2),
    quantity INT,
    discount DECIMAL(5,2),
    profit DECIMAL(10,2)
);
-- Q1: Overall Business Snapshot
SELECT
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(SUM(profit)/SUM(sales)*100, 2) AS profit_margin_percent
FROM orders;
-- Q2: Region-wise Sales & Profit
SELECT region , 
SUM(sales) AS total_sales , 
SUM(profit) AS total_profit ,
ROUND(SUM(profit)/SUM(sales) *100 , 2) AS profit_margin 
FROM ORDERS
GROUP BY region
ORDER BY total_profit DESC;
-- Q3: Top 10 Products by Sales
SELECT product_name , 
SUM(sales ) AS total_sales,
SUM(quantity) AS unit_sold 
FROM Orders 
GROUP BY product_name 
ORDER BY total_sales DESC
LIMIT 10;
-- Q4: Category & Sub-Category Performance
SELECT category , sub_Category , 
SUM(SALES) AS total_sales,
SUM(profit) AS total_profit
FROM orders
GROUP BY category , sub_category 
ORDER BY total_profit DESC;

-- Q5: Loss-Making Products
SELECT
    product_name,
    category,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    AVG(discount) AS avg_discount
FROM orders
GROUP BY product_name, category
HAVING SUM(profit) < 0
ORDER BY total_profit ASC;
-- Q6: Discount vs Profit Relationship
SELECT
    discount,
    COUNT(*) AS order_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM orders
GROUP BY discount
ORDER BY discount;
- Q7: Monthly Sales Trend
SELECT
    TO_CHAR(order_date, 'YYYY-MM') AS month,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM orders
GROUP BY TO_CHAR(order_date, 'YYYY-MM')
ORDER BY month;
 
-- Q8: Customer Segment Analysis
SELECT
    segment,
    COUNT(DISTINCT customer_id) AS unique_customers,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM orders
GROUP BY segment
ORDER BY total_sales DESC;
 
-- Q9: Top 10 Customers by Sales
SELECT
    customer_name,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit
FROM orders
GROUP BY customer_name
ORDER BY total_sales DESC
LIMIT 10;
 
-- Q10: Shipping Mode Analysis (Avg Delivery Time)
SELECT
    ship_mode,
    COUNT(*) AS total_orders,
    AVG(ship_date - order_date) AS avg_delivery_days
FROM orders
GROUP BY ship_mode
ORDER BY avg_delivery_days;
 

-- WINDOW FUNCTIONS

 
-- Q11: Rank Products within Each Category by Sales
SELECT
    category,
    product_name,
    SUM(sales) AS total_sales,
    RANK() OVER (PARTITION BY category ORDER BY SUM(sales) DESC) AS rank_in_category
FROM orders
GROUP BY category, product_name
ORDER BY category, rank_in_category;
 
-- Q12: Running Total - Cumulative Sales Over Time
SELECT
    order_date,
    SUM(sales) AS daily_sales,
    SUM(SUM(sales)) OVER (ORDER BY order_date) AS cumulative_sales
FROM orders
GROUP BY order_date
ORDER BY order_date;
 
 

-- ADVANCED BUSINESS INTELLIGENCE QUERIES
 
-- Q13: Year-over-Year Sales Growth
WITH yearly_sales AS (
    SELECT
        EXTRACT(YEAR FROM order_date) AS year,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY EXTRACT(YEAR FROM order_date)
)
SELECT
    year,
    total_sales,
    LAG(total_sales) OVER (ORDER BY year) AS prev_year_sales,
    ROUND(
        (total_sales - LAG(total_sales) OVER (ORDER BY year))
        / LAG(total_sales) OVER (ORDER BY year) * 100, 2
    ) AS yoy_growth_percent
FROM yearly_sales
ORDER BY year;
 
-- Q14: Top 3 Products in Each Sub-Category
WITH ranked_products AS (
    SELECT
        sub_category,
        product_name,
        SUM(sales) AS total_sales,
        DENSE_RANK() OVER (PARTITION BY sub_category ORDER BY SUM(sales) DESC) AS rank
    FROM orders
    GROUP BY sub_category, product_name
)
SELECT * FROM ranked_products
WHERE rank <= 3
ORDER BY sub_category, rank;
 
-- Q15: Customer Segmentation by Lifetime Value
WITH customer_value AS (
    SELECT
        customer_id,
        customer_name,
        COUNT(DISTINCT order_id) AS total_orders,
        SUM(sales) AS lifetime_value,
        SUM(profit) AS lifetime_profit
    FROM orders
    GROUP BY customer_id, customer_name
)
SELECT
    *,
    CASE
        WHEN lifetime_value >= 5000 THEN 'High Value'
        WHEN lifetime_value >= 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS customer_tier
FROM customer_value
ORDER BY lifetime_value DESC;
 
-- Q16: 3-Month Moving Average of Sales
WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', order_date) AS month,
        SUM(sales) AS total_sales
    FROM orders
    GROUP BY DATE_TRUNC('month', order_date)
)
SELECT
    month,
    total_sales,
    ROUND(AVG(total_sales) OVER (
        ORDER BY month
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_3month
FROM monthly_sales
ORDER BY month;
 
-- Q17: Discount Impact Analysis (Bucketed)
SELECT
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low (0-20%)'
        WHEN discount <= 0.4 THEN 'Medium (20-40%)'
        ELSE 'High (>40%)'
    END AS discount_bucket,
    COUNT(*) AS order_count,
    SUM(sales) AS total_sales,
    SUM(profit) AS total_profit,
    ROUND(AVG(profit), 2) AS avg_profit_per_order
FROM orders
GROUP BY
    CASE
        WHEN discount = 0 THEN 'No Discount'
        WHEN discount <= 0.2 THEN 'Low (0-20%)'
        WHEN discount <= 0.4 THEN 'Medium (20-40%)'
        ELSE 'High (>40%)'
    END
ORDER BY total_profit DESC;
 
-- Q18: Customer Retention - Repeat vs One-Time Customers
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM orders
    GROUP BY customer_id
)
SELECT
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,
    COUNT(*) AS num_customers
FROM customer_orders
GROUP BY
    CASE
        WHEN order_count = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END;
 
-- Q19: Profitability Percentile Rank by State
SELECT
    state,
    SUM(profit) AS total_profit,
    ROUND(PERCENT_RANK() OVER (ORDER BY SUM(profit))::numeric, 2) AS percentile_rank
FROM orders
GROUP BY state
ORDER BY total_profit DESC;