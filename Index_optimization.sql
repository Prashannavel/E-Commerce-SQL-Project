-- Index for faster country aggregation
CREATE INDEX idx_country
ON ecomm (Country);

-- Index for customer analysis
CREATE INDEX idx_customer
ON ecomm (CustomerID);

-- Index for date filtering
CREATE INDEX idx_invoice_date
ON ecomm (InvoiceDate);
