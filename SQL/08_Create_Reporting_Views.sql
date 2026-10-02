/* ================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
   Script       : 08_Create_Reporting_Views.sql
   Purpose      : Create business-ready reporting views for Power BI and executive analytics.
   Layer        : rpt
   Note         : Project review added Gross_Profit / True_Contribution_Profit /
                  True_Contribution_Margin_Pct to vw_Cost_to_Serve and
                  vw_Customer_Profitability (existing columns preserved
                  unchanged for Power BI compatibility — see inline notes),
                  and marked vw_Customer_Cost_to_Serve as deprecated in
                  favor of the single canonical Cost-to-Serve definition.
================================================================================================ */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO

/* ================================================================================================
01. Create Reporting Schema
================================================================================================ */

IF SCHEMA_ID(N'rpt') IS NULL
BEGIN
    EXEC(N'CREATE SCHEMA rpt');
END;
GO

/* ================================================================================================
02. Revenue Analytics
View         : rpt.vw_Revenue_Analytics
Grain        : 1 Row = 1 Order Item
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Revenue_Analytics
AS
SELECT
    o.Order_ID,
    oi.Order_Item_ID,
    o.Order_Date,

    o.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    c.Industry,

    o.Region_ID,
    r.Region_Name,
    r.Country,
    r.Territory,

    o.Warehouse_ID,
    w.Warehouse_Name,

    o.Order_Channel,
    o.Order_Status,

    oi.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory,

    oi.Quantity,
    oi.Unit_Price,
    ISNULL(oi.Discount_Amount, 0) AS Discount_Amount,

    oi.Quantity * oi.Unit_Price AS Gross_Revenue,

    oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0) AS Net_Revenue,

    oi.Quantity * ISNULL(p.Unit_Cost, 0) AS Product_Cost,

    oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
        - oi.Quantity * ISNULL(p.Unit_Cost, 0) AS Gross_Profit,

    CASE
        WHEN
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0) <> 0
        THEN
            (
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
                - oi.Quantity * ISNULL(p.Unit_Cost, 0)
            )
            /
            (
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
            )
        ELSE 0
    END AS Gross_Margin_Pct

FROM core.Orders AS o
INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID
INNER JOIN core.Customers AS c
    ON o.Customer_ID = c.Customer_ID
INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID
INNER JOIN core.Regions AS r
    ON o.Region_ID = r.Region_ID
INNER JOIN core.Warehouses AS w
    ON o.Warehouse_ID = w.Warehouse_ID;
GO

/* ================================================================================================
03. Shipping Cost by Order
View         : rpt.vw_Shipping_Cost_By_Order
Grain        : 1 Row = 1 Order
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Shipping_Cost_By_Order
AS
SELECT
    Order_ID,
    SUM(ISNULL(Shipping_Cost, 0)) AS Shipping_Cost
FROM core.Shipping_Costs
GROUP BY Order_ID;
GO

/* ================================================================================================
04. Service Cost by Order
View         : rpt.vw_Service_Cost_By_Order
Grain        : 1 Row = 1 Order
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Service_Cost_By_Order
AS
SELECT
    Order_ID,
    SUM(ISNULL(Service_Cost, 0)) AS Customer_Service_Cost
FROM core.Customer_Service
GROUP BY Order_ID;
GO

/* ================================================================================================
05. Return Cost by Order Item
View         : rpt.vw_Return_Cost_By_Order_Item
Grain        : 1 Row = 1 Order Item
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Return_Cost_By_Order_Item
AS
SELECT
    Order_Item_ID,
    Order_ID,
    SUM(ISNULL(Return_Cost, 0)) AS Return_Cost,
    SUM(ISNULL(Return_Quantity, 0)) AS Return_Quantity
FROM core.Returns
GROUP BY
    Order_Item_ID,
    Order_ID;
GO

/* ================================================================================================
06. Storage Cost Allocation
View         : rpt.vw_Storage_Cost_Allocation
Grain        : 1 Row = 1 Completed Order Item
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Storage_Cost_Allocation
AS
WITH Storage_Cost AS
(
    SELECT
        YEAR(Cost_Date) AS Cost_Year,
        MONTH(Cost_Date) AS Cost_Month,
        Warehouse_ID,
        Product_ID,
        SUM(Storage_Cost) AS Total_Storage_Cost
    FROM core.Storage_Costs
    GROUP BY
        YEAR(Cost_Date),
        MONTH(Cost_Date),
        Warehouse_ID,
        Product_ID
),
Sold_Quantity AS
(
    SELECT
        YEAR(o.Order_Date) AS Order_Year,
        MONTH(o.Order_Date) AS Order_Month,
        o.Warehouse_ID,
        oi.Product_ID,
        SUM(oi.Quantity) AS Total_Quantity
    FROM core.Orders AS o
    INNER JOIN core.Order_Items AS oi
        ON o.Order_ID = oi.Order_ID
    WHERE o.Order_Status = N'Completed'
    GROUP BY
        YEAR(o.Order_Date),
        MONTH(o.Order_Date),
        o.Warehouse_ID,
        oi.Product_ID
),
Storage_Rate AS
(
    SELECT
        sc.Cost_Year,
        sc.Cost_Month,
        sc.Warehouse_ID,
        sc.Product_ID,
        sc.Total_Storage_Cost,
        sq.Total_Quantity,
        sc.Total_Storage_Cost
            / NULLIF(sq.Total_Quantity, 0)
            AS Storage_Cost_Per_Unit
    FROM Storage_Cost AS sc
    INNER JOIN Sold_Quantity AS sq
        ON sc.Cost_Year = sq.Order_Year
       AND sc.Cost_Month = sq.Order_Month
       AND sc.Warehouse_ID = sq.Warehouse_ID
       AND sc.Product_ID = sq.Product_ID
)
SELECT
    o.Order_ID,
    oi.Order_Item_ID,
    o.Order_Date,
    o.Warehouse_ID,
    oi.Product_ID,
    oi.Quantity,
    sr.Total_Storage_Cost,
    sr.Total_Quantity,
    sr.Storage_Cost_Per_Unit,
    oi.Quantity * sr.Storage_Cost_Per_Unit
        AS Allocated_Storage_Cost
FROM core.Orders AS o
INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID
INNER JOIN Storage_Rate AS sr
    ON sr.Cost_Year = YEAR(o.Order_Date)
   AND sr.Cost_Month = MONTH(o.Order_Date)
   AND sr.Warehouse_ID = o.Warehouse_ID
   AND sr.Product_ID = oi.Product_ID
WHERE o.Order_Status = N'Completed';
GO

/* ================================================================================================
07. Order Cost Components
View         : rpt.vw_Order_Cost_Components
Grain        : 1 Row = 1 Completed Order
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Order_Cost_Components
AS
WITH Completed_Orders AS
(
    SELECT DISTINCT
        Order_ID
    FROM rpt.vw_Revenue_Analytics
    WHERE Order_Status = N'Completed'
),
Shipping AS
(
    SELECT
        s.Order_ID,
        SUM(s.Shipping_Cost) AS Shipping_Cost
    FROM rpt.vw_Shipping_Cost_By_Order AS s
    INNER JOIN Completed_Orders AS o
        ON s.Order_ID = o.Order_ID
    GROUP BY s.Order_ID
),
Customer_Service AS
(
    SELECT
        cs.Order_ID,
        SUM(cs.Customer_Service_Cost) AS Customer_Service_Cost
    FROM rpt.vw_Service_Cost_By_Order AS cs
    INNER JOIN Completed_Orders AS o
        ON cs.Order_ID = o.Order_ID
    GROUP BY cs.Order_ID
),
Storage AS
(
    SELECT
        Order_ID,
        SUM(Allocated_Storage_Cost) AS Storage_Cost
    FROM rpt.vw_Storage_Cost_Allocation
    GROUP BY Order_ID
),
Returns AS
(
    SELECT
        r.Order_ID,
        SUM(r.Return_Cost) AS Returns_Cost,
        SUM(r.Return_Quantity) AS Return_Quantity
    FROM rpt.vw_Return_Cost_By_Order_Item AS r
    INNER JOIN Completed_Orders AS o
        ON r.Order_ID = o.Order_ID
    GROUP BY r.Order_ID
)
SELECT
    o.Order_ID,

    COALESCE(s.Shipping_Cost, 0) AS Shipping_Cost,
    COALESCE(cs.Customer_Service_Cost, 0) AS Customer_Service_Cost,
    COALESCE(st.Storage_Cost, 0) AS Storage_Cost,
    COALESCE(r.Returns_Cost, 0) AS Returns_Cost,
    COALESCE(r.Return_Quantity, 0) AS Return_Quantity

FROM Completed_Orders AS o
LEFT JOIN Shipping AS s
    ON o.Order_ID = s.Order_ID
LEFT JOIN Customer_Service AS cs
    ON o.Order_ID = cs.Order_ID
LEFT JOIN Storage AS st
    ON o.Order_ID = st.Order_ID
LEFT JOIN Returns AS r
    ON o.Order_ID = r.Order_ID;
GO

/* ================================================================================================
08. Cost-to-Serve
View         : rpt.vw_Cost_to_Serve
Grain        : 1 Row = 1 Completed Order

Correction Note (Project Review):
"Contribution_Profit" and "Contribution_Margin_Pct" below are PRESERVED
UNCHANGED from the original implementation because the live Power BI report
is already bound to these exact column names/values — changing them here
would silently break every visual in the .pbix.

However, these two columns were found NOT to subtract Product Cost (COGS).
They measure "Net Revenue minus Cost-to-Serve", not true contribution
profit, and the resulting ~99.5% margin is not a credible headline KPI.
Per Data_Dictionary.md, the correct formula is:
    Contribution Profit = Gross Profit - Cost-to-Serve
    Gross Profit        = Net Revenue - Product Cost (COGS)

Two new, correctly-named columns are added instead of overwriting the
existing ones: Gross_Profit, True_Contribution_Profit, and
True_Contribution_Margin_Pct. See Documentation/PowerBI_Documentation.md
for the manual steps required to surface these in the dashboard, and
Documentation/KPI_Dictionary.md for both definitions side by side.
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Cost_to_Serve
AS
SELECT
    r.Order_ID,
    r.Customer_ID,

    SUM(r.Net_Revenue) AS Net_Revenue,
    SUM(r.Product_Cost) AS Product_Cost,
    SUM(r.Gross_Profit) AS Gross_Profit,

    c.Shipping_Cost,
    c.Customer_Service_Cost,
    c.Storage_Cost,
    c.Returns_Cost,

    c.Shipping_Cost
        + c.Customer_Service_Cost
        + c.Storage_Cost
        + c.Returns_Cost AS Total_Cost_to_Serve,

    /* Preserved as-is: Net Revenue - Cost-to-Serve (does NOT net COGS) */
    SUM(r.Net_Revenue)
        -
        (
            c.Shipping_Cost
            + c.Customer_Service_Cost
            + c.Storage_Cost
            + c.Returns_Cost
        ) AS Contribution_Profit,

    CASE
        WHEN SUM(r.Net_Revenue) <> 0
        THEN
            (
                SUM(r.Net_Revenue)
                -
                (
                    c.Shipping_Cost
                    + c.Customer_Service_Cost
                    + c.Storage_Cost
                    + c.Returns_Cost
                )
            )
            / SUM(r.Net_Revenue)
        ELSE 0
    END AS Contribution_Margin_Pct,

    /* New: true contribution profit, netting COGS first (Gross Profit - Cost-to-Serve) */
    SUM(r.Gross_Profit)
        -
        (
            c.Shipping_Cost
            + c.Customer_Service_Cost
            + c.Storage_Cost
            + c.Returns_Cost
        ) AS True_Contribution_Profit,

    CASE
        WHEN SUM(r.Net_Revenue) <> 0
        THEN
            (
                SUM(r.Gross_Profit)
                -
                (
                    c.Shipping_Cost
                    + c.Customer_Service_Cost
                    + c.Storage_Cost
                    + c.Returns_Cost
                )
            )
            / SUM(r.Net_Revenue)
        ELSE 0
    END AS True_Contribution_Margin_Pct,

    c.Return_Quantity

