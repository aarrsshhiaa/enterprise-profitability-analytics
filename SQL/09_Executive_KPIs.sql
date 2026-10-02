/* ================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization

   Script       : 09_Executive_KPIs.sql

   Purpose      : Create the final executive-level KPIs and management metrics
                  consumed by Power BI and executive reporting.

   Layer        : rpt

   Grain        : 1 Row = Overall Business KPI Snapshot

   Important    : Page 09 contains final Executive KPIs only.
                  Reporting Views are created in Page 08 and are not redefined here.

   Note (Project Review): Added True_Contribution_Profit and
   True_Contribution_Margin (Gross Profit - Cost-to-Serve) alongside the
   existing Contribution_Profit/Contribution_Margin, which do not net COGS
   and were retained unchanged for Power BI compatibility. See
   Documentation/KPI_Dictionary.md for the full definition of both metrics.

   KPI Scope:
       - Total Orders
       - Total Customers
       - Total Units Sold
       - Gross Revenue
       - Net Revenue
       - Product Cost
       - Gross Profit
       - Gross Margin
       - Shipping Cost
       - Customer Service Cost
       - Storage Cost
       - Return Cost
       - Total Cost-to-Serve
       - Contribution Profit  (legacy — does not net COGS)
       - Contribution Margin  (legacy — does not net COGS)
       - True Contribution Profit  (Gross Profit - Cost-to-Serve)
       - True Contribution Margin  (True Contribution Profit / Net Revenue)
       - Cost-to-Serve Rate
       - Return Quantity
       - Return Rate
       - Profitable Customers
       - Loss-Making Customers
       - Break-Even Customers
       - Profitable Customer Rate
       - Loss-Making Customer Rate

================================================================================================ */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* ================================================================================================
01. Executive KPI View

View         : rpt.vw_Executive_KPIs
Grain        : 1 Row = Overall Business KPI Snapshot

Purpose:
Central executive KPI layer consumed by Power BI.
================================================================================================ */

CREATE OR ALTER VIEW rpt.vw_Executive_KPIs
AS

WITH Completed_Revenue AS
(
    SELECT
        Order_ID,
        Customer_ID,

        SUM(Quantity * Unit_Price)
            AS Gross_Revenue,

        SUM(Net_Revenue)
            AS Net_Revenue,

        SUM(Product_Cost)
            AS Product_Cost,

        SUM(Gross_Profit)
            AS Gross_Profit,

        SUM(Quantity)
            AS Total_Units

    FROM rpt.vw_Revenue_Analytics

    WHERE Order_Status = N'Completed'

    GROUP BY
        Order_ID,
        Customer_ID
),

Order_Costs AS
(
    SELECT
        Order_ID,

        Shipping_Cost,
        Customer_Service_Cost,
        Storage_Cost,
        Returns_Cost,
        Total_Cost_to_Serve,
        Contribution_Profit,
        True_Contribution_Profit,
        Return_Quantity

    FROM rpt.vw_Cost_to_Serve
),

Business_Metrics AS
(
    SELECT

        /* ========================================================
           Volume
           ======================================================== */

        COUNT(DISTINCT r.Order_ID)
            AS Total_Orders,

        COUNT(DISTINCT r.Customer_ID)
            AS Total_Customers,

        SUM(r.Total_Units)
            AS Total_Units_Sold,

        /* ========================================================
           Revenue
           ======================================================== */

        SUM(r.Gross_Revenue)
            AS Gross_Revenue,

        SUM(r.Net_Revenue)
            AS Net_Revenue,

        /* ========================================================
           Product Cost & Gross Profit
           ======================================================== */

        SUM(r.Product_Cost)
            AS Product_Cost,

        SUM(r.Gross_Profit)
            AS Gross_Profit,

        /* ========================================================
           Cost-to-Serve Components
           ======================================================== */

        SUM(ISNULL(c.Shipping_Cost, 0))
            AS Shipping_Cost,

        SUM(ISNULL(c.Customer_Service_Cost, 0))
            AS Customer_Service_Cost,

        SUM(ISNULL(c.Storage_Cost, 0))
            AS Storage_Cost,

        SUM(ISNULL(c.Returns_Cost, 0))
            AS Return_Cost,

        SUM(ISNULL(c.Total_Cost_to_Serve, 0))
            AS Total_Cost_to_Serve,

        /* ========================================================
           Contribution Profitability
           ======================================================== */

        SUM(ISNULL(c.Contribution_Profit, 0))
            AS Contribution_Profit,

        SUM(ISNULL(c.True_Contribution_Profit, 0))
            AS True_Contribution_Profit,

        /* ========================================================
           Returns
           ======================================================== */

        SUM(ISNULL(c.Return_Quantity, 0))
            AS Return_Quantity

    FROM Completed_Revenue AS r

    LEFT JOIN Order_Costs AS c
        ON r.Order_ID = c.Order_ID
),

