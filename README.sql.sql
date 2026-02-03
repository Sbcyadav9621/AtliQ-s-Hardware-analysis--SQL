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
ORDER BY no_of_customers desc
