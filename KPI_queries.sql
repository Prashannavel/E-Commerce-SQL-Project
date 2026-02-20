 SELECT SUM(Revenue) AS total_revenue
FROM vw_sales_clean;

SELECT COUNT(DISTINCT InvoiceNo) AS total_orders
FROM vw_sales_clean;

SELECT COUNT(DISTINCT CustomerID) AS total_customers
FROM vw_sales_clean
WHERE CustomerID IS NOT NULL;

SELECT TOP 10
    Country,
    SUM(Revenue) AS revenue
FROM vw_sales_clean
GROUP BY Country
ORDER BY revenue DESC;