Customer_Metrics AS
(
    SELECT

        COUNT(*) AS Total_Customers,

        SUM(
            CASE
                WHEN Contribution_Profit > 0
                THEN 1
                ELSE 0
            END
        ) AS Profitable_Customers,

        SUM(
            CASE
                WHEN Contribution_Profit < 0
                THEN 1
                ELSE 0
            END
        ) AS Loss_Making_Customers,

        SUM(
            CASE
                WHEN Contribution_Profit = 0
                THEN 1
                ELSE 0
            END
        ) AS Break_Even_Customers,

        /* True (COGS-adjusted) equivalents — see KPI_Dictionary.md */
        SUM(
            CASE
                WHEN True_Contribution_Profit > 0
                THEN 1
                ELSE 0
            END
        ) AS True_Profitable_Customers,

        SUM(
            CASE
                WHEN True_Contribution_Profit < 0
                THEN 1
                ELSE 0
            END
        ) AS True_Loss_Making_Customers

    FROM rpt.vw_Customer_Profitability
)

SELECT

    /* ============================================================================================
       Volume KPIs
       ============================================================================================ */

    b.Total_Orders,

    b.Total_Customers,

    b.Total_Units_Sold,


    /* ============================================================================================
       Revenue KPIs
       ============================================================================================ */

    b.Gross_Revenue,

    b.Net_Revenue,


    /* ============================================================================================
       Product Cost & Gross Profit
       ============================================================================================ */

    b.Product_Cost,

    b.Gross_Profit,

    CASE
        WHEN b.Net_Revenue <> 0
        THEN b.Gross_Profit / b.Net_Revenue
        ELSE 0
    END AS Gross_Margin,


    /* ============================================================================================
       Cost-to-Serve Components
       ============================================================================================ */

    b.Shipping_Cost,

    b.Customer_Service_Cost,

    b.Storage_Cost,

    b.Return_Cost,

    b.Total_Cost_to_Serve,


    /* ============================================================================================
       Contribution Profitability
       (Legacy — does not net Product Cost / COGS. Preserved for Power BI compatibility.)
       ============================================================================================ */

    b.Contribution_Profit,

    CASE
        WHEN b.Net_Revenue <> 0
        THEN b.Contribution_Profit / b.Net_Revenue
        ELSE 0
    END AS Contribution_Margin,


    /* ============================================================================================
       True Contribution Profitability
       (Gross Profit - Total Cost-to-Serve. This is the metric that should be
       presented as the headline profitability KPI — see KPI_Dictionary.md.)
       ============================================================================================ */

    b.True_Contribution_Profit,

    CASE
        WHEN b.Net_Revenue <> 0
        THEN b.True_Contribution_Profit / b.Net_Revenue
        ELSE 0
    END AS True_Contribution_Margin,


    /* ============================================================================================
       Cost-to-Serve Rate
       ============================================================================================ */

    CASE
        WHEN b.Net_Revenue <> 0
        THEN b.Total_Cost_to_Serve / b.Net_Revenue
        ELSE 0
    END AS Cost_to_Serve_Rate,


    /* ============================================================================================
       Return KPIs
       ============================================================================================ */

    b.Return_Quantity,

    CASE
        WHEN b.Total_Units_Sold <> 0
        THEN
            CAST(b.Return_Quantity AS DECIMAL(18,4))
            / b.Total_Units_Sold
        ELSE 0
    END AS Return_Rate,


    /* ============================================================================================
       Customer Profitability KPIs
       ============================================================================================ */

    cm.Profitable_Customers,

    cm.Loss_Making_Customers,

    cm.Break_Even_Customers,

    CASE
        WHEN cm.Total_Customers <> 0
        THEN
            CAST(cm.Profitable_Customers AS DECIMAL(18,6))
            / cm.Total_Customers
        ELSE 0
    END AS Profitable_Customer_Rate,

    CASE
        WHEN cm.Total_Customers <> 0
        THEN
            CAST(cm.Loss_Making_Customers AS DECIMAL(18,6))
            / cm.Total_Customers
        ELSE 0
    END AS Loss_Making_Customer_Rate,

    /* ============================================================================================
       True (COGS-Adjusted) Customer Profitability KPIs
       ============================================================================================ */

    cm.True_Profitable_Customers,

    cm.True_Loss_Making_Customers,

    CASE
        WHEN cm.Total_Customers <> 0
        THEN
            CAST(cm.True_Profitable_Customers AS DECIMAL(18,6))
            / cm.Total_Customers
        ELSE 0
    END AS True_Profitable_Customer_Rate,

    CASE
        WHEN cm.Total_Customers <> 0
        THEN
            CAST(cm.True_Loss_Making_Customers AS DECIMAL(18,6))
            / cm.Total_Customers
        ELSE 0
    END AS True_Loss_Making_Customer_Rate

FROM Business_Metrics AS b

CROSS JOIN Customer_Metrics AS cm;
GO


/* ================================================================================================
02. Executive KPI Validation
================================================================================================ */

SELECT
    *
FROM rpt.vw_Executive_KPIs;
GO


/* ================================================================================================
03. Executive KPI Completion
================================================================================================ */

SELECT
    'Executive KPIs Created Successfully' AS Status,
    SYSDATETIME() AS Created_Date;
GO