/* ================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
   Script       : 10_Profitability_and_Cost_to_Serve_Analysis.sql
   Purpose      : Detailed profitability, Cost-to-Serve, customer segmentation,
                  Pareto concentration, and customer risk analysis.
   Layer        : Analytics
================================================================================================ */

USE Enterprise_Profitability;
GO

SET NOCOUNT ON;
GO


/* ================================================================================================
01. Cost-to-Serve Drivers
================================================================================================ */

WITH Cost_Components AS
(
    SELECT
        'Shipping' AS Cost_Component,
        SUM(Shipping_Cost) AS Total_Cost
    FROM rpt.vw_Cost_to_Serve

    UNION ALL

    SELECT
        'Storage',
        SUM(Storage_Cost)
    FROM rpt.vw_Cost_to_Serve

    UNION ALL

    SELECT
        'Customer Service',
        SUM(Customer_Service_Cost)
    FROM rpt.vw_Cost_to_Serve

    UNION ALL

    SELECT
        'Returns',
        SUM(Returns_Cost)
    FROM rpt.vw_Cost_to_Serve
),

Total_Cost AS
(
    SELECT
        SUM(Total_Cost_to_Serve) AS Total_Cost_to_Serve,
        COUNT(*) AS Total_Orders
    FROM rpt.vw_Cost_to_Serve
)

SELECT

    c.Cost_Component,

    c.Total_Cost,

    c.Total_Cost
        / NULLIF(t.Total_Cost_to_Serve, 0)
        AS Cost_Share_Pct,

    c.Total_Cost
        / NULLIF(t.Total_Orders, 0)
        AS Avg_Cost_Per_Order

FROM Cost_Components AS c

CROSS JOIN Total_Cost AS t

ORDER BY
    c.Total_Cost DESC;
GO


/* ================================================================================================
02. Profitability by Customer Segment
================================================================================================ */

SELECT

    Customer_Segment,

    COUNT(*) AS Customer_Count,

    SUM(Total_Orders) AS Total_Orders,

    SUM(Net_Revenue) AS Total_Revenue,

    SUM(Total_Cost_to_Serve)
        AS Total_Cost_to_Serve,

    SUM(Contribution_Profit)
        AS Total_Contribution_Profit,

    SUM(Total_Cost_to_Serve)
        / NULLIF(SUM(Net_Revenue), 0)
        AS Cost_to_Serve_Ratio,

    SUM(Contribution_Profit)
        / NULLIF(SUM(Net_Revenue), 0)
        AS Contribution_Margin

FROM rpt.vw_Customer_Profitability

GROUP BY
    Customer_Segment

ORDER BY
    Total_Contribution_Profit DESC;
GO


/* ================================================================================================
03. Profitability by Industry
================================================================================================ */

SELECT

    Industry,

    COUNT(*) AS Customer_Count,

    SUM(Total_Orders) AS Total_Orders,

    SUM(Net_Revenue) AS Total_Revenue,

    SUM(Total_Cost_to_Serve)
        AS Total_Cost_to_Serve,

    SUM(Contribution_Profit)
        AS Total_Contribution_Profit,

    SUM(Total_Cost_to_Serve)
        / NULLIF(SUM(Net_Revenue), 0)
        AS Cost_to_Serve_Ratio,

    SUM(Contribution_Profit)
        / NULLIF(SUM(Net_Revenue), 0)
        AS Contribution_Margin

FROM rpt.vw_Customer_Profitability

GROUP BY
    Industry

ORDER BY
    Total_Contribution_Profit DESC;
GO


/* ================================================================================================
04. Top 20 Most Profitable Customers
================================================================================================ */

SELECT TOP 20

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Contribution_Profit,

    Contribution_Margin_Pct

FROM rpt.vw_Customer_Profitability

ORDER BY
    Contribution_Profit DESC;
GO


/* ================================================================================================
05. Bottom 20 Customers by Contribution Profit
================================================================================================ */

SELECT TOP 20

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Contribution_Profit,

    Contribution_Margin_Pct

FROM rpt.vw_Customer_Profitability

ORDER BY
    Contribution_Profit ASC;
