# Enterprise Profitability & Cost-to-Serve Analytics

## Overview

This project analyzes customer profitability and operational Cost-to-Serve using SQL Server and Power BI.

The analysis works with transactional data to understand revenue, product costs, customer profitability, operational costs, and profit concentration. The project follows an end-to-end analytics workflow from raw data preparation and SQL analysis to Power BI reporting and business insights.

## Business Questions

The project focuses on questions such as:

* Which customers generate the most profit?
* Which customers have high operational costs?
* What are the major Cost-to-Serve drivers?
* Which customers are loss-making after accounting for product costs?
* How concentrated is profit across the customer base?
* Which areas require further cost and profitability analysis?

## Key Areas of Analysis

* Revenue and profitability analysis
* Customer profitability
* Cost-to-Serve analysis
* Customer segmentation
* Profit concentration and Pareto analysis
* Customer risk analysis
* Operational cost analysis
* Business KPI reporting

## Data

The project uses a synthetic enterprise dataset containing multiple interconnected tables covering:

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

The `dataset` folder contains the project data and data dictionary.

## Tools & Technologies

* SQL Server
* T-SQL
* SQL Views
* Data Quality & Validation
* Power BI
* DAX
* Data Modeling
* Power Query
* Microsoft Excel-compatible CSV data
* Markdown / PDF documentation

## Project Workflow

```text
Raw CSV Data
     ↓
SQL Server
     ↓
Data Cleaning & Validation
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

## SQL Analysis

The SQL layer covers:

* Database and table setup
* Data loading
* Data quality checks
* Validation and reconciliation
* Reporting views
* Customer profitability
* Cost-to-Serve analysis
* Customer segmentation
* Pareto analysis
* Customer risk analysis
* KPI calculations

The SQL scripts are available in the `SQL` folder.

## Power BI Dashboard

The Power BI report provides interactive analysis of:

* Revenue
* Contribution Profit
* Contribution Margin
* Cost-to-Serve
* Cost drivers
* Customer profitability
* Customer risk
* Profit concentration
* Customer-level performance

Dashboard screenshots are available in the `dashboard` folder.

## Business Insights

The analysis highlights the relationship between revenue, product costs, profitability, and operational Cost-to-Serve.

The major areas examined include customer service, shipping, storage, and returns. The accompanying `Insights.pdf` contains the detailed findings and business recommendations.

## Repository Structure

```text
├── dashboard/
│   └── Dashboard screenshots
│
├── dataset/
│   ├── Dataset files
│   └── Data_Dictionary.md
│
├── PowerBi/
│   └── Power BI report
│
├── SQL/
│   └── SQL analysis scripts
│
├── Insights.pdf
└── README.md
```

## Purpose

This repository demonstrates how transactional business data can be transformed into profitability and operational insights using SQL Server and Power BI.