FROM rpt.vw_Revenue_Analytics AS r
INNER JOIN rpt.vw_Order_Cost_Components AS c
    ON r.Order_ID = c.Order_ID
WHERE r.Order_Status = N'Completed'
GROUP BY
    r.Order_ID,
    r.Customer_ID,
    c.Shipping_Cost,
    c.Customer_Service_Cost,
    c.Storage_Cost,
    c.Returns_Cost,
    c.Return_Quantity;
GO

/* ================================================================================================
09. Customer Profitability
View         : rpt.vw_Customer_Profitability
Grain        : 1 Row = 1 Customer
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Customer_Profitability
AS
WITH Customer_Revenue AS
(
    SELECT
        Order_ID,
        Customer_ID,
        SUM(Net_Revenue) AS Net_Revenue
    FROM rpt.vw_Revenue_Analytics
    WHERE Order_Status = N'Completed'
    GROUP BY
        Order_ID,
        Customer_ID
),
Customer_Orders AS
(
    SELECT
        Customer_ID,
        COUNT(DISTINCT Order_ID) AS Total_Orders
    FROM Customer_Revenue
    GROUP BY Customer_ID
),
Customer_Costs AS
(
    SELECT
        r.Customer_ID,
        SUM(c.Shipping_Cost) AS Shipping_Cost,
        SUM(c.Customer_Service_Cost) AS Customer_Service_Cost,
        SUM(c.Storage_Cost) AS Storage_Cost,
        SUM(c.Returns_Cost) AS Returns_Cost,
        SUM(c.Total_Cost_to_Serve) AS Total_Cost_to_Serve,
        SUM(c.Product_Cost) AS Product_Cost,
        SUM(c.Gross_Profit) AS Gross_Profit
    FROM Customer_Revenue AS r
    INNER JOIN rpt.vw_Cost_to_Serve AS c
        ON r.Order_ID = c.Order_ID
    GROUP BY r.Customer_ID
),
Customer_Total_Revenue AS
(
    SELECT
        Customer_ID,
        SUM(Net_Revenue) AS Net_Revenue
    FROM Customer_Revenue
    GROUP BY Customer_ID
),
Customer_Details AS
(
    SELECT DISTINCT
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry
    FROM rpt.vw_Revenue_Analytics
    WHERE Order_Status = N'Completed'
)
SELECT
    d.Customer_ID,
    d.Customer_Name,
    d.Customer_Segment,
    d.Industry,

    o.Total_Orders,
    r.Net_Revenue,
    c.Product_Cost,
    c.Gross_Profit,

    c.Shipping_Cost,
    c.Customer_Service_Cost,
    c.Storage_Cost,
    c.Returns_Cost,

    c.Total_Cost_to_Serve,

    /* Preserved as-is (see rpt.vw_Cost_to_Serve note): does NOT net COGS */
    r.Net_Revenue
        - c.Total_Cost_to_Serve AS Contribution_Profit,

    CASE
        WHEN r.Net_Revenue <> 0
        THEN
            (
                r.Net_Revenue
                - c.Total_Cost_to_Serve
            )
            / r.Net_Revenue
        ELSE 0
    END AS Contribution_Margin_Pct,

    /* New: true contribution profit, netting COGS first */
    c.Gross_Profit
        - c.Total_Cost_to_Serve AS True_Contribution_Profit,

    CASE
        WHEN r.Net_Revenue <> 0
        THEN
            (
                c.Gross_Profit
                - c.Total_Cost_to_Serve
            )
            / r.Net_Revenue
        ELSE 0
    END AS True_Contribution_Margin_Pct

