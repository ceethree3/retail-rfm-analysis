# Customer Purchase Behavior & RFM Segmentation
**Tools:** SQLite, SQL, VS Code  
**Dataset:** UCI Online Retail II (541,910 transactions, 4,340 customers)

A SQL-based customer analytics project analyzing real eCommerce transaction data 
to segment customers by purchasing behavior and identify actionable retention opportunities.
## Business Objective
Retail businesses often treat all customers the same. This project uses SQL to 
identify who the best customers are, who is slipping away, and who has been lost, 
so marketing and retention efforts can be targeted where they matter most.

Core questions:
- Where is revenue coming from geographically?
- What does the customer base look like at scale?
- Which customers are Champions, Loyal, At Risk, or Lost?

## Dataset
- Source: UCI Machine Learning Repository, Online Retail II dataset
- Timeframe: December 2010 through December 2011
- Records: 541,910 transactions across 4,340 unique customers
- Geography: UK-based retailer with sales across 8 countries
- Note: InvoiceDate required significant cleaning due to non-standard M/D/YY 
  formatting. Built a clean_date conversion table using PRINTF and SUBSTR 
  before date calculations were possible.

## Tools Used
- SQLite for database creation and querying
- SQL for all analysis including joins, subqueries, aggregations, and CASE logic
- VS Code with SQLTools extension for query development
- Harvard CS50 SQL as the learning foundation for this project
## What I Built
Five SQL queries that answer real business questions:

1. Revenue by Country: Identified top 10 markets by total revenue using GROUP BY 
   and aggregations. UK dominates, with strong presence across Western Europe and 
   a notable outlier in Australia.

2. Business Scale Summary: Calculated total orders, unique customers, and revenue 
   in a single query. 20,728 orders, 4,340 customers, $10.6M in revenue. Average 
   order value of roughly $50 and average revenue per customer of roughly $2,450.

3. Top Customers by Spend: Ranked customers by total revenue and order count. 
   Revealed two distinct high-value profiles: bulk buyers with massive single 
   orders and frequent buyers with consistent purchasing behavior.

4. Purchase Frequency Distribution: Bucketed all customers by order count to 
   reveal a long-tail distribution. The majority of customers place fewer than 
   8 orders, indicating a large base of low-frequency buyers.

5. RFM Segmentation: Built a three-layer subquery scoring every customer on 
   Recency, Frequency, and Monetary value, then labeled each as Champion, Loyal, 
   At Risk, or Lost based on their combined score.

## Key Findings
- The top 10 countries account for the majority of revenue, with the UK generating 
  the largest share by a significant margin
- Customer 12346 spent $77K in a single order over a year ago and never returned, 
  a high-value lost customer that monetary analysis alone would miss
- The majority of customers fall into low purchase frequency buckets, suggesting 
  strong opportunity for first-time buyer conversion programs
- Champions and Loyal customers represent the retention priority, while the large 
  Lost segment points to a win-back campaign opportunity
- Real-world data required hands-on cleaning before analysis was possible, 
  reflecting standard data integrity work in production environments

## Skills Demonstrated
- SQL query writing: aggregations, GROUP BY, HAVING, ORDER BY, LIMIT
- Subqueries and multi-layer query architecture
- Date parsing and data type conversion in SQLite
- Customer segmentation using CASE logic and RFM methodology
- Data quality investigation and cleaning
- Translating query results into business recommendations
