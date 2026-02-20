SELECT
    YEAR(InvoiceDate) AS year,
    MONTH(InvoiceDate) AS month,
    SUM(Revenue) AS monthly_revenue
FROM vw_sales_clean
GROUP BY YEAR(InvoiceDate), MONTH(InvoiceDate)
ORDER BY year, month;

SELECT TOP 10
    StockCode,
    Description,
    SUM(Revenue) AS total_revenue
FROM vw_sales_clean
GROUP BY StockCode, Description
ORDER BY total_revenue DESC;

SELECT TOP 10
    CustomerID,
    SUM(Revenue) AS total_revenue
FROM vw_sales_clean
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY total_revenue DESC;

SELECT
    SUM(Revenue) / COUNT(DISTINCT InvoiceNo) AS avg_order_value
FROM vw_sales_clean;

SELECT COUNT(*) AS repeat_customers
FROM (
    SELECT CustomerID
    FROM vw_sales_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
    HAVING COUNT(DISTINCT InvoiceNo) > 1
) x;
