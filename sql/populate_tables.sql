-- Customer Table: Map Harry Olson to one ID instead of the initial 4.
INSERT INTO Customer (customer_id, customer_name, segment)
SELECT DISTINCT
    CASE
        WHEN customer_name = 'Harry Olson' THEN 'HO-15231'
        ELSE customer_id
    END,
   customer_name,
   segment
FROM Staging;

-- Managers Table: Everything already validated
INSERT INTO Managers (region, regional_manager)
SELECT region, regional_manager
FROM ManagerStaging;

-- Products Table: product_key is an auto increment, we just need other values.
INSERT INTO Products (product_id, product_name, category, sub_category)
SELECT DISTINCT product_id, product_name, category, sub_category
FROM Staging;


-- Orders Table: Straight forward, but we need to change the extra IDs for Harry
INSERT INTO Orders (order_id, order_date, ship_date, ship_mode, customer_id)
SELECT DISTINCT
    order_id,
    order_date,
    ship_date,
    ship_mode,
    CASE
        WHEN customer_id IN ('HO-15230','HO-15231', 'HO-15232', 'HO-15233', 'HO-15234') THEN 'HO-15231'
        ELSE customer_id
    END
FROM Staging;

-- Returns Table: Validated, can pull directly from staging table
INSERT INTO Returns (order_id, returned)
SELECT order_id, returned
FROM ReturnsStaging;

-- OrderItems Table: Straight forward, but need product_key from Products table
INSERT INTO OrderItems (row_id, order_id, product_key, sales, quantity, discount, profit,
 country_region, state_province, city, postal_code, region)
SELECT s.row_id, s.order_id, p.product_key, s.sales, s.quantity, s.discount, s.profit,
s.country_region, s.state_province, s.city, s.postal_code, s.region
FROM Staging s
LEFT JOIN Products p
ON s.product_id = p.product_id
AND s.product_name = p.product_name;