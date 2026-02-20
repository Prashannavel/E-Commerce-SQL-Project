CREATE INDEX idx_customer
ON ecomm (CustomerID);

ALTER TABLE ecomm
WITH NOCHECK
ADD CONSTRAINT chk_quantity_not_zero
CHECK (Quantity <> 0);

CREATE TABLE order_audit (
    audit_id INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo NVARCHAR(20),
    Revenue DECIMAL(18,2),
    inserted_at DATETIME DEFAULT GETDATE()
);


CREATE TRIGGER trg_high_value_order
ON ecomm
AFTER INSERT
AS
BEGIN
    INSERT INTO order_audit (InvoiceNo, Revenue)
    SELECT 
        InvoiceNo,
        Quantity * UnitPrice
    FROM inserted
    WHERE (Quantity * UnitPrice) > 1000;
END;


IF OBJECT_ID('sp_insert_order', 'P') IS NOT NULL
    DROP PROCEDURE sp_insert_order;
GO


CREATE PROCEDURE sp_insert_order
    @InvoiceNo NVARCHAR(20),
    @StockCode NVARCHAR(20),
    @Description NVARCHAR(255),
    @Quantity INT,
    @InvoiceDate DATETIME,
    @UnitPrice DECIMAL(18,2),
    @CustomerID INT,
    @Country NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @Quantity = 0
            THROW 50001, 'Quantity cannot be zero.', 1;

        IF @UnitPrice <= 0
            THROW 50002, 'Unit price must be greater than zero.', 1;

        INSERT INTO ecomm
        (
            InvoiceNo,
            StockCode,
            Description,
            Quantity,
            InvoiceDate,
            UnitPrice,
            CustomerID,
            Country
        )
        VALUES
        (
            @InvoiceNo,
            @StockCode,
            @Description,
            @Quantity,
            @InvoiceDate,
            @UnitPrice,
            @CustomerID,
            @Country
        );

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SELECT ERROR_MESSAGE() AS ErrorMessage;
    END CATCH
END;
GO



CREATE PROCEDURE sp_revenue_by_country
    @Country NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @sql NVARCHAR(MAX);

    SET @sql = '
        SELECT 
            Country,
            SUM(Quantity * UnitPrice) AS total_revenue
        FROM ecomm
        WHERE Country = @c
        GROUP BY Country;
    ';

    EXEC sp_executesql 
        @sql,
        N'@c NVARCHAR(50)',
        @c = @Country;
END;


EXEC sp_revenue_by_country 'France';


BEGIN TRY
    BEGIN TRANSACTION;

    UPDATE ecomm
    SET Quantity = -Quantity
    WHERE InvoiceNo = '12345';

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    ROLLBACK TRANSACTION;
    SELECT ERROR_MESSAGE();
END CATCH;

