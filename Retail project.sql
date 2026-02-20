SELECT COUNT(*) AS total_rows
FROM ecomm;

SELECT TOP 10 *
FROM ecomm;

ALTER TABLE ecomm
ADD RowID INT IDENTITY(1,1);

ALTER TABLE ecomm
ADD CONSTRAINT PK_ecomm PRIMARY KEY (RowID);

CREATE VIEW vw_sales_clean AS
SELECT
    RowID,
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    (Quantity * UnitPrice) AS Revenue
FROM ecomm
WHERE InvoiceNo NOT LIKE 'C%'     -- remove cancelled invoices
  AND Quantity > 0               -- remove returns
  AND UnitPrice > 0;             -- remove free/invalid items

  SELECT TOP 20 *
FROM ecomm;

EXEC sp_help ecomm;

SELECT TOP 20 *
FROM vw_sales_clean;

SELECT COUNT(*) AS raw_rows FROM ecomm;

SELECT COUNT(*) AS clean_rows FROM vw_sales_clean;

CREATE OR ALTER VIEW vw_sales_clean AS
SELECT
    RowID,
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
     CAST(UnitPrice AS DECIMAL(18,2)) AS UnitPrice,
    CustomerID,
    Country,
    CAST(Quantity * UnitPrice AS DECIMAL(18,2)) AS Revenue
FROM ecomm
WHERE InvoiceNo NOT LIKE 'C%'
  AND Quantity > 0
  AND UnitPrice > 0;


  --------kpi queries

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
--------------------Product+customer+analytics
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

-------------RFM


WITH rfm_base AS (
    SELECT
        CustomerID,
        MAX(InvoiceDate) AS last_purchase_date,
        DATEDIFF(day, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) FROM vw_sales_clean)) AS recency_days,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(Revenue) AS monetary
    FROM vw_sales_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)
SELECT TOP 20 *
FROM rfm_base
ORDER BY monetary DESC;


WITH rfm_base AS (
    SELECT
        CustomerID,
        DATEDIFF(day, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) FROM vw_sales_clean)) AS recency_days,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(Revenue) AS monetary
    FROM vw_sales_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,

        NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
)
SELECT TOP 50 *
FROM rfm_scores
ORDER BY r_score DESC, f_score DESC, m_score DESC;


WITH rfm_base AS (
    SELECT
        CustomerID,
        DATEDIFF(day, MAX(InvoiceDate), (SELECT MAX(InvoiceDate) FROM vw_sales_clean)) AS recency_days,
        COUNT(DISTINCT InvoiceNo) AS frequency,
        SUM(Revenue) AS monetary
    FROM vw_sales_clean
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),
rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,
        NTILE(5) OVER (ORDER BY recency_days ASC) AS r_score,
        NTILE(5) OVER (ORDER BY frequency DESC) AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC) AS m_score
    FROM rfm_base
),
rfm_segment AS (
    SELECT *,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
            WHEN r_score <= 2 AND m_score >= 4 THEN 'Cannot Lose'
            ELSE 'Regular'
        END AS segment
    FROM rfm_scores
)
SELECT segment, COUNT(*) AS customers
FROM rfm_segment
GROUP BY segment
ORDER BY customers DESC;








