
-- Check if Product_id can be used as the primary key, or if there are multiple products with same ID
SELECT product_id FROM Staging
GROUP BY product_id
HAVING COUNT(DISTINCT product_name) > 1;
-- 32 rows returned, product_id alone can not be the primary key.

-- Check if product_name can be used as a primary key, or if one product name is attached to multiple product_ids
SELECT product_id, product_name
FROM STAGING
GROUP BY product_name
HAVING COUNT(DISTINCT product_id) > 1;
-- 17 rows returned, some product names are attached to multiple product_ids, this can not be a primary key.

-- Check if both can be used as a composite primary key
SELECT product_id, product_name
FROM Staging
GROUP BY product_id, product_name
HAVING COUNT(DISTINCT category) > 1
    OR COUNT(DISTINCT sub_category) > 1;
-- 0 rows, the combination of the two produce no duplicate records. They can be used as a composite key.

-- Check if customer_id maps to one department
SELECT customer_id
FROM Staging
GROUP BY customer_id
HAVING COUNT(segment) > 1;
-- 0 rows returned, which means one customer_id maps to exactly one customer_name

-- Check if each customer_id maps to only one customer name
SELECT customer_name
FROM Staging
GROUP BY customer_name
HAVING COUNT(DISTINCT customer_id) > 1;
-- Harry Olson comes up, meaning that multiple customer_ids are assigned to his name.

-- Check if these ids go to other customers or segments, or if it is just an id inconsistency
SELECT customer_id,
       COUNT(DISTINCT customer_name) AS names,
       COUNT(DISTINCT segment) AS segments
FROM Staging
WHERE customer_name = 'Harry Olson'
GROUP BY customer_id;
-- Each id correlates to one name and segment, so we will map all duplicate ids for Harry Olson back to one.

-- Check if each order_id goes to only one location
SELECT order_id
FROM Staging
GROUP BY order_id
HAVING COUNT(DISTINCT region) > 1
OR COUNT(DISTINCT country_region) > 1
OR COUNT(DISTINCT city) > 1
OR COUNT(DISTINCT state_province) > 1
OR COUNT(DISTINCT postal_code) > 1
-- One order_id comes back with two different locations.
-- This is reasonable, an order can have pieces going to different locations. This changes the original Schema plan,
-- these details will have to be moved to the OrderItems table

-- Check if any orders were ordered/shipped on different days, by different customers, or by different transportation
SELECT order
FROM Staging
GROUP BY order_id
HAVING COUNT(DISTINCT customer_id) > 1
    OR COUNT(DISTINCT order_date) > 1
    OR COUNT(DISTINCT ship_date) > 1
    OR COUNT(DISTINCT ship_mode) > 1;
-- 0 Rows returned, these categories are consistent.

-- Check that every order has a corresponding regional manager
SELECT DISTINCT s.region
FROM Staging s
LEFT JOIN ManagerStaging m
    ON s.region = m.region
WHERE m.region IS NULL;
-- 0 Rows return, this confirms that every region in Staging table has a corresponding regional manager

-- Check that every order in ReturnStaging actually exists in our Staging table
SELECT DISTINCT r.order_id
FROM ReturnStaging r
LEFT JOIN Staging s
    ON s.order_id = r.order_id
WHERE s.order_id IS NULL;
-- Returns 0 rows, every order that has been returned exists in our Staging table

------------------ Database Validation after Normalization -----------------------------------
-- Check that every order has at least one order item
SELECT o.order_id
FROM Orders o
LEFT JOIN OrderItems i
ON o.order_id = i.order_id
GROUP BY o.order_id
HAVING COUNT(product_key) < 1;
-- Returned 0 rows

-- Check that there are no records in OrderItems that reference an Order that doesn't exist
SELECT o.order_id
FROM OrderItems o
LEFT JOIN Orders i
ON o.order_id = i.order_id
WHERE i.order_id is NULL;
-- Returned 0 rows

-- Check that every order item references a product that exists
SELECT o.row_id
FROM OrderItems o
LEFT JOIN Products p
ON o.product_key = p.product_key
WHERE p.product_key is NULL;
-- Returned 0 rows, all products referenced exist in our product table.

-- Validate that our numeric data didn't get corrupted between tables
SELECT
    SUM(sales),
    SUM(profit),
    SUM(quantity)
FROM Staging;

SELECT
    SUM(sales),
    SUM(profit),
    SUM(quantity)
FROM orderitems;
-- These return the same results, so that is fine.

-- Check that no duplicate products made it into our Product table
SELECT product_id, product_name
FROM Products
GROUP BY product_id, product_name
HAVING COUNT(*) > 1;
-- Returns 0, duplicate free.
