SELECT Country,
        ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS total_revenue
FROM Sales
WHERE CAST(Quantity AS REAL) > 0
GROUP BY Country
ORDER BY total_revenue DESC
LIMIT 10;
-- this query calculates the total revenue for each country by multiplying the quantity and price of each sale, 
-- summing it up for each country, 
-- and then ordering the results to show the top 10 countries by total revenue.
-- geographically, the strong results of the uk, netherlands, ireland, germany, france, show a strong presence in the western european market
-- note australia's strength, even considering the distance from the rest of the euro countries. 
-- note the taper in sales from spain to sweden. why is this? marketing? product selection?SELECT COUNT(DISTINCT Invoice) AS total_orders,

COUNT(DISTINCT "Customer ID") AS total_customers,
       ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS total_revenue
FROM sales
WHERE CAST(Quantity AS REAL) > 0;
-- this query calcs, total number of orders, customers, and revenue. 
--20k orders, 4k customers, 10.6 million in revenue.
-- average order value of 530

SELECT "Customer ID",
       ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS total_spent,
       COUNT(DISTINCT Invoice) AS total_orders
FROM sales
WHERE CAST(Quantity AS REAL) > 0
AND "Customer ID" != ''
GROUP BY "Customer ID"
ORDER BY total_spent DESC
LIMIT 10;
-- this query calcs top customers by total spent.
-- spending ranged from 77k to 280k. total orders ranged from 1 to 201.
-- cust16446 spent 168k on only 2 orders. likely a wholesale customer or bulk buyer
-- cust14911 made 201 orders but is in the middle of the pack in terms of total spent. high frequency but lower average order value. different customer profile, but both top 10


-- purchase frequency across all customers
SELECT total_orders,
        COUNT("Customer ID") AS customer_count
FROM (
    SELECT "Customer ID",
        COUNT(DISTINCT Invoice) AS total_orders
    FROM sales
    WHERE "Customer ID" != ''
    AND CAST(Quantity AS REAL) > 0
    GROUP BY "Customer ID"
)
GROUP BY total_orders
ORDER BY total_orders ASC;
-- long tail distribution of purchase frequency.
-- total orders range from 1 to 210.
-- total orders from 1-8 have a customer count of about >= 100.
-- total orders from 9-15 have >= 25.
-- total orders from 16-21 have >= 10.
-- total orders from 21+ have <= 10,
-- low order amount is common, signifying a large base of customers with low purchase frequency. first time buyer promotions come to mind
-- how do we convert these low frequency buyers into more regular customers? loyalty programs, email marketing, retargeting ads, etc.  

-- recency, frequency, monetary value (RFM) analysis
SELECT
    "Customer ID",
    CAST(JULIANDAY('2011-12-09') - JULIANDAY(MAX(InvoiceDate)) AS INTEGER ) AS recency_days,
    COUNT(DISTINCT Invoice) AS frequency,
    ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS monetary
FROM sales
WHERE "Customer ID" != ''
AND CAST(Quantity AS REAL) > 0
GROUP BY "Customer ID"
ORDER BY monetary DESC 
LIMIT 20;

-- query returned null for all customers
-- likely due to InvoiceDate being stored as TEXT in M/D/YY format.
-- JULIANDAY requires YYYY-MM-DD format to calculate correctly.  
SELECT InvoiceDate 
FROM sales 
LIMIT 5;
-- result: "12/1/10 8:26" -- M/D/Y H:MM with no leading zeros on single digit months and days.  

-- attempt conversion without leading zero fix 
SELECT InvoiceDate,
       JULIANDAY(SUBSTR(InvoiceDate, 7, 2) || '-' || 
                 PRINTF('%02d', CAST(SUBSTR(InvoiceDate, 1, INSTR(InvoiceDate, '/') - 1) AS INTEGER)) || '-' ||
                 PRINTF('%02d', CAST(SUBSTR(InvoiceDate, INSTR(InvoiceDate, '/') + 1, 
                 INSTR(SUBSTR(InvoiceDate, INSTR(InvoiceDate, '/') + 1), '/') - 1) AS INTEGER)))
FROM sales
LIMIT 5;
-- still returned null for all customers.

-- attempt to identify patterns in InvoiceDate formatting
SELECT DISTINCT SUBSTR(InvoiceDate, 1, 10)
FROM sales
LIMIT 10;
-- result: confirmed M/D/YY H:MM format consistent across dataset, month and day vary between 1 and 2 digits.

-- attempt to convert with leading zero fix for single digit months and days, and adding '20' prefix to year for proper formatting
SELECT InvoiceDate,
       JULIANDAY('20' || SUBSTR(InvoiceDate, 7, 2) || '-' || 
                 PRINTF('%02d', CAST(SUBSTR(InvoiceDate, 1, INSTR(InvoiceDate, '/') - 1) AS INTEGER)) || '-' ||
                 PRINTF('%02d', CAST(SUBSTR(InvoiceDate, INSTR(InvoiceDate, '/') + 1, 
                 INSTR(SUBSTR(InvoiceDate, INSTR(InvoiceDate, '/') + 1), '/') - 1) AS INTEGER)))
FROM sales
LIMIT 5;
-- still returned null for all customers.

-- attempt to inspect raw character positions to indentify exact structure
SELECT 
    InvoiceDate,
    LENGTH(InvoiceDate),
    SUBSTR(InvoiceDate, 1, 1),
    SUBSTR(InvoiceDate, 2, 1),
    SUBSTR(InvoiceDate, 3, 1),
    SUBSTR(InvoiceDate, 4, 1),
    SUBSTR(InvoiceDate, 5, 1),
    SUBSTR(InvoiceDate, 6, 1),
    SUBSTR(InvoiceDate, 7, 1),
    SUBSTR(InvoiceDate, 8, 1)
