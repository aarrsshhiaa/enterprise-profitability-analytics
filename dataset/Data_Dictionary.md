# Data Dictionary — Enterprise Financial Profitability & Cost-to-Serve Optimization

Synthetic dataset for an end-to-end SQL Server + Power BI portfolio project.
Time period: **2022-01-01 to 2025-12-31** (Customers can date back to 2019).
Encoding: UTF-8, comma-delimited, header row, no index column.

---

## 1. Regions.csv (30 rows)
| Column | Type | Description |
|---|---|---|
| Region_ID | INT (PK) | Unique region identifier |
| Region_Name | TEXT | City-based sales region name |
| Country | TEXT | Country the region belongs to (USA, Canada, UK, Germany, France, UAE, Australia, Japan, India, Brazil) |
| Territory | TEXT | Continental grouping (North America, Europe, Middle East, APAC, South America) |

## 2. Warehouses.csv (20 rows)
| Column | Type | Description |
|---|---|---|
| Warehouse_ID | INT (PK) | Unique warehouse identifier |
| Warehouse_Name | TEXT | Warehouse display name |
| Region_ID | INT (FK → Regions) | Region where the warehouse is located |
| Capacity | INT | Maximum unit storage capacity |

## 3. Customers.csv (10,000 rows)
| Column | Type | Description |
|---|---|---|
| Customer_ID | INT (PK) | Unique customer identifier |
| Customer_Name | TEXT | Unique company name |
| Customer_Segment | TEXT | Enterprise (15%), Mid-Market (35%), SMB (50%) |
| Industry | TEXT | Technology, Healthcare, Finance, Manufacturing, Retail, Education, Professional Services |
| Region_ID | INT (FK → Regions) | Customer's home region |
| Customer_Since | DATE | Account start date (2019-01-01 to 2025-12-31) |

*Business logic:* Enterprise customers are weighted to place ~6x more orders than SMB customers and receive larger average discounts (~10% vs ~7.5%).

## 4. Products.csv (1,000 rows)
| Column | Type | Description |
|---|---|---|
| Product_ID | INT (PK) | Unique product identifier |
| Product_Name | TEXT | Product display name |
| Category | TEXT | Technology, Office, Industrial, Consumer, Services |
| Subcategory | TEXT | Category-specific subcategory (e.g., Laptops, Furniture, Tools) |
| Unit_Cost | DECIMAL | Base product cost (COGS basis), varies by category |
| Unit_Price | DECIMAL | List price = Unit_Cost × 1.2–1.8 |

*Business logic:* Each product has an underlying "popularity" weight driving order frequency and storage volume — creating natural high-revenue/low-margin and low-revenue/high-margin product patterns.

