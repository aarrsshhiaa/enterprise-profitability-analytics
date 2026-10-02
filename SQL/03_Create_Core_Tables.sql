/* ================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
   Script       : 03_Create_Core_Tables.sql
   Purpose      : Create clean business/core tables for validated operational data.
   Layer        : core
   Grain        : Business-level operational records
   ================================================================================================ */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* ================================================================================================
   01. Regions
   Grain: 1 Row = 1 Region
   ================================================================================================ */

IF OBJECT_ID(N'core.Regions', N'U') IS NULL
BEGIN
    CREATE TABLE core.Regions
    (
        Region_ID       INT             NOT NULL,
        Region_Name     NVARCHAR(100)   NULL,
        Country         NVARCHAR(100)   NULL,
        Territory       NVARCHAR(50)    NULL,

        CONSTRAINT PK_core_Regions
            PRIMARY KEY CLUSTERED (Region_ID)
    );
END;
GO


/* ================================================================================================
   02. Warehouses
   Grain: 1 Row = 1 Warehouse
   ================================================================================================ */

IF OBJECT_ID(N'core.Warehouses', N'U') IS NULL
BEGIN
    CREATE TABLE core.Warehouses
    (
        Warehouse_ID    INT             NOT NULL,
        Warehouse_Name  NVARCHAR(100)   NULL,
        Region_ID       INT             NULL,
        Capacity        INT             NULL,

        CONSTRAINT PK_core_Warehouses
            PRIMARY KEY CLUSTERED (Warehouse_ID),

        CONSTRAINT FK_core_Warehouses_Regions
            FOREIGN KEY (Region_ID)
            REFERENCES core.Regions (Region_ID),

        CONSTRAINT CK_core_Warehouses_Capacity
            CHECK (Capacity IS NULL OR Capacity > 0)
    );
END;
GO


/* ================================================================================================
   03. Customers
   Grain: 1 Row = 1 Customer
   ================================================================================================ */

IF OBJECT_ID(N'core.Customers', N'U') IS NULL
BEGIN
    CREATE TABLE core.Customers
    (
        Customer_ID       INT             NOT NULL,
        Customer_Name     NVARCHAR(150)   NULL,
        Customer_Segment  NVARCHAR(50)    NULL,
        Industry          NVARCHAR(100)   NULL,
        Region_ID         INT             NULL,
        Customer_Since    DATE            NULL,

        CONSTRAINT PK_core_Customers
            PRIMARY KEY CLUSTERED (Customer_ID),

        CONSTRAINT FK_core_Customers_Regions
            FOREIGN KEY (Region_ID)
            REFERENCES core.Regions (Region_ID)
    );
END;
GO


/* ================================================================================================
   04. Products
   Grain: 1 Row = 1 Product
   ================================================================================================ */

IF OBJECT_ID(N'core.Products', N'U') IS NULL
BEGIN
    CREATE TABLE core.Products
    (
        Product_ID      INT             NOT NULL,
        Product_Name    NVARCHAR(150)   NULL,
        Category        NVARCHAR(100)   NULL,
        Subcategory     NVARCHAR(100)   NULL,
        Unit_Cost       DECIMAL(18,2)   NULL,
        Unit_Price      DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Products
            PRIMARY KEY CLUSTERED (Product_ID),

        CONSTRAINT CK_core_Products_Unit_Cost
            CHECK (Unit_Cost IS NULL OR Unit_Cost > 0),

        CONSTRAINT CK_core_Products_Unit_Price
            CHECK (Unit_Price IS NULL OR Unit_Price > 0)
    );
END;
GO


/* ================================================================================================
   05. Orders
   Grain: 1 Row = 1 Order
   ================================================================================================ */

IF OBJECT_ID(N'core.Orders', N'U') IS NULL
BEGIN
    CREATE TABLE core.Orders
    (
        Order_ID        INT             NOT NULL,
        Order_Date      DATE            NULL,
        Customer_ID     INT             NULL,
        Region_ID       INT             NULL,
        Warehouse_ID    INT             NULL,
        Order_Channel   NVARCHAR(50)    NULL,
        Order_Status    NVARCHAR(50)    NULL,

        CONSTRAINT PK_core_Orders
            PRIMARY KEY CLUSTERED (Order_ID),

        CONSTRAINT FK_core_Orders_Customers
            FOREIGN KEY (Customer_ID)
            REFERENCES core.Customers (Customer_ID),

        CONSTRAINT FK_core_Orders_Regions
            FOREIGN KEY (Region_ID)
            REFERENCES core.Regions (Region_ID),

        CONSTRAINT FK_core_Orders_Warehouses
            FOREIGN KEY (Warehouse_ID)
            REFERENCES core.Warehouses (Warehouse_ID)
    );
END;
GO


/* ================================================================================================
   06. Order Items
   Grain: 1 Row = 1 Order Line
   ================================================================================================ */