FROM sales
LIMIT 3;
-- confirmed that month at pos 1-2, slash at 3, day at 4, slash at 5, year at 6-7, space at 8 
-- single digit months and days cause position shifts which broke earlier parsing attempts

-- attempt to CREATE TABLE attempt using CASE -- produced malformed dates ("200 -12-1/")
-- CASE logic didn't correctly isolate year, month, day positions  
CREATE TABLE sales_clean AS
SELECT *,
       CASE 
           WHEN INSTR(InvoiceDate, '/') = 2 
           THEN '20' || SUBSTR(InvoiceDate, INSTR(InvoiceDate,'/') + INSTR(SUBSTR(InvoiceDate, INSTR(InvoiceDate,'/')+1),'/')+1, 2) || '-0' || SUBSTR(InvoiceDate, 1, 1) || '-0' || SUBSTR(InvoiceDate, 3, 1)
           ELSE '20' || SUBSTR(InvoiceDate, 7, 2) || '-' || SUBSTR(InvoiceDate, 1, 2) || '-' || SUBSTR(InvoiceDate, 4, 2)
       END AS clean_date
FROM sales;

-- checking
SELECT InvoiceDate, clean_date 
FROM sales_clean 
LIMIT 10;

-- attempt to start over with a cleaner approach using PRINTF to pad single digit months and days with leading zeros  
DROP TABLE sales_clean;

CREATE TABLE sales_clean AS
SELECT *,
       '20' || SUBSTR(InvoiceDate, 6, 2) || '-' || 
       PRINTF('%02d', CAST(SUBSTR(InvoiceDate, 1, INSTR(InvoiceDate, '/') - 1) AS INTEGER)) || '-' ||
       PRINTF('%02d', CAST(SUBSTR(InvoiceDate, INSTR(InvoiceDate, '/') + 1, 
       INSTR(InvoiceDate, '/') - 1) AS INTEGER)) AS clean_date
FROM sales;

-- final conversion: '20' || year || '-' || PRINTF ('%02d', month) || '-' || PRINTF('%02d', day)

SELECT InvoiceDate, clean_date 
FROM sales_clean 
LIMIT 5;
-- result: "2010-12-01" -- JULIANDAY now reads correctly  

SELECT 
    "Customer ID",
    CAST(JULIANDAY('2011-12-09') - JULIANDAY(MAX(clean_date)) AS INTEGER) AS recency_days,
    COUNT(DISTINCT Invoice) AS frequency,
    ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS monetary
FROM sales_clean
WHERE "Customer ID" != ''
AND CAST(Quantity AS REAL) > 0
GROUP BY "Customer ID"
ORDER BY monetary DESC
LIMIT 20;
-- successful RFM analysis after cleaning date format.
-- polarizing customer profiles.  customer 12346 has the highest recency (342) but the lowest frequency (1)
-- customer 14911 has the one of the loweset recency days (1) and the highest frequency (201), while also being top 10 in monetary value
-- there are valuable customers amongst the data, they're being lost. label customers and create solutions to target each segment.

-- lesson: always inspect raw data format before assuming date functions will work
-- real world data rarely comes in clean. this is standard data integrity work

SELECT
    "Customer ID",
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    r_score + f_score + m_score AS rfm_total,
    CASE
        WHEN r_score + f_score + m_score >= 8 THEN 'Champion'
        WHEN r_score + f_score + m_score >= 6 THEN 'Loyal'
        WHEN r_score + f_score + m_score >= 4 THEN 'At Risk'
        ELSE 'Lost'
    END AS segment
FROM (
    SELECT
        "Customer ID",
        recency_days,
        frequency,
        monetary,
        CASE WHEN recency_days <= 30 THEN 3
             WHEN recency_days <= 90 THEN 2
             ELSE 1 END AS r_score,
        CASE WHEN frequency >= 10 THEN 3
             WHEN frequency >= 3 THEN 2
             ELSE 1 END AS f_score,
        CASE WHEN monetary >= 10000 THEN 3
             WHEN monetary >= 1000 THEN 2
             ELSE 1 END AS m_score
    FROM (
        SELECT
            "Customer ID",
            CAST(JULIANDAY('2011-12-09') - JULIANDAY(MAX(clean_date)) AS INTEGER) AS recency_days,
            COUNT(DISTINCT Invoice) AS frequency,
            ROUND(SUM(CAST(Quantity AS REAL) * CAST(Price AS REAL)), 2) AS monetary
        FROM sales_clean
        WHERE "Customer ID" != ''
        AND CAST(Quantity AS REAL) > 0
        GROUP BY "Customer ID"
    )
)
ORDER BY rfm_total DESC;
-- RFM segmentation of customers into 'Champion', 'Loyal', 'At Risk', and 'Lost' based on their recency, frequency, and monetary scores.
-- this segmentation allows for targeted marketing strategies for each group, such as exclusive offers for Champions, loyalty rewards for Loyal customers, re-engagement campaigns for At Risk customers, and win-back strategies for Lost customers.
-- customer 12346 is 'At Risk' due to low frequency and recency score despite high monetary score. confirming that this is a customer that the business must focus on winning back.
-- the long tail distribution identified earlier in the frequency query is reflected here, with a large volume of customers falling into the 'Lost' segment.    
