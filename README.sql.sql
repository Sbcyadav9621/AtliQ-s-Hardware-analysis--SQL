# AtliQ-s-Hardware-analysis--SQL
select top 1 * from dim_customer
select top 1 * from dim_product
select top 1 * from fact_gross_price
select top 1 * from fact_manufacturing_cost
select top 1 * from fact_pre_invoice_deductions
select top 1 * from fact_sales_monthly

-- Compare no.of customers across regions or channles?
### Region wise no.of customers
SELECT region,
      count(customer_code) as no_of_customers
FROM dim_customer
GROUP BY region
ORDER BY no_of_customers desc;

### Channel wise no.of customers:
SELECT channel,
      COUNT(customer_code) as no_of_customers
FROM dim_customer
GROUP BY channel
ORDER BY no_of_customers desc;

-- No.of products per category
SELECT category,
      COUNT(product) as no_products
FROM dim_product
GROUP BY category
ORDER BY no_products;

-- Product categories where the no.of products offered are more then 15
SELECT  category,
      COUNT(product) as no_of_products
FROM dim_product
GROUP BY category
HAVING count(product)>15
ORDER BY no_products desc;

-- List all products labeled as "premium"
SELECT *
FROM dim_product
WHERE Variant like "Premium%"

-- Monthly Sales Trend in FY2021, Also show the month names
SELECT MONTH(date) as Month_No,
      FORMAT(date,'MMMM') as Month_Name,
      SUM(sold_quantity) as total_sales
FROM fact_sales_monthly
WHERE fiscal_year = 2021
GROUP BY MONTH(date),FORMAT(date,'MMMM')
ORDER BY MONTH(date) ASC, total_sales DESC:

-- TOP-5 Costliest products in 2021
SELECT top 5 product_code, 
            MAX(manufacturing_cost) as high_cost
FROM fact_manufacturing_cost
WHERE cost_year = 2021
GROUP BY product_code
ORDER BY high_cost desc;

-- Find the Total Revenue(Sales) & Tota Profit
-- Calcuating Total Revenue
SELECT SUM(sum_sold_quantity * gp.gross_price * (1-pre_invoice_discount_pct)) as Total_Revenue
FROM fact_gross_price as gp
JOIN fact_sales_monthly as sm
ON gp.product_code = sm.product_code AND gp.fiscal_year = sm.fiscal_year
JOIN fact_pre_invoice_deductions as d
ON d.customer_code = sm.customer_code AND d.fiscal_year = sm.fiscal_year

-- Calculating Total Profit
SELECT 
      SUM((gross_price * (1-pre_invoice_discount_pct)-manufacturing_cost) * sold_quantity) as Total_profit
FROM fact_manufacturing_cost as mfc
JOIN fact_gross_price as gp
ON mfc.product_code = gp.product_code
JOIN fact_sales_monthly as sm
ON gp.fiscal_year = sm.fiscal_year AND gp.product_code = sm.product_code
JOIN fact_pre_invoice_deductions as d
ON d.customer_code = sm.customer_code AND d.fiscal_year = sm.fiscal_year

-- Top 3 products with maximum sold quantities for each year
SELECT *
FROM (
      SELECT DATEPART(Year,date) as years,
                  product_code, 
                  SUM(sold_quanitity) as Max_qty,
                  DENSE_RANK() OVER(PARTITION BY DATEPART(YEAR,date) ORDER BY Max_qty DESC) as Ranks
      FROM fact_sales_monthly
      GROUP BY DATEPART(YEAR,date),product_code
      ) as t
      WHERE Ranks <=3;

-- 2nd approach using 
SELECT *
FROM (SELECT *,
            DENSE_RANK() OVER(PARTITION BY years ORDER BY max_sales DESC) as Ranks
      FROM(
            SELECT product_code,
                  DATEPART(YEAR,date) as years,
                  SUM(sold_quantity) as Max_Sales
            FROM fact_sales_monthly
            GROUP BY product_code, DATEPART(YEAR,date)
       ) as t1
      )as t2)