GO


/* ================================================================================================
06. Top 20 Customers by Cost-to-Serve
================================================================================================ */

SELECT TOP 20

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Total_Cost_to_Serve
        / NULLIF(Net_Revenue, 0)
        AS Cost_to_Serve_Ratio,

    Contribution_Profit,

    Contribution_Margin_Pct

FROM rpt.vw_Customer_Profitability

ORDER BY
    Total_Cost_to_Serve DESC;
GO


/* ================================================================================================
07. Customer Profit Concentration
================================================================================================ */

SELECT

    Pareto_Segment,

    COUNT(*) AS Customer_Count,

    SUM(Net_Revenue)
        AS Total_Revenue,

    SUM(Total_Cost_to_Serve)
        AS Total_Cost_to_Serve,

    SUM(Contribution_Profit)
        AS Total_Contribution_Profit,

    AVG(Contribution_Margin_Pct)
        AS Avg_Contribution_Margin

FROM rpt.vw_Customer_Pareto

GROUP BY
    Pareto_Segment

ORDER BY
    Total_Contribution_Profit DESC;
GO


/* ================================================================================================
08. Profit Concentration Summary
================================================================================================ */

SELECT

    COUNT(*) AS Total_Customers,

    SUM(Contribution_Profit)
        AS Total_Contribution_Profit,

    MAX(Cumulative_Profit_Pct)
        AS Max_Cumulative_Profit_Pct

FROM rpt.vw_Customer_Pareto;
GO


/* ================================================================================================
09. At-Risk / Loss-Making Customers
================================================================================================ */

SELECT

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Cost_to_Serve_Ratio,

    Contribution_Profit,

    Contribution_Margin_Pct,

    Profitability_Status,

    Cost_Efficiency_Status

FROM rpt.vw_Customer_Risk_Analysis

WHERE Profitability_Status = 'Loss-Making Customer'

ORDER BY
    Contribution_Profit ASC;
GO


/* ================================================================================================
10. High Cost-to-Serve Customers
================================================================================================ */

SELECT TOP 20

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Cost_to_Serve_Ratio,

    Contribution_Profit,

    Contribution_Margin_Pct,

    Profitability_Status,

    Cost_Efficiency_Status

FROM rpt.vw_Customer_Risk_Analysis

WHERE Cost_Efficiency_Status = 'High Cost-to-Serve'

ORDER BY
    Cost_to_Serve_Ratio DESC;
GO


/* ================================================================================================
11. High-Cost + Below-Average Profit Customers
================================================================================================ */

SELECT TOP 20

    Customer_ID,
    Customer_Name,
    Customer_Segment,
    Industry,

    Total_Orders,

    Net_Revenue,

    Total_Cost_to_Serve,

    Cost_to_Serve_Ratio,

    Contribution_Profit,

    Contribution_Margin_Pct,

    Profitability_Status,

    Cost_Efficiency_Status

FROM rpt.vw_Customer_Risk_Analysis

WHERE Profitability_Status = 'Below-Average Profit'
  AND Cost_Efficiency_Status = 'High Cost-to-Serve'

ORDER BY
    Cost_to_Serve_Ratio DESC;
GO


/* ================================================================================================
12. Customer Profitability Segmentation
================================================================================================ */

SELECT

    Profitability_Segment,

    COUNT(*) AS Customer_Count,

    SUM(Net_Revenue)
        AS Total_Revenue,

    SUM(Total_Cost_to_Serve)
        AS Total_Cost_to_Serve,

    SUM(Contribution_Profit)
        AS Total_Contribution_Profit,

    AVG(Contribution_Margin_Pct)
        AS Avg_Contribution_Margin

FROM rpt.vw_Customer_Profitability_Segmentation

GROUP BY
    Profitability_Segment

ORDER BY
    Total_Contribution_Profit DESC;
GO


/* ================================================================================================
13. Customer Profitability Analysis Completion
================================================================================================ */

SELECT
    'Profitability and Cost-to-Serve Analysis Completed Successfully'
        AS Status,
    SYSDATETIME()
        AS Completed_Date;
GO