/* =================================================================================================
    Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
    Script       : 05_Data_Quality_Audit.sql
    Purpose      : Validate staging data quality before loading the core layer.
    Layer        : stg -> audit
================================================================================================= */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* =================================================================================================
    01. Create Audit Schema
================================================================================================= */

IF SCHEMA_ID(N'audit') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA audit');
END;
GO


/* =================================================================================================
    02. Create Data Quality Audit Table
================================================================================================= */

IF OBJECT_ID(N'audit.Data_Quality_Audit', N'U') IS NULL
BEGIN
    CREATE TABLE audit.Data_Quality_Audit
    (
        Audit_ID
            INT IDENTITY(1,1) NOT NULL,

        Check_Name
            NVARCHAR(200) NOT NULL,

        Check_Category
            NVARCHAR(100) NOT NULL,

        Issue_Count
            BIGINT NOT NULL,

        Status
            VARCHAR(20) NOT NULL,

        Business_Action
            NVARCHAR(500) NULL,

        Audit_Date
            DATETIME2(0) NOT NULL
            CONSTRAINT DF_Data_Quality_Audit_Audit_Date
                DEFAULT SYSDATETIME(),

        CONSTRAINT PK_Data_Quality_Audit
            PRIMARY KEY (Audit_ID),

        CONSTRAINT CK_Data_Quality_Audit_Issue_Count
            CHECK (Issue_Count >= 0),

        CONSTRAINT CK_Data_Quality_Audit_Status
            CHECK (Status IN ('PASS', 'WARNING', 'FAIL'))
    );
END;
GO


/* =================================================================================================
    03. Clear Previous Audit Run
================================================================================================= */

TRUNCATE TABLE audit.Data_Quality_Audit;
GO


/* =================================================================================================
    04. Execute Data Quality Checks
================================================================================================= */

INSERT INTO audit.Data_Quality_Audit
(
    Check_Name,
    Check_Category,
    Issue_Count,
    Status,
    Business_Action
)
VALUES

/* ================================================================================================
   A. Uniqueness Checks
================================================================================================ */

(
    N'Duplicate Customer_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Customer_ID
            FROM stg.Customers
            GROUP BY Customer_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Customer_ID
                FROM stg.Customers
                GROUP BY Customer_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Customer_ID must be unique before loading the core customer dimension.'
),

(
    N'Duplicate Product_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Product_ID
            FROM stg.Products
            GROUP BY Product_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Product_ID
                FROM stg.Products
                GROUP BY Product_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Product_ID must be unique before loading the core product dimension.'
),

(
    N'Duplicate Order_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Order_ID
            FROM stg.Orders
            GROUP BY Order_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Order_ID
                FROM stg.Orders
                GROUP BY Order_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Order_ID must be unique.'
),

(
    N'Duplicate Order_Item_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Order_Item_ID
            FROM stg.Order_Items
            GROUP BY Order_Item_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Order_Item_ID
                FROM stg.Order_Items
                GROUP BY Order_Item_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Order_Item_ID must be unique.'
),

(
    N'Duplicate Region_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Region_ID
            FROM stg.Regions
            GROUP BY Region_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Region_ID
                FROM stg.Regions
                GROUP BY Region_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Region_ID must be unique.'
),

(
    N'Duplicate Warehouse_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Warehouse_ID
            FROM stg.Warehouses
            GROUP BY Warehouse_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Warehouse_ID
                FROM stg.Warehouses
                GROUP BY Warehouse_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Warehouse_ID must be unique.'
),

(
    N'Duplicate Shipping_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Shipping_ID
            FROM stg.Shipping_Costs
            GROUP BY Shipping_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Shipping_ID
                FROM stg.Shipping_Costs
                GROUP BY Shipping_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Shipping_ID must be unique.'
),

(
    N'Duplicate Storage_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Storage_ID
            FROM stg.Storage_Costs
            GROUP BY Storage_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Storage_ID
                FROM stg.Storage_Costs
                GROUP BY Storage_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Storage_ID must be unique.'
),

(
    N'Duplicate Service_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Service_ID
            FROM stg.Customer_Service
            GROUP BY Service_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Service_ID
                FROM stg.Customer_Service
                GROUP BY Service_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Service_ID must be unique.'
),