Where ranks<=3

-- Products with Maximum Manufacturing Cost in FY2021
SELECT product_code,
      MAX(manufacturing_cost) as Max_Mfcost
FROM fact_manufacturing_cost
WHERE cost_year = 2021
GROUP BY product_code
ORDER BY Max_Mfcost desc;

---2nd approach--------
SELECT *
FROM fact_manufacturing_cost
WHERE manufacturing_cost = (
                              SELECT MAX(manufacturing_cost) as max_cost
                              FROM fact_manufacuring_cost
                              WHERE cost_year = 2021)

-- Products priced above average in 2021
SELECT *
FROM fact_gross_price
WHERE gross_price > fiscal_year = 2021 AND (
                                                SELECT AVG(gross_price) as avg_price
                                                FROM fact_gross_price
                                                WHERE fiscal_year = 2021
                                          ) 

--- Products with higher Manugacturing Cost then the Gross Price
SELECT a.product_code,
      g.gross_price,
      b.manufacturing_cost
FROM fact_gross_price as a
JOIN fact_manufactruing_cost as b
ON  a.product_code = b.product_code AND a.fiscal_year = b.cost_year
WHERE b.manufacturing_cost > a.gross_price

--- Product with higher manufacturing cost than the Average Gross Price
SELECT DISTINCT(product_code)
FROM fact_manufacturing_cost as b
WHERE manufacturing_cost > (SELECT AVG(gross_price)
                            FROM fact_gross_price)

-- Customers who purchased high priced products?
WITH top_10_products AS(
                        SELECT TOP 10 product_code,
                              MAX(gross_price) AS max_price
                        FROM fact_gross_price
                        GROUP BY product_code
                        ORDER BY MAX(gross_price) DESC
                        )
SELECT DISTINCT(customer_code)
FROM fact_sales_monthly
WHERE product_code IN (SELECT product_code
                        FROM top_10_products)

--- 2nd approach using Subquery----
SELECT customer_code
FROM fact_sales_monthly
WHERE product_code IN (
                        SELECT top 10 product_code
                        FROM fact_gross_price
                        GROUP BY product_code
                        ORDER BY MAX(gross_price)DESC)

# Customer Profitability Analysis:
-- Which customer provided the highest profit in fiscal year 2021?
SELECT TOP 5 d.customer_code,
      SUM((gross_price * (1-pre_invoice_discount_pct) - manufacturing_cost) * sold_quantity) as Profit
FROM fact_manufacturing_cost as m
INNER JOIN fact_gross_price as g
ON m.product_code = g.product_code AND m.cost_year = g.fiscal_year
INNER JOIN fact_sales_monthly as s
ON g.product_code = s.product_code AND g.fiscal_year = s.fiscal_year
INNER JOIN fact_pre_invoice_deductions as d
ON d.customer_code = s.customer_code
WHERE g.fiscal_year = 2021
GROUP BY d.customer_code
ORDER BY Profit desc

-- what is the total quantity sold across different sales channels in 2021?
SELECT a.channel as Sales_Channel,
      SUM(b.sold_quantity) as Total_Qty
FROM dim_customer as a
INNER JOIN fact_sales_monthly as b
ON a.customer_code = b.customer_code
WHERE fiscal_year = 2021
GROUP BY a.channel
ORDER BY Total_Qty DESC

--which regions are generating high sales volumes and low revenue per unit?
SELECT Region,
      Sales_volume,
      Total_revenue/Sales_volume as Revenue_per_Unit