FROM Customer_Details AS d
INNER JOIN Customer_Orders AS o
    ON d.Customer_ID = o.Customer_ID
INNER JOIN Customer_Total_Revenue AS r
    ON d.Customer_ID = r.Customer_ID
INNER JOIN Customer_Costs AS c
    ON d.Customer_ID = c.Customer_ID;
GO

/* ================================================================================================
10. Customer Profitability Segmentation
View         : rpt.vw_Customer_Profitability_Segmentation
Grain        : 1 Row = 1 Customer
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Customer_Profitability_Segmentation
AS
WITH Customer_Metrics AS
(
    SELECT
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry,
        Total_Orders,
        Net_Revenue,
        Total_Cost_to_Serve,
        Contribution_Profit,
        Contribution_Margin_Pct,

        Total_Cost_to_Serve
            / NULLIF(Net_Revenue, 0)
            AS Cost_to_Serve_Ratio

    FROM rpt.vw_Customer_Profitability
),
Customer_Benchmarks AS
(
    SELECT
        AVG(Net_Revenue) AS Avg_Revenue,
        AVG(Contribution_Profit) AS Avg_Contribution_Profit,
        AVG(Cost_to_Serve_Ratio) AS Avg_Cost_to_Serve_Ratio
    FROM Customer_Metrics
)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    c.Industry,
    c.Total_Orders,
    c.Net_Revenue,
    c.Total_Cost_to_Serve,
    c.Cost_to_Serve_Ratio,
    c.Contribution_Profit,
    c.Contribution_Margin_Pct,

    CASE
        WHEN c.Contribution_Profit < 0
            THEN 'At-Risk Customer'

        WHEN c.Net_Revenue >= b.Avg_Revenue
         AND c.Contribution_Profit >= b.Avg_Contribution_Profit
            THEN 'Strategic Customer'

        WHEN c.Cost_to_Serve_Ratio > b.Avg_Cost_to_Serve_Ratio
            THEN 'High-Cost Customer'

        WHEN c.Contribution_Profit > 0
            THEN 'Profitable Customer'

        ELSE 'Unclassified'
    END AS Profitability_Segment

FROM Customer_Metrics AS c
CROSS JOIN Customer_Benchmarks AS b;
GO

/* ================================================================================================
11. Customer Pareto
View         : rpt.vw_Customer_Pareto
Grain        : 1 Row = 1 Customer
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Customer_Pareto
AS
WITH Customer_Ranking AS
(
    SELECT
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry,
        Total_Orders,
        Net_Revenue,
        Total_Cost_to_Serve,
        Contribution_Profit,
        Contribution_Margin_Pct,

        ROW_NUMBER() OVER
        (
            ORDER BY Contribution_Profit DESC
        ) AS Profit_Rank,

        SUM(Contribution_Profit) OVER
        (
            ORDER BY Contribution_Profit DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS Cumulative_Contribution_Profit,

        SUM(Contribution_Profit) OVER ()
            AS Total_Contribution_Profit

    FROM rpt.vw_Customer_Profitability
)
SELECT
    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,
    Total_Orders,
    Net_Revenue,
    Total_Cost_to_Serve,
    Contribution_Profit,
    Contribution_Margin_Pct,
    Profit_Rank,
    Cumulative_Contribution_Profit,
    Total_Contribution_Profit,

    CASE
        WHEN Total_Contribution_Profit <> 0
        THEN Cumulative_Contribution_Profit
             / Total_Contribution_Profit
        ELSE 0
    END AS Cumulative_Profit_Pct,

    CASE
        WHEN
            Cumulative_Contribution_Profit
            / NULLIF(Total_Contribution_Profit, 0) <= 0.80
            THEN 'Top 80% Profit Contributors'

        WHEN
            Cumulative_Contribution_Profit
            / NULLIF(Total_Contribution_Profit, 0) <= 0.95
            THEN 'Next 15% Profit Contributors'

        ELSE 'Bottom 5% Profit Contributors'
    END AS Pareto_Segment

FROM Customer_Ranking;
GO

/* ================================================================================================
12. Customer Risk Analysis
View         : rpt.vw_Customer_Risk_Analysis
Grain        : 1 Row = 1 Customer
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Customer_Risk_Analysis
AS
WITH Customer_Metrics AS
(
    SELECT
        Customer_ID,
        Customer_Name,
        Customer_Segment,
        Industry,
        Total_Orders,
        Net_Revenue,
        Total_Cost_to_Serve,
        Contribution_Profit,
        Contribution_Margin_Pct,

        Total_Cost_to_Serve
            / NULLIF(Net_Revenue, 0)
            AS Cost_to_Serve_Ratio

    FROM rpt.vw_Customer_Profitability
),
Benchmarks AS
(
    SELECT
        AVG(Cost_to_Serve_Ratio) AS Avg_Cost_to_Serve_Ratio,
        AVG(Contribution_Profit) AS Avg_Contribution_Profit
    FROM Customer_Metrics
)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    c.Industry,
    c.Total_Orders,
    c.Net_Revenue,
    c.Total_Cost_to_Serve,
    c.Cost_to_Serve_Ratio,
    c.Contribution_Profit,
    c.Contribution_Margin_Pct,

    CASE
        WHEN c.Contribution_Profit < 0
            THEN 'Loss-Making Customer'

        WHEN c.Contribution_Profit < b.Avg_Contribution_Profit
            THEN 'Below-Average Profit'

        ELSE 'Profitable Customer'
    END AS Profitability_Status,

    CASE
        WHEN c.Cost_to_Serve_Ratio > b.Avg_Cost_to_Serve_Ratio
            THEN 'High Cost-to-Serve'

        ELSE 'Efficient Cost-to-Serve'
    END AS Cost_Efficiency_Status

FROM Customer_Metrics AS c
CROSS JOIN Benchmarks AS b;
GO

/* ================================================================================================
13. Sales & Order Line Reporting
View         : rpt.vw_Sales_Order_Lines
Grain        : 1 Row = 1 Order Item
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Sales_Order_Lines
AS
SELECT
    oi.Order_Item_ID,
    oi.Order_ID,
    o.Order_Date,
    o.Order_Status,
    o.Order_Channel,

    o.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    c.Industry,

    o.Region_ID,
    r.Region_Name,
    r.Country,
    r.Territory,

    o.Warehouse_ID,
    w.Warehouse_Name,

    oi.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory,

    oi.Quantity,
    oi.Unit_Price,
    p.Unit_Cost AS Product_Unit_Cost,

    ISNULL(oi.Discount_Amount, 0) AS Discount_Amount,

    oi.Quantity * oi.Unit_Price AS Gross_Sales_Amount,

    ISNULL(oi.Discount_Amount, 0)
        AS Discount_Amount_Total,

    oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
        AS Net_Revenue,

    oi.Quantity * ISNULL(p.Unit_Cost, 0)
        AS Product_Cost,

    oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
        - oi.Quantity * ISNULL(p.Unit_Cost, 0)
        AS Gross_Profit,

    CASE
        WHEN
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0) = 0
        THEN 0
        ELSE
            (
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
                - oi.Quantity * ISNULL(p.Unit_Cost, 0)
            )
            /
            (
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
            )
    END AS Gross_Margin

FROM core.Order_Items AS oi
INNER JOIN core.Orders AS o
    ON oi.Order_ID = o.Order_ID
INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID
LEFT JOIN core.Customers AS c
    ON o.Customer_ID = c.Customer_ID
LEFT JOIN core.Regions AS r
    ON o.Region_ID = r.Region_ID
LEFT JOIN core.Warehouses AS w
    ON o.Warehouse_ID = w.Warehouse_ID;
GO

/* ================================================================================================
14. Product Profitability
View         : rpt.vw_Product_Profitability
Grain        : 1 Row = 1 Product
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Product_Profitability
AS
WITH Sales AS
(
    SELECT
        oi.Product_ID,
        SUM(oi.Quantity) AS Units_Sold,

        SUM(
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        ) AS Net_Revenue,

        SUM(
            oi.Quantity * ISNULL(p.Unit_Cost, 0)
        ) AS Product_Cost,

        COUNT(DISTINCT oi.Order_ID) AS Order_Count

    FROM core.Order_Items AS oi
    INNER JOIN core.Products AS p
        ON oi.Product_ID = p.Product_ID
    GROUP BY oi.Product_ID
),
Returns AS
(
    SELECT
        oi.Product_ID,
        SUM(ISNULL(r.Return_Quantity, 0)) AS Returned_Units,
        SUM(ISNULL(r.Return_Cost, 0)) AS Return_Cost
    FROM core.Returns AS r
    INNER JOIN core.Order_Items AS oi
        ON r.Order_Item_ID = oi.Order_Item_ID
    GROUP BY oi.Product_ID
)
SELECT
    p.Product_ID,
    p.Product_Name,
    p.Category,
    p.Subcategory,
    p.Unit_Cost,
    p.Unit_Price,

    ISNULL(s.Order_Count, 0) AS Order_Count,
    ISNULL(s.Units_Sold, 0) AS Units_Sold,
    ISNULL(s.Net_Revenue, 0) AS Net_Revenue,
    ISNULL(s.Product_Cost, 0) AS Product_Cost,

    ISNULL(s.Net_Revenue, 0)
        - ISNULL(s.Product_Cost, 0)
        AS Gross_Profit,

    CASE
        WHEN ISNULL(s.Net_Revenue, 0) = 0
        THEN 0
        ELSE
            (
                ISNULL(s.Net_Revenue, 0)
                - ISNULL(s.Product_Cost, 0)
            )
            / s.Net_Revenue
    END AS Gross_Margin,

    ISNULL(ret.Returned_Units, 0) AS Returned_Units,
    ISNULL(ret.Return_Cost, 0) AS Return_Cost,

    CASE
        WHEN ISNULL(s.Units_Sold, 0) = 0
        THEN 0
        ELSE
            CAST(ISNULL(ret.Returned_Units, 0) AS DECIMAL(18,4))
            / s.Units_Sold
    END AS Return_Rate

FROM core.Products AS p
LEFT JOIN Sales AS s
    ON p.Product_ID = s.Product_ID
LEFT JOIN Returns AS ret
    ON p.Product_ID = ret.Product_ID;
GO

/* ================================================================================================
15. Region Profitability
View         : rpt.vw_Region_Profitability
Grain        : 1 Row = 1 Region
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Region_Profitability
AS
SELECT
    r.Region_ID,
    r.Region_Name,
    r.Country,
    r.Territory,

    COUNT(DISTINCT o.Order_ID) AS Order_Count,
    COUNT(DISTINCT o.Customer_ID) AS Customer_Count,
    SUM(oi.Quantity) AS Units_Sold,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Net_Revenue,

    SUM(
        oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Product_Cost,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
        - oi.Quantity * ISNULL(p.Unit_Cost, 0)
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
                oi.Quantity * oi.Unit_Price
                - ISNULL(oi.Discount_Amount, 0)
                - oi.Quantity * ISNULL(p.Unit_Cost, 0)
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
    r.Region_ID,
    r.Region_Name,
    r.Country,
    r.Territory;
GO

/* ================================================================================================
16. Customer Cost-to-Serve [DEPRECATED — DO NOT USE]
View         : rpt.vw_Customer_Cost_to_Serve
Grain        : 1 Row = 1 Customer

Deprecation Note (Project Review):
This view is a second, INCONSISTENT definition of Cost-to-Serve: it omits
Storage_Cost (only sums Shipping + Service + Returns) and, unlike
rpt.vw_Cost_to_Serve, does not restrict to completed orders. It is not
referenced by any Power BI visual or by any other script in this project
(confirmed by inspecting the .pbix report layout). It is kept, rather than
deleted, only for backward compatibility in case of external references.
Use rpt.vw_Customer_Profitability for customer-level Cost-to-Serve instead —
it is built on the canonical rpt.vw_Cost_to_Serve definition.
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Customer_Cost_to_Serve
AS
WITH Revenue AS
(
    SELECT
        o.Customer_ID,
        SUM(
            oi.Quantity * oi.Unit_Price
            - ISNULL(oi.Discount_Amount, 0)
        ) AS Net_Revenue
    FROM core.Orders AS o
    INNER JOIN core.Order_Items AS oi
        ON o.Order_ID = oi.Order_ID
    GROUP BY o.Customer_ID
),
Shipping AS
(
    SELECT
        o.Customer_ID,
        SUM(ISNULL(sc.Shipping_Cost, 0)) AS Shipping_Cost
    FROM core.Orders AS o
    INNER JOIN core.Shipping_Costs AS sc
        ON o.Order_ID = sc.Order_ID
    GROUP BY o.Customer_ID
),
Service AS
(
    SELECT
        Customer_ID,
        SUM(ISNULL(Service_Cost, 0)) AS Service_Cost
    FROM core.Customer_Service
    GROUP BY Customer_ID
),
Returns AS
(
    SELECT
        o.Customer_ID,
        SUM(ISNULL(r.Return_Cost, 0)) AS Return_Cost
    FROM core.Returns AS r
    INNER JOIN core.Orders AS o
        ON r.Order_ID = o.Order_ID
    GROUP BY o.Customer_ID
)
SELECT
    c.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    c.Industry,

    ISNULL(r.Net_Revenue, 0) AS Net_Revenue,
    ISNULL(s.Shipping_Cost, 0) AS Shipping_Cost,
    ISNULL(cs.Service_Cost, 0) AS Service_Cost,
    ISNULL(ret.Return_Cost, 0) AS Return_Cost,

    ISNULL(s.Shipping_Cost, 0)
        + ISNULL(cs.Service_Cost, 0)
        + ISNULL(ret.Return_Cost, 0)
        AS Cost_to_Serve,

    CASE
        WHEN ISNULL(r.Net_Revenue, 0) = 0
        THEN 0
        ELSE
            (
                ISNULL(s.Shipping_Cost, 0)
                + ISNULL(cs.Service_Cost, 0)
                + ISNULL(ret.Return_Cost, 0)
            )
            / r.Net_Revenue
    END AS Cost_to_Serve_Rate

FROM core.Customers AS c
LEFT JOIN Revenue AS r
    ON c.Customer_ID = r.Customer_ID
LEFT JOIN Shipping AS s
    ON c.Customer_ID = s.Customer_ID
LEFT JOIN Service AS cs
    ON c.Customer_ID = cs.Customer_ID
LEFT JOIN Returns AS ret
    ON c.Customer_ID = ret.Customer_ID;
GO

/* ================================================================================================
17. Order Summary
View         : rpt.vw_Order_Summary
Grain        : 1 Row = 1 Order
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Order_Summary
AS
SELECT
    o.Order_ID,
    o.Order_Date,

    o.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,

    o.Region_ID,
    r.Region_Name,

    o.Warehouse_ID,
    w.Warehouse_Name,

    o.Order_Channel,
    o.Order_Status,

    COUNT(oi.Order_Item_ID) AS Order_Line_Count,
    SUM(oi.Quantity) AS Total_Units,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
    ) AS Net_Revenue,

    SUM(
        oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Product_Cost,

    SUM(
        oi.Quantity * oi.Unit_Price
        - ISNULL(oi.Discount_Amount, 0)
        - oi.Quantity * ISNULL(p.Unit_Cost, 0)
    ) AS Gross_Profit

FROM core.Orders AS o
INNER JOIN core.Order_Items AS oi
    ON o.Order_ID = oi.Order_ID
INNER JOIN core.Products AS p
    ON oi.Product_ID = p.Product_ID
LEFT JOIN core.Customers AS c
    ON o.Customer_ID = c.Customer_ID
LEFT JOIN core.Regions AS r
    ON o.Region_ID = r.Region_ID
LEFT JOIN core.Warehouses AS w
    ON o.Warehouse_ID = w.Warehouse_ID

GROUP BY
    o.Order_ID,
    o.Order_Date,
    o.Customer_ID,
    c.Customer_Name,
    c.Customer_Segment,
    o.Region_ID,
    r.Region_Name,
    o.Warehouse_ID,
    w.Warehouse_Name,
    o.Order_Channel,
    o.Order_Status;
GO

/* ================================================================================================
18. Reporting Layer Validation
================================================================================================ */

SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_SCHEMA = 'rpt'
ORDER BY TABLE_NAME;
GO

SELECT
    'rpt.vw_Revenue_Analytics' AS View_Name,
    COUNT_BIG(*) AS Row_Count
FROM rpt.vw_Revenue_Analytics

UNION ALL

SELECT 'rpt.vw_Shipping_Cost_By_Order', COUNT_BIG(*)
FROM rpt.vw_Shipping_Cost_By_Order

UNION ALL

SELECT 'rpt.vw_Service_Cost_By_Order', COUNT_BIG(*)
FROM rpt.vw_Service_Cost_By_Order

UNION ALL

SELECT 'rpt.vw_Return_Cost_By_Order_Item', COUNT_BIG(*)
FROM rpt.vw_Return_Cost_By_Order_Item

UNION ALL

SELECT 'rpt.vw_Storage_Cost_Allocation', COUNT_BIG(*)
FROM rpt.vw_Storage_Cost_Allocation

UNION ALL

SELECT 'rpt.vw_Order_Cost_Components', COUNT_BIG(*)
FROM rpt.vw_Order_Cost_Components

UNION ALL

SELECT 'rpt.vw_Cost_to_Serve', COUNT_BIG(*)
FROM rpt.vw_Cost_to_Serve

UNION ALL

