/* ================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
   Script       : 02_Create_Staging_Tables.sql
   Purpose      : Create staging tables for raw operational data ingestion.
   Layer        : stg
   Grain        : Raw source-level records
   Note         : Renamed during project review from a non-ASCII filename
                  ("Page 02 — Create Staging Tables.sql") that broke portable
                  zip extraction on some systems. Logic unchanged.
   ================================================================================================ */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* ================================================================================================
   01. Regions
   ================================================================================================ */

IF OBJECT_ID(N'stg.Regions', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Regions
    (
        Region_ID       INT             NOT NULL,
        Region_Name     NVARCHAR(100)   NULL,
        Country         NVARCHAR(100)   NULL,
        Territory       NVARCHAR(50)    NULL
    );
END;
GO


/* ================================================================================================
   02. Warehouses
   ================================================================================================ */

IF OBJECT_ID(N'stg.Warehouses', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Warehouses
    (
        Warehouse_ID    INT             NOT NULL,
        Warehouse_Name  NVARCHAR(100)   NULL,
        Region_ID       INT             NULL,
        Capacity        INT             NULL
    );
END;
GO


/* ================================================================================================
   03. Customers
   ================================================================================================ */

IF OBJECT_ID(N'stg.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Customers
    (
        Customer_ID       INT             NOT NULL,
        Customer_Name     NVARCHAR(150)   NULL,
        Customer_Segment  NVARCHAR(50)    NULL,
        Industry          NVARCHAR(100)   NULL,
        Region_ID         INT             NULL,
        Customer_Since    DATE            NULL
    );
END;
GO


/* ================================================================================================
   04. Products
   ================================================================================================ */

IF OBJECT_ID(N'stg.Products', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Products
    (
        Product_ID      INT             NOT NULL,
        Product_Name    NVARCHAR(150)   NULL,
        Category        NVARCHAR(100)   NULL,
        Subcategory     NVARCHAR(100)   NULL,
        Unit_Cost       DECIMAL(18,2)   NULL,
        Unit_Price      DECIMAL(18,2)   NULL
    );
END;
GO


/* ================================================================================================
   05. Orders
   ================================================================================================ */

IF OBJECT_ID(N'stg.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Orders
    (
        Order_ID        INT             NOT NULL,
        Order_Date      DATE            NULL,
        Customer_ID     INT             NULL,
        Region_ID       INT             NULL,
        Warehouse_ID    INT             NULL,
        Order_Channel   NVARCHAR(50)    NULL,
        Order_Status    NVARCHAR(50)    NULL
    );
END;
GO


/* ================================================================================================
   06. Order Items
   ================================================================================================ */

IF OBJECT_ID(N'stg.Order_Items', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Order_Items
    (
        Order_Item_ID   BIGINT          NOT NULL,
        Order_ID        INT             NULL,
        Product_ID      INT             NULL,
        Quantity        INT             NULL,
        Unit_Price      DECIMAL(18,2)   NULL,
        Discount_Amount DECIMAL(18,2)   NULL
    );
END;
GO


/* ================================================================================================
   07. Shipping Costs
   ================================================================================================ */

IF OBJECT_ID(N'stg.Shipping_Costs', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Shipping_Costs
    (
        Shipping_ID      BIGINT          NOT NULL,
        Order_ID         INT             NULL,
        Shipping_Date    DATE            NULL,
        Shipping_Method  NVARCHAR(50)    NULL,
        Shipping_Cost    DECIMAL(18,2)   NULL
    );
END;
GO


/* ================================================================================================
   08. Storage Costs
   ================================================================================================ */

IF OBJECT_ID(N'stg.Storage_Costs', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Storage_Costs
    (
        Storage_ID      BIGINT          NOT NULL,
        Warehouse_ID    INT             NULL,
        Product_ID      INT             NULL,
        Cost_Date       DATE            NULL,
        Storage_Cost    DECIMAL(18,2)   NULL
    );
END;
GO


/* ================================================================================================
   09. Customer Service
   ================================================================================================ */

IF OBJECT_ID(N'stg.Customer_Service', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Customer_Service
    (
        Service_ID      BIGINT          NOT NULL,
        Customer_ID     INT             NULL,
        Order_ID        INT             NULL,
        Service_Date    DATE            NULL,
        Service_Type    NVARCHAR(50)    NULL,
        Service_Cost    DECIMAL(18,2)   NULL
    );
END;
GO


/* ================================================================================================
   10. Returns
   ================================================================================================ */

IF OBJECT_ID(N'stg.Returns', N'U') IS NULL
BEGIN
    CREATE TABLE stg.Returns
    (
        Return_ID        BIGINT          NOT NULL,
        Order_ID         INT             NULL,
        Order_Item_ID    BIGINT          NULL,
        Return_Date      DATE            NULL,
        Return_Quantity  INT             NULL,
        Return_Reason    NVARCHAR(100)   NULL,
        Return_Cost      DECIMAL(18,2)   NULL
    );
END;
GO