FROM (Select cust.region as Region,
             SUM(sold_quantity) as Sales_volume,
             SUM(gross_price * sold_quantity * (1-pre_invoice_discount_pct)) as Total_revenue
      FROM fact_manufacturing_cost as m
      INNER JOIN fact_gross_price as g
      ON m.product_code = g.product_code AND m.cost_year = g.fisal_year
      INNER JOIN fact_sales_monthly as s
      ON g.product_code = s.product_code AND g.fisal_year = s.fiscal_year
      INNER JOIN fact_pre_invocie_deductions as d
      ON d.customer_code = s.customer_code AND d.fiscal_year = s.fiscal_year
      INNER JOIN dim_customer as cust
      ON cust.customer_code = d.customer_code
      GROUP BY cust_region) as x
      ORDER BY Sales_volume DESC, Revenue_per_Unit 

-- Which is the most profitable product?
WITH Profit_products as
      (  SELECT c.product_code as product_code,
                  SUM((g.gross_price - c.manufacturing_cost) * s.sold_quantity) as Total_profit
         FROM fact_manufacturing_cost as c
         INNER JOIN fact_gross_price as g
         ON c.product_code = g.product_code AND c.cost_year = g.fiscal_year
         INNER JOIN fact_sales_monthly as s
         ON c.product_code = s.product_code AND c.cost_year = s.fiscal_year
          GROUP BY c.product_code
      )
SELECT t.product_code, t.product
FROM dim_product as t
JOIN (SELECt TOP 1 product_code
      FROM Profit_products
      ORDER BY Total_profit desc) as p
ON t.product_code = p.product_code


--Which customer receive the highest average pre-invoice discount, and how does it affect their gross revenue?
SELECT d.customer_code,
      SUM(gross_price * sold_quantity) as Revenue,
      AVG(d.pre_invoice_discount_pct) as Avg_Discount
FROM fact_gross_price as gp
INNER JOIN fact_sales_monthly as s
ON gp.fiscal_year = s.fiscal_year AND gp.product_code = s.product_code
INNER JOIN fact_pre_invoice_deductions as d
ON d.customer_code = s.customer_code
GROUP BY d.customer_code
ORDER BY Avg_Discount DESC

-- Which is the most profitable product
WITH Profit_Products as
      (
       SELECT c.product_code as product_code,
              SUM((g.gross_price - c.manuafacturing_cost) * s.sold_quantity) as Total_profit
       FROM fact_manufacturing_cost as c
       INNER JOIN fact_gross_price as g
       ON c.product_code = g.product_code AND c.cost_year = g.fiscal_year
       INNER JOIN fact_sales_monthly as s
       ON c.product_code = s.product_code AND c.cost_year = s.fiscal_year
       GROUP BY c.product_code
      )
SELECT t.product_code,
       t.product
FROM dim_product as t
JOIN (
      SELECT TOP 1 product_code
      FROM Profit_Products
      ORDER BY Total_profit DESC) as p
ON t.product_code = p.product_code

--Which customer received the maximum discounts on products?
SELECT TOP 1 c.customer_code,
       c.customer as customer_code,
       MAX(1-pre_invoice_discount_pct) as Max_Discount
FROM fact_pre_invoice_deductions as d
INNER JOIN dim_customer as c
ON d.cutomer_code  = c.customer_code
GROUP BY c.customer_code,c.customer
ORDER BY Max_Discount DESC;

-- Provide the list of markets in which customer 'AtliQ Exclusive" operates its business in the APAC regions?
SELECT market
FROM dim_customer
WHERE customer = 'Atliq Exclusive' AND region = 'APAC'
GROUP BY market

--What is the percentage of unique product increase in 2021 vs 2020?
-- The final output contains the following outputs
-- Unique_products_2020
-- Unqiue_products_2021
--Percentage_change

SELECT *, ((cnt_2021 - cnt_2020) / CAST (cnt_2020 as float)) as percentage_change
FROM
      ( SELECT * 
        FROM ( SELECT COUNT(DISTINCT product_code) as cnt_2020
               FROM fact_sales_monthly
               WHERE fiscal_year = 2020
             ) as t1
INNER JOIN
      ( SELECT (DISTINCT product_code) as cnt_2021
        FROM fact_sales_monthly
        WHERE fiscal_year = 2021
      ) as t2
     ON 1=1
     ) as p




