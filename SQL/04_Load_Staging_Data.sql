/* =================================================================================================
    Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
    Script       : 04_Load_Staging_Data.sql
    Purpose      : Load source CSV files into the staging layer.
    Layer        : stg
================================================================================================= */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* =================================================================================================
    01. Source Data Location

    Set CsvFolder to the local path of the /Data folder before running this
    script (SQLCMD mode, trailing backslash required). This replaces a
    machine-specific hardcoded path that was not reproducible outside the
    original author's workstation.

    Example:
    :setvar CsvFolder "C:\Projects\Enterprise-Profitability\Data\"
================================================================================================= */

:setvar CsvFolder "<PATH_TO_PROJECT>\Data\"


/* =================================================================================================
    02. Load Regions
================================================================================================= */

BULK INSERT stg.Regions
FROM '$(CsvFolder)Regions.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    03. Load Warehouses
================================================================================================= */

BULK INSERT stg.Warehouses
FROM '$(CsvFolder)Warehouses.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    04. Load Customers
================================================================================================= */

BULK INSERT stg.Customers
FROM '$(CsvFolder)Customers.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    05. Load Products
================================================================================================= */

BULK INSERT stg.Products
FROM '$(CsvFolder)Products.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    06. Load Orders
================================================================================================= */

BULK INSERT stg.Orders
FROM '$(CsvFolder)Orders.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    07. Load Order Items
================================================================================================= */

BULK INSERT stg.Order_Items
FROM '$(CsvFolder)Order_Items.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    08. Load Shipping Costs
================================================================================================= */

BULK INSERT stg.Shipping_Costs
FROM '$(CsvFolder)Shipping_Costs.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    09. Load Storage Costs
================================================================================================= */

BULK INSERT stg.Storage_Costs
FROM '$(CsvFolder)Storage_Costs.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    10. Load Customer Service
================================================================================================= */

BULK INSERT stg.Customer_Service
FROM '$(CsvFolder)Customer_Service.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    11. Load Returns
================================================================================================= */

BULK INSERT stg.Returns
FROM '$(CsvFolder)Returns.csv'
WITH
(
    FORMAT = 'CSV',
    FIRSTROW = 2,
    FIELDQUOTE = '"',
    ROWTERMINATOR = '0x0a',
    TABLOCK
);
GO


/* =================================================================================================
    12. Staging Row Count Validation
================================================================================================= */

SELECT
    v.Table_Name,
    v.Row_Count
FROM
(
    SELECT
        'stg.Regions' AS Table_Name,
        COUNT_BIG(*) AS Row_Count
    FROM stg.Regions

    UNION ALL

    SELECT
        'stg.Warehouses',
        COUNT_BIG(*)
    FROM stg.Warehouses

    UNION ALL

    SELECT
        'stg.Customers',
        COUNT_BIG(*)
    FROM stg.Customers

    UNION ALL

    SELECT
        'stg.Products',
        COUNT_BIG(*)
    FROM stg.Products

    UNION ALL

    SELECT
        'stg.Orders',
        COUNT_BIG(*)
    FROM stg.Orders

    UNION ALL

    SELECT
        'stg.Order_Items',
        COUNT_BIG(*)
    FROM stg.Order_Items

    UNION ALL

    SELECT
        'stg.Shipping_Costs',
        COUNT_BIG(*)
    FROM stg.Shipping_Costs

    UNION ALL

    SELECT
        'stg.Storage_Costs',
        COUNT_BIG(*)
    FROM stg.Storage_Costs

    UNION ALL

    SELECT
        'stg.Customer_Service',
        COUNT_BIG(*)
    FROM stg.Customer_Service

    UNION ALL

    SELECT
        'stg.Returns',
        COUNT_BIG(*)
    FROM stg.Returns
) AS v
ORDER BY
    v.Table_Name;
GO