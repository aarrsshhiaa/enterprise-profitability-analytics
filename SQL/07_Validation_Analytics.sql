/* =================================================================================================
Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization

Script       : 07_Validation_Analytics.sql

Purpose      : Business-level validation, financial reconciliation,
               and analytical sanity checks after the Core layer is loaded.

Layer        : core / analytical validation

Note         : Section 14 was corrected during project review to include all
               four Cost-to-Serve components (previously omitted Storage and
               Returns) and to net Product Cost before Cost-to-Serve, matching
               the canonical definition in rpt.vw_Cost_to_Serve. Section 10 is
               labeled as a partial early sanity check to avoid being read as
               a competing definition.

================================================================================================= */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* =================================================================================================
01. Order Revenue Reconciliation
================================================================================================= */

SELECT
    'Order Revenue Reconciliation' AS Validation_Name,

    SUM(
        (oi.Quantity * oi.Unit_Price)
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Net_Order_Revenue,

    SUM(
        (oi.Quantity * p.Unit_Price)
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Product_List_Revenue,

    CASE
        WHEN
            SUM(
                (oi.Quantity * oi.Unit_Price)
                - ISNULL(oi.Discount_Amount, 0)
            )
            =
            SUM(
                (oi.Quantity * p.Unit_Price)
                - ISNULL(oi.Discount_Amount, 0)
            )
        THEN 'PASS'
        ELSE 'WARNING'
    END AS Validation_Status

FROM core.Order_Items AS oi

INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID;
GO


/* =================================================================================================
02. Negative Revenue Check
================================================================================================= */

SELECT
    'Negative Net Line Revenue' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Order_Items
WHERE
    (
        Quantity * Unit_Price
        - ISNULL(Discount_Amount, 0)
    ) < 0;
GO


/* =================================================================================================
03. Gross Profit Sanity Check
================================================================================================= */

SELECT
    'Negative Gross Profit Lines' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END AS Validation_Status

FROM core.Order_Items AS oi

INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID

WHERE
    (
        (
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        )
        -
        (
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        )
    ) < 0;
GO


/* =================================================================================================
04. Order-Level Financial Reconciliation
================================================================================================= */

SELECT
    o.Order_ID,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Net_Revenue,

    SUM(
        oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Product_Cost,

    SUM(
        (
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        )
        -
        (
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        )
    ) AS Gross_Profit

FROM core.Orders AS o

INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID

INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID

GROUP BY
    o.Order_ID;
GO


/* =================================================================================================
05. Shipping Cost Validation
================================================================================================= */

SELECT
    'Negative Shipping Cost' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Shipping_Costs

WHERE Shipping_Cost < 0;
GO


/* =================================================================================================
06. Storage Cost Validation
================================================================================================= */

SELECT
    'Negative Storage Cost' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Storage_Costs

WHERE Storage_Cost < 0;
GO


/* =================================================================================================
07. Customer Service Cost Validation
================================================================================================= */

SELECT
    'Negative Customer Service Cost' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Customer_Service

WHERE Service_Cost < 0;
GO


/* =================================================================================================
08. Return Cost Validation
================================================================================================= */

SELECT
    'Negative Return Cost' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Returns

WHERE Return_Cost < 0;
GO


/* =================================================================================================
09. Return Quantity vs Ordered Quantity
================================================================================================= */

SELECT
    'Return Quantity vs Ordered Quantity' AS Validation_Name,
    COUNT(*) AS Issue_Count,

    CASE
        WHEN COUNT(*) = 0
        THEN 'PASS'
        ELSE 'FAIL'
    END AS Validation_Status

FROM core.Returns AS r

INNER JOIN core.Order_Items AS oi
    ON r.Order_Item_ID = oi.Order_Item_ID

WHERE
    r.Return_Quantity > oi.Quantity;
GO


/* =================================================================================================
10. Customer Profitability Validation

Note: This is a partial, early sanity check (Revenue - Product_Cost - Shipping_Cost)
used only to catch gross data-entry problems before the full reporting layer exists.
It is not the authoritative Contribution Profit metric — see rpt.vw_Cost_to_Serve
and rpt.vw_Customer_Profitability (script 08) and the "Cost-to-Serve Analysis by
Customer" check above (§14) for the full, four-component definition.
================================================================================================= */

WITH CustomerFinancials AS
(
    SELECT
        o.Customer_ID,

        SUM(
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        ) AS Revenue,

        SUM(
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        ) AS Product_Cost,

        SUM(
            ISNULL(sc.Shipping_Cost, 0)
        ) AS Shipping_Cost

    FROM core.Orders AS o

    INNER JOIN core.Order_Items AS oi
        ON o.Order_ID = oi.Order_ID

    INNER JOIN core.Products AS p
        ON oi.Product_ID = p.Product_ID

    LEFT JOIN core.Shipping_Costs AS sc
        ON o.Order_ID = sc.Order_ID

    GROUP BY
        o.Customer_ID
)

SELECT
    'Customer Profitability Sanity Check' AS Validation_Name,

    COUNT(*) AS Customers_Analyzed,

    SUM(
        CASE
            WHEN Revenue - Product_Cost - Shipping_Cost < 0
            THEN 1
            ELSE 0
        END
    ) AS Negative_Profit_Customers,

    CASE
        WHEN
            SUM(
                CASE
                    WHEN Revenue - Product_Cost - Shipping_Cost < 0
                    THEN 1
                    ELSE 0
                END
            ) = 0
        THEN 'PASS'
        ELSE 'WARNING'
    END AS Validation_Status

FROM CustomerFinancials;
GO


/* =================================================================================================
11. Revenue by Order Status
================================================================================================= */

SELECT
    Order_Status,

    COUNT(DISTINCT o.Order_ID) AS Order_Count,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Net_Revenue

FROM core.Orders AS o

INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID

GROUP BY
    Order_Status

ORDER BY
    Net_Revenue DESC;
GO


/* =================================================================================================
12. Profitability by Customer Segment
================================================================================================= */

SELECT
    c.Customer_Segment,

    COUNT(DISTINCT c.Customer_ID) AS Customer_Count,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Revenue,

    SUM(
        oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Product_Cost,

    SUM(
        (
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        )
        -
        (
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        )
    ) AS Gross_Profit

FROM core.Customers AS c

INNER JOIN core.Orders AS o
    ON c.Customer_ID = o.Customer_ID

INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID

INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID

GROUP BY
    c.Customer_Segment

ORDER BY
    Gross_Profit DESC;
GO


/* =================================================================================================
13. Profitability by Region
================================================================================================= */

SELECT
    r.Region_Name,

    COUNT(DISTINCT o.Order_ID) AS Order_Count,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Revenue,

    SUM(
        oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Product_Cost,

    SUM(
        (
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        )
        -
        (
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        )
    ) AS Gross_Profit,

    CASE
        WHEN
            SUM(
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
            ) = 0
        THEN 0

        ELSE
            SUM(
                (
                    oi.Quantity * oi.Unit_Price
                    - ISNULL(oi.Discount_Amount, 0)
                )
                -
                (
                    oi.Quantity * ISNULL(p.Unit_Cost, 0)
                )
            )
            /
            SUM(
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
            )
    END AS Gross_Margin

FROM core.Regions AS r

INNER JOIN core.Orders AS o
    ON r.Region_ID = o.Region_ID

INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID

INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID

GROUP BY
    r.Region_Name

ORDER BY
    Gross_Profit DESC;
GO


/* =================================================================================================
14. Cost-to-Serve Analysis by Customer (Preliminary — Pre-Reporting-Layer)

Correction Note (Project Review):
This script runs before 08_Create_Reporting_Views.sql, so rpt.vw_Cost_to_Serve
does not exist yet and cannot be referenced here. The original version of this
check summed only Shipping_Cost + Service_Cost, silently omitting Storage_Cost
and Return_Cost. That made it a THIRD, contradictory definition of Cost-to-Serve
alongside the two used in the reporting layer. It has been corrected to include
all four cost components so it previews the same definition that
rpt.vw_Cost_to_Serve formally establishes in script 08. It also now nets
Product_Cost first (Gross Profit) before subtracting Cost-to-Serve, matching
the Contribution Profit formula in Data_Dictionary.md
(Contribution Profit = Gross Profit - Cost-to-Serve), rather than subtracting
Cost-to-Serve straight from Revenue.
================================================================================================= */

WITH RevenueAndProductCost AS
(
    SELECT
        o.Customer_ID,

        SUM(
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        ) AS Revenue,

        SUM(
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        ) AS Product_Cost

    FROM core.Orders AS o

    INNER JOIN core.Order_Items AS oi
        ON o.Order_ID = oi.Order_ID

    INNER JOIN core.Products AS p
        ON oi.Product_ID = p.Product_ID

    GROUP BY
        o.Customer_ID
),

ServiceCost AS
(
    SELECT
        Customer_ID,
        SUM(ISNULL(Service_Cost, 0)) AS Service_Cost

    FROM core.Customer_Service

    GROUP BY
        Customer_ID
),

ShippingCost AS
(
    SELECT
        o.Customer_ID,
        SUM(ISNULL(sc.Shipping_Cost, 0)) AS Shipping_Cost

    FROM core.Orders AS o

    INNER JOIN core.Shipping_Costs AS sc
        ON o.Order_ID = sc.Order_ID

    GROUP BY
        o.Customer_ID
),

StorageCost AS
(
    SELECT
        o.Customer_ID,
        SUM(ISNULL(st.Storage_Cost, 0)) AS Storage_Cost

    FROM core.Orders AS o

    INNER JOIN core.Order_Items AS oi
        ON o.Order_ID = oi.Order_ID

    INNER JOIN core.Storage_Costs AS st
        ON st.Warehouse_ID = o.Warehouse_ID
       AND st.Product_ID = oi.Product_ID

    GROUP BY
        o.Customer_ID
),

ReturnCost AS
(
    SELECT
        o.Customer_ID,
        SUM(ISNULL(r.Return_Cost, 0)) AS Return_Cost

    FROM core.Returns AS r

    INNER JOIN core.Orders AS o
        ON r.Order_ID = o.Order_ID

    GROUP BY
        o.Customer_ID
)

SELECT
    c.Customer_ID,
    c.Customer_Name,

    ISNULL(r.Revenue, 0) AS Revenue,
    ISNULL(r.Product_Cost, 0) AS Product_Cost,

    ISNULL(r.Revenue, 0) - ISNULL(r.Product_Cost, 0) AS Gross_Profit,

    ISNULL(s.Shipping_Cost, 0) AS Shipping_Cost,
    ISNULL(cs.Service_Cost, 0) AS Service_Cost,
    ISNULL(sto.Storage_Cost, 0) AS Storage_Cost,
    ISNULL(ret.Return_Cost, 0) AS Return_Cost,

    ISNULL(s.Shipping_Cost, 0)
    + ISNULL(cs.Service_Cost, 0)
    + ISNULL(sto.Storage_Cost, 0)
    + ISNULL(ret.Return_Cost, 0) AS Cost_to_Serve,

    (
        ISNULL(r.Revenue, 0) - ISNULL(r.Product_Cost, 0)
    )
    -
    (
        ISNULL(s.Shipping_Cost, 0)
        + ISNULL(cs.Service_Cost, 0)
        + ISNULL(sto.Storage_Cost, 0)
        + ISNULL(ret.Return_Cost, 0)
    ) AS Contribution_Profit

FROM core.Customers AS c

LEFT JOIN RevenueAndProductCost AS r
    ON c.Customer_ID = r.Customer_ID

LEFT JOIN ShippingCost AS s
    ON c.Customer_ID = s.Customer_ID

LEFT JOIN ServiceCost AS cs
    ON c.Customer_ID = cs.Customer_ID

LEFT JOIN StorageCost AS sto
    ON c.Customer_ID = sto.Customer_ID

LEFT JOIN ReturnCost AS ret
    ON c.Customer_ID = ret.Customer_ID

ORDER BY
    Contribution_Profit DESC;
GO


/* =================================================================================================
15. Return Rate Analysis
================================================================================================= */

SELECT
    'Return Rate Analysis' AS Analysis_Name,

    SUM(ISNULL(r.Return_Quantity, 0)) AS Returned_Units,

    SUM(ISNULL(oi.Quantity, 0)) AS Ordered_Units,

    CASE
        WHEN SUM(ISNULL(oi.Quantity, 0)) = 0
        THEN 0

        ELSE
            CAST(SUM(ISNULL(r.Return_Quantity, 0)) AS DECIMAL(18,4))
            /
            SUM(ISNULL(oi.Quantity, 0))
    END AS Return_Rate

FROM core.Returns AS r

INNER JOIN core.Order_Items AS oi
    ON r.Order_Item_ID = oi.Order_Item_ID;
GO


/* =================================================================================================
16. Executive Validation Summary
================================================================================================= */

SELECT
    'Validation & Analytics Completed' AS Validation_Status,

    SYSDATETIME() AS Validation_Date,

    (SELECT COUNT_BIG(*) FROM core.Orders)
        AS Total_Orders,

    (SELECT COUNT_BIG(*) FROM core.Order_Items)
        AS Total_Order_Items,

    (
        SELECT
            SUM(
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
            )
        FROM core.Order_Items AS oi
    ) AS Total_Net_Revenue,

    (
        SELECT
            SUM(
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
                -
                oi.Quantity * ISNULL(p.Unit_Cost, 0)
            )
        FROM core.Order_Items AS oi
        INNER JOIN core.Products AS p
            ON oi.Product_ID = p.Product_ID
    ) AS Total_Gross_Profit;
GO