(
    N'Duplicate Return_ID',
    N'Uniqueness',

    (
        SELECT COUNT(*)
        FROM
        (
            SELECT Return_ID
            FROM stg.Returns
            GROUP BY Return_ID
            HAVING COUNT(*) > 1
        ) AS D
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM
            (
                SELECT Return_ID
                FROM stg.Returns
                GROUP BY Return_ID
                HAVING COUNT(*) > 1
            ) AS D
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Return_ID must be unique.'
),


/* ================================================================================================
   B. Referential Integrity Checks
================================================================================================ */

(
    N'Customers to Regions - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Customers AS c
        LEFT JOIN stg.Regions AS r
            ON c.Region_ID = r.Region_ID
        WHERE c.Region_ID IS NOT NULL
          AND r.Region_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Customers AS c
            LEFT JOIN stg.Regions AS r
                ON c.Region_ID = r.Region_ID
            WHERE c.Region_ID IS NOT NULL
              AND r.Region_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan customer region references must be resolved.'
),

(
    N'Warehouses to Regions - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Warehouses AS w
        LEFT JOIN stg.Regions AS r
            ON w.Region_ID = r.Region_ID
        WHERE w.Region_ID IS NOT NULL
          AND r.Region_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Warehouses AS w
            LEFT JOIN stg.Regions AS r
                ON w.Region_ID = r.Region_ID
            WHERE w.Region_ID IS NOT NULL
              AND r.Region_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan warehouse region references must be resolved.'
),

(
    N'Orders to Customers - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Orders AS o
        LEFT JOIN stg.Customers AS c
            ON o.Customer_ID = c.Customer_ID
        WHERE o.Customer_ID IS NOT NULL
          AND c.Customer_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Orders AS o
            LEFT JOIN stg.Customers AS c
                ON o.Customer_ID = c.Customer_ID
            WHERE o.Customer_ID IS NOT NULL
              AND c.Customer_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan order customer references must be resolved.'
),

(
    N'Orders to Regions - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Orders AS o
        LEFT JOIN stg.Regions AS r
            ON o.Region_ID = r.Region_ID
        WHERE o.Region_ID IS NOT NULL
          AND r.Region_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Orders AS o
            LEFT JOIN stg.Regions AS r
                ON o.Region_ID = r.Region_ID
            WHERE o.Region_ID IS NOT NULL
              AND r.Region_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan order region references must be resolved.'
),

(
    N'Orders to Warehouses - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Orders AS o
        LEFT JOIN stg.Warehouses AS w
            ON o.Warehouse_ID = w.Warehouse_ID
        WHERE o.Warehouse_ID IS NOT NULL
          AND w.Warehouse_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Orders AS o
            LEFT JOIN stg.Warehouses AS w
                ON o.Warehouse_ID = w.Warehouse_ID
            WHERE o.Warehouse_ID IS NOT NULL
              AND w.Warehouse_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan order warehouse references must be resolved.'
),

(
    N'Order Items to Orders - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Order_Items AS oi
        LEFT JOIN stg.Orders AS o
            ON oi.Order_ID = o.Order_ID
        WHERE oi.Order_ID IS NOT NULL
          AND o.Order_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Order_Items AS oi
            LEFT JOIN stg.Orders AS o
                ON oi.Order_ID = o.Order_ID
            WHERE oi.Order_ID IS NOT NULL
              AND o.Order_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan order item references must be resolved.'
),

(
    N'Order Items to Products - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Order_Items AS oi
        LEFT JOIN stg.Products AS p
            ON oi.Product_ID = p.Product_ID
        WHERE oi.Product_ID IS NOT NULL
          AND p.Product_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Order_Items AS oi
            LEFT JOIN stg.Products AS p
                ON oi.Product_ID = p.Product_ID
            WHERE oi.Product_ID IS NOT NULL
              AND p.Product_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan product references must be resolved.'
),

(
    N'Shipping to Orders - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Shipping_Costs AS s
        LEFT JOIN stg.Orders AS o
            ON s.Order_ID = o.Order_ID
        WHERE s.Order_ID IS NOT NULL
          AND o.Order_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Shipping_Costs AS s
            LEFT JOIN stg.Orders AS o
                ON s.Order_ID = o.Order_ID
            WHERE s.Order_ID IS NOT NULL
              AND o.Order_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan shipping order references must be resolved.'
),

(
    N'Storage to Warehouses - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Storage_Costs AS s
        LEFT JOIN stg.Warehouses AS w
            ON s.Warehouse_ID = w.Warehouse_ID
        WHERE s.Warehouse_ID IS NOT NULL
          AND w.Warehouse_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Storage_Costs AS s
            LEFT JOIN stg.Warehouses AS w
                ON s.Warehouse_ID = w.Warehouse_ID
            WHERE s.Warehouse_ID IS NOT NULL
              AND w.Warehouse_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan storage warehouse references must be resolved.'
),

(
    N'Storage to Products - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Storage_Costs AS s
        LEFT JOIN stg.Products AS p
            ON s.Product_ID = p.Product_ID
        WHERE s.Product_ID IS NOT NULL
          AND p.Product_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Storage_Costs AS s
            LEFT JOIN stg.Products AS p
                ON s.Product_ID = p.Product_ID
            WHERE s.Product_ID IS NOT NULL
              AND p.Product_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan storage product references must be resolved.'
),

(
    N'Returns to Orders - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Returns AS r
        LEFT JOIN stg.Orders AS o
            ON r.Order_ID = o.Order_ID
        WHERE r.Order_ID IS NOT NULL
          AND o.Order_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Returns AS r
            LEFT JOIN stg.Orders AS o
                ON r.Order_ID = o.Order_ID
            WHERE r.Order_ID IS NOT NULL
              AND o.Order_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan return order references must be resolved.'
),

(
    N'Returns to Order Items - Orphan Records',
    N'Referential Integrity',

    (
        SELECT COUNT(*)
        FROM stg.Returns AS r
        LEFT JOIN stg.Order_Items AS oi
            ON r.Order_Item_ID = oi.Order_Item_ID
        WHERE r.Order_Item_ID IS NOT NULL
          AND oi.Order_Item_ID IS NULL
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Returns AS r
            LEFT JOIN stg.Order_Items AS oi
                ON r.Order_Item_ID = oi.Order_Item_ID
            WHERE r.Order_Item_ID IS NOT NULL
              AND oi.Order_Item_ID IS NULL
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Orphan return order-item references must be resolved.'
),


/* ================================================================================================
   C. Financial Validation
================================================================================================ */

(
    N'Products - Unit Price Less Than or Equal to Unit Cost',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Products
        WHERE Unit_Price <= Unit_Cost
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Products
            WHERE Unit_Price <= Unit_Cost
        ) = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END,

    N'Products without positive gross margin should be reviewed.'
),

(
    N'Order Items - Invalid Discount',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Order_Items
        WHERE Discount_Amount < 0
           OR Discount_Amount > Quantity * Unit_Price
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Order_Items
            WHERE Discount_Amount < 0
               OR Discount_Amount > Quantity * Unit_Price
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Invalid discounts must be investigated before profitability calculations.'
),

(
    N'Negative Shipping Cost',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Shipping_Costs
        WHERE Shipping_Cost < 0
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Shipping_Costs
            WHERE Shipping_Cost < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Shipping cost cannot be negative.'
),

(
    N'Negative Storage Cost',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Storage_Costs
        WHERE Storage_Cost < 0
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Storage_Costs
            WHERE Storage_Cost < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Storage cost cannot be negative.'
),

(
    N'Negative Customer Service Cost',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Customer_Service
        WHERE Service_Cost < 0
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Customer_Service
            WHERE Service_Cost < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Customer service cost cannot be negative.'
),

(
    N'Negative Return Cost',
    N'Financial Validation',

    (
        SELECT COUNT(*)
        FROM stg.Returns
        WHERE Return_Cost < 0
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Returns
            WHERE Return_Cost < 0
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Return cost cannot be negative.'
),


/* ================================================================================================
   D. Date Validation
================================================================================================ */

(
    N'Shipping Date Before Order Date',
    N'Date Validation',

    (
        SELECT COUNT(*)
        FROM stg.Shipping_Costs AS s
        INNER JOIN stg.Orders AS o
            ON s.Order_ID = o.Order_ID
        WHERE s.Shipping_Date < o.Order_Date
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Shipping_Costs AS s
            INNER JOIN stg.Orders AS o
                ON s.Order_ID = o.Order_ID
            WHERE s.Shipping_Date < o.Order_Date
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Shipping date must not precede the related order date.'
),

(
    N'Return Date Before Order Date',
    N'Date Validation',

    (
        SELECT COUNT(*)
        FROM stg.Returns AS r
        INNER JOIN stg.Orders AS o
            ON r.Order_ID = o.Order_ID
        WHERE r.Return_Date < o.Order_Date
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Returns AS r
            INNER JOIN stg.Orders AS o
                ON r.Order_ID = o.Order_ID
            WHERE r.Return_Date < o.Order_Date
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Return date must not precede the related order date.'
),


/* ================================================================================================
   E. Business Rules
================================================================================================ */

(
    N'Return Quantity Greater Than Ordered Quantity',
    N'Business Rules',

    (
        SELECT COUNT(*)
        FROM stg.Returns AS r
        INNER JOIN stg.Order_Items AS oi
            ON r.Order_Item_ID = oi.Order_Item_ID
        WHERE r.Return_Quantity > oi.Quantity
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Returns AS r
            INNER JOIN stg.Order_Items AS oi
                ON r.Order_Item_ID = oi.Order_Item_ID
            WHERE r.Return_Quantity > oi.Quantity
        ) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END,

    N'Return quantity must not exceed the original ordered quantity.'
),

(
    N'Customer Service - Customer Does Not Match Order',
    N'Business Rules',

    (
        SELECT COUNT(*)
        FROM stg.Customer_Service AS cs
        INNER JOIN stg.Orders AS o
            ON cs.Order_ID = o.Order_ID
        WHERE cs.Customer_ID <> o.Customer_ID
    ),

    CASE
        WHEN
        (
            SELECT COUNT(*)
            FROM stg.Customer_Service AS cs
            INNER JOIN stg.Orders AS o
                ON cs.Order_ID = o.Order_ID
            WHERE cs.Customer_ID <> o.Customer_ID
        ) = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END,

    N'Orders.Customer_ID will be used as the authoritative analytical customer reference.'
);


/* =================================================================================================
    05. Audit Summary
================================================================================================= */

SELECT
    Check_Category,
    COUNT(*) AS Total_Checks,

    SUM(
        CASE
            WHEN Status = 'PASS' THEN 1
            ELSE 0
        END
    ) AS Passed_Checks,

    SUM(
        CASE
            WHEN Status = 'WARNING' THEN 1
            ELSE 0
        END
    ) AS Warning_Checks,

    SUM(
        CASE
            WHEN Status = 'FAIL' THEN 1
            ELSE 0
        END
    ) AS Failed_Checks

FROM audit.Data_Quality_Audit

GROUP BY
    Check_Category

ORDER BY
    Check_Category;
GO


/* =================================================================================================
    06. Detailed Findings
================================================================================================= */

SELECT
    Audit_ID,
    Check_Name,
    Check_Category,
    Issue_Count,
    Status,
    Business_Action,
    Audit_Date

FROM audit.Data_Quality_Audit

WHERE Status <> 'PASS'

ORDER BY
    Audit_ID;
GO


/* =================================================================================================
    07. Overall Audit Status
================================================================================================= */

SELECT
    CASE
        WHEN EXISTS
        (
            SELECT 1
            FROM audit.Data_Quality_Audit
            WHERE Status = 'FAIL'
        )
        THEN 'FAIL'

        WHEN EXISTS
        (
            SELECT 1
            FROM audit.Data_Quality_Audit
            WHERE Status = 'WARNING'
        )
        THEN 'WARNING'

        ELSE 'PASS'
    END AS Overall_Audit_Status,

    COUNT(*) AS Total_Checks,

    SUM(
        CASE
            WHEN Status = 'PASS' THEN 1
            ELSE 0
        END
    ) AS Passed_Checks,

    SUM(
        CASE
            WHEN Status = 'WARNING' THEN 1
            ELSE 0
        END
    ) AS Warning_Checks,

    SUM(
        CASE
            WHEN Status = 'FAIL' THEN 1
            ELSE 0
        END
    ) AS Failed_Checks,

    SYSDATETIME() AS Audit_Run_Date

FROM audit.Data_Quality_Audit;
GO