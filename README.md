# Enterprise Profitability & Cost-to-Serve Analytics

An end-to-end **SQL Server + Power BI** analytics project focused on customer profitability, Cost-to-Serve, operational cost drivers, and business performance.

## Project Overview

Revenue alone does not show whether customers are truly profitable. This project analyzes transactional and operational data to understand:

* Customer profitability
* Contribution profit and margin
* Cost-to-Serve
* Operational cost drivers
* Customer segmentation
* Profit concentration
* Customer risk
* Business performance

The workflow moves from raw CSV data through **SQL Server data preparation and validation**, analytical SQL views, and a **Power BI dashboard** for interactive business analysis.

## Business Questions

The analysis focuses on questions such as:

* Which customers generate the highest contribution profit?
* Which customers have disproportionately high Cost-to-Serve?
* What are the major operational cost drivers?
* Which customers are loss-making after accounting for product cost?
* How concentrated is profit across the customer base?
* Which customers require further profitability or cost review?

## Key Areas of Analysis

### Customer Profitability

Analysis of customer-level revenue, costs, contribution profit, and profitability differences across customer segments and industries.

### Cost-to-Serve

Analysis of operational costs associated with:

* Customer Service
* Shipping
* Storage
* Returns

### Customer Segmentation

Customers are analyzed based on profitability and cost efficiency to identify different business segments.

### Pareto Analysis

Profit concentration is analyzed to understand how contribution profit is distributed across the customer base.

### Customer Risk

The analysis identifies customers requiring closer attention based on profitability and cost characteristics.

---

## Data

The project uses a **synthetic enterprise dataset** containing interconnected tables for:

* Regions
* Warehouses
* Customers
* Products
* Orders
* Order Items
* Shipping Costs
* Storage Costs
* Customer Service
* Returns

The dataset covers transactional and operational information required for profitability and Cost-to-Serve analysis.

📂 **[View Dataset](dataset/)**
📄 **[View Data Dictionary](dataset/Data_Dictionary.md)**

---

## Project Workflow

```text
Raw CSV Data
      ↓
SQL Server
      ↓
Data Quality & Validation
      ↓
Analytical SQL Views
      ↓
Profitability & Cost Analysis
      ↓
Power BI Data Model
      ↓
Interactive Dashboard
      ↓
Business Insights
```

---

## SQL Analysis

The SQL layer covers:

* Database and table setup
* Data loading
* Data quality checks
* Validation and reconciliation
* Analytical views
* Customer profitability
* Cost-to-Serve analysis
* Customer segmentation
* Pareto analysis
* Customer risk analysis
* KPI calculations

📂 **[View SQL Scripts](SQL/)**

---

## Power BI Dashboard

The Power BI report provides an interactive view of profitability and Cost-to-Serve performance.

The analysis includes:

* Revenue
* Contribution Profit
* Contribution Margin
* Cost-to-Serve
* Cost drivers
* Customer profitability
* Customer risk
* Profit concentration
* Customer-level analysis

📊 **[View Power BI Files](PowerBi/)**

🖼️ **[View Dashboard Screenshots](dashboard/)**

---

## Business Insights

The project examines the relationship between revenue, product costs, profitability, and operational Cost-to-Serve.

The detailed findings and recommendations are provided in the accompanying insights report.

📄 **[View Business Insights](Insights.pdf)**

---

## Data Quality & Validation

The project includes validation checks covering:

* Uniqueness
* Primary and foreign key relationships
* Referential integrity
* Financial validity
* Date validity
* Business-rule validation
* Transactional row-count reconciliation

These checks help ensure that the analytical results are based on internally consistent data.

---

## Analytical Concepts

The project uses the following key business metrics and concepts:

* Revenue
* Product Cost / COGS
* Gross Profit
* Contribution Profit
* Contribution Margin
* Cost-to-Serve
* Cost-to-Serve Ratio
* Customer Profitability
* Customer Segmentation
* Pareto Profit Concentration
* Customer Risk

---

## Repository Structure

* 📊 **[Dashboard](dashboard/)** — Power BI dashboard screenshots
* 🗃️ **[Dataset](dataset/)** — CSV datasets and data dictionary
* 📈 **[Power BI](PowerBi/)** — Power BI report files
* 🧮 **[SQL](SQL/)** — SQL Server analysis scripts
* 📄 **[Insights](Insights.pdf)** — Business insights and recommendations

---

## Tools & Technologies

* **SQL Server**
* **T-SQL**
* **SQL Views**
* **Data Quality & Validation**
* **Power BI**
* **DAX**
* **Data Modeling**
* **Interactive Dashboards**
* **CSV / Relational Data**
* **Markdown / PDF Documentation**

---

## End-to-End Analytics Workflow

This project demonstrates how raw transactional data can be transformed into business insights through:

**Data → SQL Analysis → Data Validation → Profitability Modeling → Power BI → Business Insights**

The focus is on connecting technical data analysis with business questions around profitability, operational efficiency, and customer value.

---

## Project Files

📂 **[Dashboard Screenshots](dashboard/)**
📂 **[Dataset](dataset/)**
📂 **[Power BI Report](PowerBi/)**
📂 **[SQL Analysis](SQL/)**
📄 **[Business Insights Report](Insights.pdf)**