IF OBJECT_ID(N'core.Order_Items', N'U') IS NULL
BEGIN
    CREATE TABLE core.Order_Items
    (
        Order_Item_ID    BIGINT          NOT NULL,
        Order_ID         INT             NULL,
        Product_ID       INT             NULL,
        Quantity         INT             NULL,
        Unit_Price       DECIMAL(18,2)   NULL,
        Discount_Amount  DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Order_Items
            PRIMARY KEY CLUSTERED (Order_Item_ID),

        CONSTRAINT FK_core_Order_Items_Orders
            FOREIGN KEY (Order_ID)
            REFERENCES core.Orders (Order_ID),

        CONSTRAINT FK_core_Order_Items_Products
            FOREIGN KEY (Product_ID)
            REFERENCES core.Products (Product_ID),

        CONSTRAINT CK_core_Order_Items_Quantity
            CHECK (Quantity IS NULL OR Quantity > 0),

        CONSTRAINT CK_core_Order_Items_Unit_Price
            CHECK (Unit_Price IS NULL OR Unit_Price > 0),

        CONSTRAINT CK_core_Order_Items_Discount
            CHECK (Discount_Amount IS NULL OR Discount_Amount >= 0)
    );
END;
GO


/* ================================================================================================
   07. Shipping Costs
   Grain: 1 Row = 1 Shipping Record
   ================================================================================================ */

IF OBJECT_ID(N'core.Shipping_Costs', N'U') IS NULL
BEGIN
    CREATE TABLE core.Shipping_Costs
    (
        Shipping_ID      BIGINT          NOT NULL,
        Order_ID         INT             NULL,
        Shipping_Date    DATE            NULL,
        Shipping_Method  NVARCHAR(50)    NULL,
        Shipping_Cost    DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Shipping_Costs
            PRIMARY KEY CLUSTERED (Shipping_ID),

        CONSTRAINT FK_core_Shipping_Costs_Orders
            FOREIGN KEY (Order_ID)
            REFERENCES core.Orders (Order_ID),

        CONSTRAINT CK_core_Shipping_Costs_Cost
            CHECK (Shipping_Cost IS NULL OR Shipping_Cost > 0)
    );
END;
GO


/* ================================================================================================
   08. Storage Costs
   Grain: 1 Row = 1 Storage Cost Event
   ================================================================================================ */

IF OBJECT_ID(N'core.Storage_Costs', N'U') IS NULL
BEGIN
    CREATE TABLE core.Storage_Costs
    (
        Storage_ID      BIGINT          NOT NULL,
        Warehouse_ID    INT             NULL,
        Product_ID      INT             NULL,
        Cost_Date       DATE            NULL,
        Storage_Cost    DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Storage_Costs
            PRIMARY KEY CLUSTERED (Storage_ID),

        CONSTRAINT FK_core_Storage_Costs_Warehouses
            FOREIGN KEY (Warehouse_ID)
            REFERENCES core.Warehouses (Warehouse_ID),

        CONSTRAINT FK_core_Storage_Costs_Products
            FOREIGN KEY (Product_ID)
            REFERENCES core.Products (Product_ID),

        CONSTRAINT CK_core_Storage_Costs_Cost
            CHECK (Storage_Cost IS NULL OR Storage_Cost > 0)
    );
END;
GO


/* ================================================================================================
   09. Customer Service
   Grain: 1 Row = 1 Customer Service Event
   ================================================================================================ */

IF OBJECT_ID(N'core.Customer_Service', N'U') IS NULL
BEGIN
    CREATE TABLE core.Customer_Service
    (
        Service_ID          BIGINT          NOT NULL,
        Customer_ID         INT             NULL,
        Source_Customer_ID  INT             NULL,
        Order_ID            INT             NULL,
        Service_Date        DATE            NULL,
        Service_Type        NVARCHAR(50)    NULL,
        Service_Cost        DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Customer_Service
            PRIMARY KEY CLUSTERED (Service_ID),

        CONSTRAINT FK_core_Customer_Service_Customers
            FOREIGN KEY (Customer_ID)
            REFERENCES core.Customers (Customer_ID),

        CONSTRAINT FK_core_Customer_Service_Orders
            FOREIGN KEY (Order_ID)
            REFERENCES core.Orders (Order_ID),

        CONSTRAINT CK_core_Customer_Service_Cost
            CHECK (Service_Cost IS NULL OR Service_Cost > 0)
    );
END;
GO


/* ================================================================================================
   10. Returns
   Grain: 1 Row = 1 Return Record
   ================================================================================================ */

IF OBJECT_ID(N'core.Returns', N'U') IS NULL
BEGIN
    CREATE TABLE core.Returns
    (
        Return_ID        BIGINT          NOT NULL,
        Order_ID         INT             NULL,
        Order_Item_ID    BIGINT          NULL,
        Return_Date      DATE            NULL,
        Return_Quantity  INT             NULL,
        Return_Reason    NVARCHAR(100)   NULL,
        Return_Cost      DECIMAL(18,2)   NULL,

        CONSTRAINT PK_core_Returns
            PRIMARY KEY CLUSTERED (Return_ID),

        CONSTRAINT FK_core_Returns_Orders
            FOREIGN KEY (Order_ID)
            REFERENCES core.Orders (Order_ID),

        CONSTRAINT FK_core_Returns_Order_Items
            FOREIGN KEY (Order_Item_ID)
            REFERENCES core.Order_Items (Order_Item_ID),

        CONSTRAINT CK_core_Returns_Quantity
            CHECK (Return_Quantity IS NULL OR Return_Quantity > 0),

        CONSTRAINT CK_core_Returns_Cost
            CHECK (Return_Cost IS NULL OR Return_Cost > 0)
    );
END;
GO