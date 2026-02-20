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