SELECT 'rpt.vw_Customer_Profitability', COUNT_BIG(*)
FROM rpt.vw_Customer_Profitability

UNION ALL

SELECT 'rpt.vw_Customer_Profitability_Segmentation', COUNT_BIG(*)
FROM rpt.vw_Customer_Profitability_Segmentation

UNION ALL

SELECT 'rpt.vw_Customer_Pareto', COUNT_BIG(*)
FROM rpt.vw_Customer_Pareto

UNION ALL

SELECT 'rpt.vw_Customer_Risk_Analysis', COUNT_BIG(*)
FROM rpt.vw_Customer_Risk_Analysis

UNION ALL

SELECT 'rpt.vw_Sales_Order_Lines', COUNT_BIG(*)
FROM rpt.vw_Sales_Order_Lines

UNION ALL

SELECT 'rpt.vw_Product_Profitability', COUNT_BIG(*)
FROM rpt.vw_Product_Profitability

UNION ALL

SELECT 'rpt.vw_Region_Profitability', COUNT_BIG(*)
FROM rpt.vw_Region_Profitability

UNION ALL

SELECT 'rpt.vw_Customer_Cost_to_Serve', COUNT_BIG(*)
FROM rpt.vw_Customer_Cost_to_Serve

UNION ALL

SELECT 'rpt.vw_Order_Summary', COUNT_BIG(*)
FROM rpt.vw_Order_Summary

ORDER BY View_Name;
GO

SELECT
    'Reporting Views Created Successfully' AS Status,
    SYSDATETIME() AS Created_Date;
GO