## 5. Orders.csv (250,000 rows)
| Column | Type | Description |
|---|---|---|
| Order_ID | INT (PK) | Unique order identifier |
| Order_Date | DATE | 2022-01-01 to 2025-12-31, weighted toward later years (growth trend) |
| Customer_ID | INT (FK → Customers) | Ordering customer |
| Region_ID | INT (FK → Regions) | Matches the customer's home region |
| Warehouse_ID | INT (FK → Warehouses) | Fulfilling warehouse (preferentially within the order's region) |
| Order_Channel | TEXT | Online (50%), Direct (30%), Partner (20%) |
| Order_Status | TEXT | Completed (91%), Cancelled (4%), Returned (5%) |

## 6. Order_Items.csv (512,515 rows)
| Column | Type | Description |
|---|---|---|
| Order_Item_ID | INT (PK) | Unique order line identifier |
| Order_ID | INT (FK → Orders) | Parent order (1–4 lines per order) |
| Product_ID | INT (FK → Products) | Ordered product |
| Quantity | INT | Units ordered (1–10) |
| Unit_Price | DECIMAL | Actual transaction unit price (≈ product list price ± 5%) |
| Discount_Amount | DECIMAL | Dollar discount on the line; Enterprise/Mid-Market customers receive systematically higher discount rates |

**Derived measures:**
- Gross Line Revenue = `Quantity × Unit_Price`
- Net Line Revenue = `Quantity × Unit_Price − Discount_Amount`

## 7. Shipping_Costs.csv (250,000 rows)
| Column | Type | Description |
|---|---|---|
| Shipping_ID | INT (PK) | Unique shipping record identifier |
| Order_ID | INT (FK → Orders) | One shipping record per order |
| Shipping_Date | DATE | Order_Date + 1–5 days |
| Shipping_Method | TEXT | Standard (60%), Express (30%), Same-Day (10%) |
| Shipping_Cost | DECIMAL | Standard < Express < Same-Day; scales slightly with line count |

## 8. Storage_Costs.csv (119,808 rows)
| Column | Type | Description |
|---|---|---|
| Storage_ID | INT (PK) | Unique storage cost record |
| Warehouse_ID | INT (FK → Warehouses) | Storing warehouse |
| Product_ID | INT (FK → Products) | Stored product (each product held in 2–3 warehouses) |
| Cost_Date | DATE | First of month, 2022-01-01 to 2025-12-01 |
| Storage_Cost | DECIMAL | Monthly cost; scales with product cost/popularity and includes seasonal variation |

## 9. Customer_Service.csv (120,000 rows)
| Column | Type | Description |
|---|---|---|
| Service_ID | INT (PK) | Unique service interaction identifier |
| Customer_ID | INT (FK → Customers) | Customer requesting service |
| Order_ID | INT (FK → Orders) | Related order (belongs to the same customer) |
| Service_Date | DATE | Order_Date + 1–44 days |
| Service_Type | TEXT | Support (45%), Complaint (20%), Technical (25%), Billing (10%) |
| Service_Cost | DECIMAL | Complaint/Technical cost more on average; Enterprise customers incur a cost multiplier |

*Business logic:* A subset of customers is deliberately heavy service users (Pareto-distributed weighting), enabling "High Revenue + High Service Cost + Low Profitability" analysis.

## 10. Returns.csv (25,276 rows, ~4.9% of order items)
| Column | Type | Description |
|---|---|---|
| Return_ID | INT (PK) | Unique return record |
| Order_ID | INT (FK → Orders) | Order the return belongs to |
| Order_Item_ID | INT (FK → Order_Items) | Specific line item returned |
| Return_Date | DATE | Order_Date + 3–29 days |
| Return_Quantity | INT | ≤ originally ordered Quantity |
| Return_Reason | TEXT | Damaged, Wrong Item, Customer Preference, Late Delivery, Quality Issue |
| Return_Cost | DECIMAL | Scales with Return_Quantity |

*Business logic:* Return rates are category-skewed — Technology and Consumer products return more often than Office, Industrial, or Services.

---

## Suggested Calculated Measures (for Power BI / SQL)

| Measure | Formula |
|---|---|
| Gross Revenue | SUM(Order_Items.Quantity × Order_Items.Unit_Price) |
| Discount Amount | SUM(Order_Items.Discount_Amount) |
| Net Revenue | Gross Revenue − Discount Amount |
| Product Cost / COGS | SUM(Order_Items.Quantity × Products.Unit_Cost) |
| Gross Profit | Net Revenue − COGS |
| Gross Margin % | Gross Profit / Net Revenue |
| Total Cost-to-Serve | Shipping_Cost + Storage_Cost (allocated) + Customer_Service_Cost + Return_Cost |
| Contribution Profit | Gross Profit − Total Cost-to-Serve |
| Contribution Margin % | Contribution Profit / Net Revenue |
| Revenue per Customer | Net Revenue / COUNT(DISTINCT Customer_ID) |
| Cost-to-Serve per Customer | Total Cost-to-Serve / COUNT(DISTINCT Customer_ID) |

## Suggested SQL Server Relationships (Star-Schema-Ready)
- `Orders.Customer_ID → Customers.Customer_ID`
- `Orders.Region_ID → Regions.Region_ID`
- `Orders.Warehouse_ID → Warehouses.Warehouse_ID`
- `Order_Items.Order_ID → Orders.Order_ID`
- `Order_Items.Product_ID → Products.Product_ID`
- `Shipping_Costs.Order_ID → Orders.Order_ID`
- `Storage_Costs.Warehouse_ID → Warehouses.Warehouse_ID`, `Storage_Costs.Product_ID → Products.Product_ID`
- `Customer_Service.Customer_ID → Customers.Customer_ID`, `Customer_Service.Order_ID → Orders.Order_ID`
- `Returns.Order_ID → Orders.Order_ID`, `Returns.Order_Item_ID → Order_Items.Order_Item_ID`

All foreign keys have been programmatically validated (zero orphaned records), and all row-count, uniqueness, date-range, and non-negativity checks passed prior to export.
