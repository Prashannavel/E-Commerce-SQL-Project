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
