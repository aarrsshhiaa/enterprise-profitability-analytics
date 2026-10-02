/* =================================================================================================
    Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
    Script       : 06_Load_Core_Data.sql
    Purpose      : Load validated staging data into the core business layer.
    Layer        : stg -> core
    Note         : Adds an audit log entry (10.1) for Customer_Service rows
                   excluded by the Order_ID join, so exclusions are visible
                   in audit.Data_Quality_Audit instead of silently dropped.
================================================================================================= */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;
GO


/* =================================================================================================
    01. Start Core ETL Transaction
================================================================================================= */

BEGIN TRY

    BEGIN TRANSACTION;


    /* =================================================================================================
        02. Clear Existing Core Data

        DELETE is used instead of TRUNCATE because Core tables
        are connected through Foreign Key constraints.
    ================================================================================================= */

    DELETE FROM core.Customer_Service;
    DELETE FROM core.Returns;
    DELETE FROM core.Shipping_Costs;
    DELETE FROM core.Storage_Costs;
    DELETE FROM core.Order_Items;
    DELETE FROM core.Orders;
    DELETE FROM core.Products;
    DELETE FROM core.Customers;
    DELETE FROM core.Warehouses;
    DELETE FROM core.Regions;


    /* =================================================================================================
        03. Load Regions
    ================================================================================================= */

    INSERT INTO core.Regions
    (
        Region_ID,
        Region_Name,
        Country,
        Territory
    )
    SELECT
        Region_ID,
        Region_Name,
        Country,
        Territory
    FROM stg.Regions;


    /* =================================================================================================
        04. Load Warehouses
    ================================================================================================= */

    INSERT INTO core.Warehouses
    (
        Warehouse_ID,
        Warehouse_Name,
        Region_ID,
        Capacity
    )
    SELECT
        Warehouse_ID,
        Warehouse_Name,
        Region_ID,
        Capacity
    FROM stg.Warehouses;


    /* =================================================================================================
        05. Load Customers
    ================================================================================================= */

    INSERT INTO core.Customers
    (
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry,
        Region_ID,
        Customer_Since
    )
    SELECT
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry,
        Region_ID,
        Customer_Since
    FROM stg.Customers;


    /* =================================================================================================
        06. Load Products
    ================================================================================================= */

    INSERT INTO core.Products
    (
        Product_ID,
        Product_Name,
        Category,
        Subcategory,
        Unit_Cost,
        Unit_Price
    )
    SELECT
        Product_ID,
        Product_Name,
        Category,
        Subcategory,
        Unit_Cost,
        Unit_Price
    FROM stg.Products;


    /* =================================================================================================
        07. Load Orders
    ================================================================================================= */

    INSERT INTO core.Orders
    (
        Order_ID,
        Order_Date,
        Customer_ID,
        Region_ID,
        Warehouse_ID,
        Order_Channel,
        Order_Status
    )
    SELECT
        Order_ID,
        Order_Date,
        Customer_ID,
        Region_ID,
        Warehouse_ID,
        Order_Channel,
        Order_Status
    FROM stg.Orders;


    /* =================================================================================================
        08. Load Order Items
    ================================================================================================= */

    INSERT INTO core.Order_Items
    (
        Order_Item_ID,
        Order_ID,
        Product_ID,
        Quantity,
        Unit_Price,
        Discount_Amount
    )
    SELECT
        Order_Item_ID,
        Order_ID,
        Product_ID,
        Quantity,
        Unit_Price,
        Discount_Amount
    FROM stg.Order_Items;


    /* =================================================================================================
        09. Load Shipping Costs
    ================================================================================================= */

    INSERT INTO core.Shipping_Costs
    (
        Shipping_ID,
        Order_ID,
        Shipping_Date,
        Shipping_Method,
        Shipping_Cost
    )
    SELECT
        Shipping_ID,
        Order_ID,
        Shipping_Date,
        Shipping_Method,
        Shipping_Cost
    FROM stg.Shipping_Costs;


    /* =================================================================================================
        10. Load Storage Costs
    ================================================================================================= */

    INSERT INTO core.Storage_Costs
    (
        Storage_ID,
        Warehouse_ID,
        Product_ID,
        Cost_Date,
        Storage_Cost
    )
    SELECT
        Storage_ID,
        Warehouse_ID,
        Product_ID,
        Cost_Date,
        Storage_Cost
    FROM stg.Storage_Costs;


    /* =================================================================================================
        10.1 Log Excluded Customer Service Records

        Customer_Service rows whose Order_ID has no matching core.Orders
        record are excluded by the INNER JOIN below (they cannot be
        resolved to an authoritative Customer_ID). This step logs the
        count of excluded rows to the audit table instead of dropping
        them silently, so the exclusion is visible and auditable rather
        than a hidden side effect of the join.
    ================================================================================================= */

    INSERT INTO audit.Data_Quality_Audit
    (
        Check_Name,
        Check_Category,
        Issue_Count,
        Status,
        Business_Action
    )
    SELECT
        N'Customer_Service Orphaned by Order_ID (Excluded from Core Load)',
        N'Referential Integrity',
        COUNT(*),
        CASE WHEN COUNT(*) = 0 THEN 'PASS' ELSE 'WARNING' END,
        N'Rows are excluded from core.Customer_Service because their Order_ID does not exist in core.Orders. Investigate source-system lineage if Issue_Count is unexpectedly high.'
    FROM stg.Customer_Service AS cs
    WHERE NOT EXISTS
    (
        SELECT 1
        FROM core.Orders AS o
        WHERE o.Order_ID = cs.Order_ID
    );


    /* =================================================================================================
        11. Load Customer Service

        Business Rule:
        Orders.Customer_ID is the authoritative customer reference.

        Source_Customer_ID preserves the original source-system
        customer value for lineage and auditability.
    ================================================================================================= */

    INSERT INTO core.Customer_Service
    (
        Service_ID,
        Customer_ID,
        Source_Customer_ID,
        Order_ID,
        Service_Date,
        Service_Type,
        Service_Cost
    )
    SELECT
        cs.Service_ID,
        o.Customer_ID,
        cs.Customer_ID AS Source_Customer_ID,
        cs.Order_ID,
        cs.Service_Date,
        cs.Service_Type,
        cs.Service_Cost
    FROM stg.Customer_Service AS cs
    INNER JOIN core.Orders AS o
        ON cs.Order_ID = o.Order_ID;


    /* =================================================================================================
        12. Load Returns
    ================================================================================================= */

    INSERT INTO core.Returns
    (
        Return_ID,
        Order_ID,
        Order_Item_ID,
        Return_Date,
        Return_Quantity,
        Return_Reason,
        Return_Cost
    )
    SELECT
        Return_ID,
        Order_ID,
        Order_Item_ID,
        Return_Date,
        Return_Quantity,
        Return_Reason,
        Return_Cost
    FROM stg.Returns;


    /* =================================================================================================
        13. Core Load Row Count Validation

        The Core layer should preserve the validated Staging row counts.
    ================================================================================================= */

    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Regions
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Regions
    )
    BEGIN
        THROW 50001,
              'Core load validation failed: Regions row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Warehouses
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Warehouses
    )
    BEGIN
        THROW 50002,
              'Core load validation failed: Warehouses row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Customers
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Customers
    )
    BEGIN
        THROW 50003,
              'Core load validation failed: Customers row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Products
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Products
    )
    BEGIN
        THROW 50004,
              'Core load validation failed: Products row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Orders
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Orders
    )
    BEGIN
        THROW 50005,
              'Core load validation failed: Orders row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Order_Items
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Order_Items
    )
    BEGIN
        THROW 50006,
              'Core load validation failed: Order_Items row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Shipping_Costs
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Shipping_Costs
    )
    BEGIN
        THROW 50007,
              'Core load validation failed: Shipping_Costs row count mismatch.',
              1;
    END;


    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Storage_Costs
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Storage_Costs
    )
    BEGIN
        THROW 50008,
              'Core load validation failed: Storage_Costs row count mismatch.',
              1;
    END;


    /* =============================================================================================
        Customer Service Exception

        Customer_Service is intentionally transformed because
        Orders.Customer_ID is the authoritative analytical customer.
        
        Therefore, direct row-count equality is NOT sufficient.
        We validate that every loaded service record has a source
        record and a resolved analytical customer.
    ============================================================================================= */

    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Customer_Service
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Customer_Service AS cs
        INNER JOIN core.Orders AS o
            ON cs.Order_ID = o.Order_ID
    )
    BEGIN
        THROW 50009,
              'Core load validation failed: Customer_Service transformation row count mismatch.',
              1;
    END;


    /* =================================================================================================
        13.1 Validate Customer Service Transformation
    ================================================================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM core.Customer_Service AS cs
        INNER JOIN core.Orders AS o
            ON cs.Order_ID = o.Order_ID
        WHERE cs.Customer_ID <> o.Customer_ID
    )
    BEGIN
        THROW 50010,
              'Core load validation failed: Customer_Service customer mismatch detected.',
              1;
    END;


    /* =================================================================================================
        13.2 Validate Source Customer Lineage
    ================================================================================================= */

    IF EXISTS
    (
        SELECT 1
        FROM core.Customer_Service AS cs
        WHERE cs.Source_Customer_ID IS NULL
    )
    BEGIN
        THROW 50011,
              'Core load validation failed: Source_Customer_ID lineage is missing.',
              1;
    END;


    /* =================================================================================================
        14. Validate Returns Row Count
    ================================================================================================= */

    IF
    (
        SELECT COUNT_BIG(*)
        FROM core.Returns
    )
    <>
    (
        SELECT COUNT_BIG(*)
        FROM stg.Returns
    )
    BEGIN
        THROW 50012,
              'Core load validation failed: Returns row count mismatch.',
              1;
    END;


    /* =================================================================================================
        15. Commit Transaction
    ================================================================================================= */

    COMMIT TRANSACTION;


    /* =================================================================================================
        16. Core Load Summary
    ================================================================================================= */

    SELECT
        v.Table_Name,
        v.Row_Count
    FROM
    (
        SELECT
            'core.Regions' AS Table_Name,
            COUNT_BIG(*) AS Row_Count
        FROM core.Regions

        UNION ALL

        SELECT
            'core.Warehouses',
            COUNT_BIG(*)
        FROM core.Warehouses

        UNION ALL

        SELECT
            'core.Customers',
            COUNT_BIG(*)
        FROM core.Customers

        UNION ALL

        SELECT
            'core.Products',
            COUNT_BIG(*)
        FROM core.Products

        UNION ALL

        SELECT
            'core.Orders',
            COUNT_BIG(*)
        FROM core.Orders

        UNION ALL

        SELECT
            'core.Order_Items',
            COUNT_BIG(*)
        FROM core.Order_Items

        UNION ALL

        SELECT
            'core.Shipping_Costs',
            COUNT_BIG(*)
        FROM core.Shipping_Costs

        UNION ALL

        SELECT
            'core.Storage_Costs',
            COUNT_BIG(*)
        FROM core.Storage_Costs

        UNION ALL

        SELECT
            'core.Customer_Service',
            COUNT_BIG(*)
        FROM core.Customer_Service

        UNION ALL

        SELECT
            'core.Returns',
            COUNT_BIG(*)
        FROM core.Returns
    ) AS v

    ORDER BY
        v.Table_Name;


END TRY


/* =================================================================================================
    17. Error Handling
================================================================================================= */

BEGIN CATCH

    IF XACT_STATE() <> 0
    BEGIN
        ROLLBACK TRANSACTION;
    END;

    THROW;

END CATCH;
GO