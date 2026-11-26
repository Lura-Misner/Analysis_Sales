-- Which product categories generate the most sales?
SELECT p.category, SUM(o.sales) as sales, SUM(o.profit) as profit,
    ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) as profit_margin
FROM Products p
JOIN OrderItems o
ON p.product_key = o.product_key
GROUP BY p.category
ORDER BY sales DESC;
-- We find that while Furniture is up there in sales, it is not nearly as profitable as the other categories.

-- Which Furniture sub-categories are causing the least profit?
SELECT p.sub_category, SUM(o.sales) as sales, SUM(o.profit) as profit,
    ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) as profit_margin, ROUND(AVG(o.discount) * 100, 2) as discount_percent
FROM Products p
JOIN OrderItems o
ON p.product_key = o.product_key
WHERE p.category = 'Furniture'
GROUP BY p.sub_category
ORDER BY profit ASC;
-- Tables and Bookcases are dragging the Furniture category down, these categories also have the highest avg discount

-- Look at general discounts, and see where we start losing money
SELECT SUM(o.sales) as sales, SUM(o.profit) as profit, ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) as profit_margin,
    ROUND(AVG(o.discount) * 100, 2) as discount_percent
FROM Products p
JOIN OrderItems o
ON p.product_key = o.product_key
WHERE p.category = 'Furniture'
GROUP BY o.discount
ORDER BY o.discount ASC;
-- Around a 30% discount is where the company starts to lose money overall

-- Now look at discounts by sub_category, so we can look at where individual categories start to become unprofitable
SELECT p.sub_category, SUM(o.sales) as sales, SUM(o.profit) as profit,
    ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) as profit_margin, ROUND(AVG(o.discount) * 100, 2) as discount_percent
FROM Products p
JOIN OrderItems o
ON p.product_key = o.product_key
WHERE p.category = 'Furniture'
GROUP BY o.discount, p.sub_category
ORDER BY o.discount ASC;
-- Looking at the sub_categories, Tables and Bookcases start being unprofitable around 20% discounts, where the others
-- become unprofitable around 30%

-- Looking at the 10 least profitable items
SELECT p.product_name, SUM(o.sales) as sales, SUM(o.profit) as profit, ROUND((SUM(o.profit) / SUM(o.sales)) * 100, 2) as profit_margin,
ROUND(AVG(o.discount) * 100, 2) as discount_percentage, ROUND(MAX(o.discount) * 100, 2) as max_discount
FROM Products p
JOIN OrderItems o
ON p.product_key = o.product_key
WHERE p.category = 'Furniture'
GROUP BY p.product_name
HAVING SUM(o.profit) < 0
ORDER BY profit ASC
LIMIT 10;
-- Several of these worst-performing products are conference or meeting tables

-- Sales by Customer Segment
SELECT c.segment, SUM(oi.sales) as sales, SUM(oi.profit) as profit, count(DISTINCT o.order_id) as orders,
    ROUND(SUM(oi.sales) / count(DISTINCT o.order_id), 2) as AOV
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN customer c
ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY sales DESC;
-- Consumers generate the most sales, followed by corporate and home office.

-- Does the segment with the highest AOV also have the highest AOP?
SELECT c.segment, SUM(oi.sales) as sales, SUM(oi.profit) as profit, count(DISTINCT o.order_id) as orders,
    ROUND(SUM(oi.sales) / count(DISTINCT o.order_id), 2) as AOV, ROUND(SUM(oi.profit) / count(DISTINCT o.order_id), 2) as AOP,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN customer c
ON o.customer_id = c.customer_id
GROUP BY c.segment
ORDER BY sales DESC;
-- While consumers generate the bulk of our sales, this segment generates the least profit per order

-- How do sales and profit change from year to year?
SELECT YEAR(o.order_date) as year, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_date);
-- Sales and Profit continue to grow throughout the years, but the profit margins begin to drop from 2025-2026

-- Monthly sale trends
SELECT YEAR(o.order_date) as year, MONTH(o.order_date) as month, ROUND(SUM(oi.sales), 2) as sales,
    ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year, month;
-- A couple of things to look at moving forward:
-- February: Significantly lower sales and orders than any other month of the year, consistently through all years.
-- April: Despite the company growing throughout the years, Sale stay about the same during this month, and profit decreases throughout the years
-- September and October: Strong months for the company, consistently generate strong sales, profits, and order volumes
-- November and December: Holiday related activity. Strong months, but November sales stay stagnant until a large jump in 2026, while Decembers climb over the years and drip in 2026.

-- Is the declining profitability due to discounts?
SELECT YEAR(o.order_date) as year, MONTH(o.order_date) as month, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin, ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
GROUP BY YEAR(o.order_date), MONTH(o.order_date);
-- Aprils declining profitability is absolutely due to an increase in discounts. We see the profits get lower throughout the years while the weighted discount grows higher.
-- October in 2025 had significantly more profit compared to all other years, with margins up to 27%. This also had the lowest weighted discount between the years.
-- Similarly in November, 2024 had the weighted lowest discount with by far the highest profit margins. Sale numbers didn't change much whether the weighted discount was 16% or 10%.

-- Sale data by month per Furniture category: Are there trends with categories tanking or boosting margins?
SELECT YEAR(o.order_date) as year, MONTH(o.order_date) as month, p.category, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin, ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
GROUP BY YEAR(o.order_date), MONTH(o.order_date), p.category;
-- April: Furniture profitability decline every year while discounts generally increase. Office supplies in 2025 has an unusually poor year with a high discount,
-- but bounces back significantly in 2026 with a much smaller weighted discount. Tech sales in 2026 are also concerning with -21% profit margins, and a 29% weighted discount.
-- Furniture has a reoccurring profitability problem throughout the years, resulting in several months with negative margins where the weighted discounts are 20-30%.
-- Office supplies keep good margins throughout the years, even with 5-15% weighted discounts.

-- Investigating April 2026 Tech category further
SELECT p.product_name, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders, SUM(oi.quantity) AS units_sold,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin, ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE p.category = 'Technology' AND YEAR(o.order_date) = 2026 AND MONTH(o.order_date) = 4
GROUP BY p.product_key, p.product_name
ORDER BY profit_margin
LIMIT 20;
-- Immediately we can see a big outlier "Lexmark MX611dhe Monochrome Laser Printer" being sold at a -133.3% profit margin and a 70% weighted discount.
-- This products loss is greater than its sales, and it accounts for a large portion of April's overall Technology loss.

-- Has this product performed differently across all months/years?
SELECT YEAR(o.order_date) as year, MONTH(o.order_date) as month, p.product_name, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, count(DISTINCT o.order_id) as orders, SUM(oi.quantity) AS units_sold,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin, ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE p.category = 'Technology' AND p.product_name = 'Lexmark MX611dhe Monochrome Laser Printer'
GROUP BY YEAR(o.order_date), MONTH(o.order_date)
ORDER BY year, month;
-- This returned three results, showing both that the printer has been unprofitable in the past, and that it can be
-- profitable with the right pricing conditions.

-- Did the units sold in april receive the same discount and generate loss, or was one particular transaction responsible?
SELECT p.product_name, oi.sales, oi.profit, oi.discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE p.category = 'Technology' AND p.product_name = 'Lexmark MX611dhe Monochrome Laser Printer'
AND MONTH(o.order_date) = 4 AND YEAR(o.order_date) = 2026;
-- Units were all part of one transaction.

-- What are the most & least profitable items
WITH ProductTotals AS (
    SELECT
        p.category,
        p.product_key,
        p.product_name,
        ROUND(SUM(oi.sales), 2) AS sales,
        ROUND(SUM(oi.profit), 2) AS profit,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.profit) / SUM(oi.sales) * 100, 2) AS profit_margin,
        ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_key = p.product_key
    GROUP BY p.product_key, p.product_name, p.category
),
RankedProducts AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY profit DESC, product_key
        ) AS profit_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY profit ASC, product_key
        ) AS least_profit_rank
    FROM ProductTotals
)
SELECT *
FROM RankedProducts
WHERE profit_rank = 1 OR least_profit_rank = 1
ORDER BY profit DESC;
-- Canon Advanced Copier is a strong performer with over $25,000 in profit and margins over 40%
-- The Cubify printer stands out as the weakest performer, with a -80% profit margin, and a weighted discount of 48%

-- What is and isn't selling?
WITH ProductTotals AS (
    SELECT
        p.category,
        p.product_key,
        p.product_name,
        ROUND(SUM(oi.sales), 2) AS sales,
        ROUND(SUM(oi.profit), 2) AS profit,
        COUNT(DISTINCT o.order_id) AS orders,
        SUM(oi.quantity) AS units_sold,
        ROUND(SUM(oi.profit) / SUM(oi.sales) * 100, 2) AS profit_margin,
        ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
    FROM Orders o
    JOIN OrderItems oi ON o.order_id = oi.order_id
    JOIN Products p ON oi.product_key = p.product_key
    GROUP BY p.product_key, p.product_name, p.category
),
RankedProducts AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY sales DESC, product_key
        ) AS sales_rank,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY sales ASC, product_key
        ) AS least_sales_rank
    FROM ProductTotals
)
SELECT *
FROM RankedProducts
WHERE sales_rank = 1 OR least_sales_rank = 1
ORDER BY sales DESC;
-- Cannon Advanced Copier has the most net sales, but something that catches my eye is the HON Series Task Chair is third in sales, but the company makes 0 profit on it
-- Eureka Disposable Bags are some of the least selling items, while it has a -275% margin, its financial impact is small at $1.62

-- What percentage of orders are returned?
SELECT COUNT(r.order_id) AS returned_orders, COUNT(DISTINCT o.order_id) AS total_orders,
    ROUND(COUNT(r.order_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate
FROM Orders o
LEFT JOIN Returns r
ON o.order_id = r.order_id;
-- 5.79% of orders are returned

-- Is there a particular product category where returns are concentrated?
SELECT p.sub_category, ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate
FROM Orders o
LEFT JOIN Returns r
ON o.order_id = r.order_id
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
GROUP BY p.sub_category
ORDER BY return_rate DESC;
-- Important assumption for this project: Orders can contain multiple products, but our Returns table only gives us an
-- order id and a 'yes' for returned. We will be assuming that if an order has been returned, it includes all products from the order.

-- How does a higher return rate correlate with other financial statistics?
SELECT p.sub_category, ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate,
    ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, COUNT(DISTINCT o.order_id) as orders,
    SUM(oi.quantity) AS units_sold, ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
LEFT JOIN Returns r
ON o.order_id = r.order_id
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
GROUP BY p.sub_category
ORDER BY return_rate DESC;
-- Biggest areas of concern:
-- Machines 11.4% return rate with only 1.82% profit
-- Tables with 9.55% return rate, -17,700 in profit, -8.53% margins
-- Overall, high return rates do not necessarily correspond to poor profitability.

-- What region has the highest return rates?
SELECT oi.region, ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate,
    ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, COUNT(DISTINCT o.order_id) as orders,
    SUM(oi.quantity) AS units_sold, ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
LEFT JOIN Returns r
ON o.order_id = r.order_id
JOIN orderitems oi
ON o.order_id = oi.order_id
GROUP BY oi.region
ORDER BY return_rate DESC;
-- West return rate is significantly higher at 11.56%, compared to the others at 2-3%.
-- Central has the lowest profit margins at 7.92%, compared to the others at 12-15%

-- Why are West return rates so much higher?
SELECT p.sub_category, ROUND(COUNT(DISTINCT r.order_id) / COUNT(DISTINCT o.order_id) * 100, 2) AS return_rate,
    ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit, COUNT(DISTINCT o.order_id) as orders,
    SUM(oi.quantity) AS units_sold, ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin,
    ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
LEFT JOIN Returns r
ON o.order_id = r.order_id
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE oi.region = 'West'
GROUP BY p.sub_category
ORDER BY return_rate DESC;
-- The West has elevated return rates across all sub-categories, suggesting the overall regional difference isn't isolated to a single product type.
-- Machines has both a high return rate of 19.51% and na -1.26% profit margin
-- Something worth noting: Tables perform better financially in the west than overall, not the same for bookcases

-- Why does Central have such low margins?
SELECT p.sub_category, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit,
    COUNT(DISTINCT o.order_id) as orders, SUM(oi.quantity) AS units_sold,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin,
    ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE oi.region = 'Central'
GROUP BY p.sub_category
ORDER BY profit_margin DESC;
-- Several poorly performing sub-categories, particularly Furniture. Furnishings -25.62%, Tables -9.09%, Bookcases -8.27% are all generating losses
-- Strong performance in certain office supplies and technology help offset these losses (Copiers, Paper, Accessories)

-- Now that we have looked at the West and Central, we can look at other regions to make comparisons.
SELECT p.sub_category, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit,
    count(DISTINCT o.order_id) as orders, SUM(oi.quantity) AS units_sold,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin,
    ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE oi.region = 'East'
GROUP BY p.sub_category
ORDER BY profit_margin DESC;
-- Paper, Copiers, and Accessories are all top performers with strong margins and profit.
-- Tables are by far the worst performing, with -11k in profit, -27.77% margins, with a weighted discount of 37.39. Bookcases are still unprofitable
-- Furnishings are profitable with almost 20% margins, which is much better compared to Central.

-- South
SELECT p.sub_category, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit,
    count(DISTINCT o.order_id) as orders, SUM(oi.quantity) AS units_sold,
    ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin,
    ROUND(SUM(oi.sales * oi.discount) / SUM(oi.sales) * 100, 2) AS weighted_discount
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
JOIN products p
ON oi.product_key = p.product_key
WHERE oi.region = 'South'
GROUP BY p.sub_category
ORDER BY profit_margin DESC;

-- Paper, Copiers and Accessories are again among the most impactful top performers. Labels and Envelopes have also been up there across multiple regions, but account for a small percentage of sales.
-- Tables are still the least profitable, with negative profit and margins -10.53%, although are performing better compared to the East
-- This is the only region where bookcases are profitable, chairs are also more profitable here than other regions.

/*
I have gone through and updated the above queries to include the weighted discounts for categories, and compared them across Regions.
Significant findings:
- West has the strongest overall profit margin 14.98%, while Central has the weakest 7.92%.
- Several sub-categories show a relationship between higher weighted discounts and lower profit margins, particularly Machines, Tables, Bookcases, and Furnishings.
- Central has poor profitability in Furnishings, with a 26.16% weighted discount and a -25.62% profit margin.
- East has the largest Tables losses, with a -27.77% margin and 37.39% weighted discount.
- Machines are profitable only in East, where its weighted discount is lower than in the other regions.
- Discounting does not explain every difference. Binders remains profitable in three regions despite relatively high weighted discounts.
*/

-- What is the average shipping between orders?
SELECT ship_mode, AVG(DATEDIFF(ship_date, order_date)) AS avg_shipping_days,
    MIN(DATEDIFF(ship_date, order_date)) AS min_shipping_days,
    MAX(DATEDIFF(ship_date, order_date)) AS max_shipping_days,
    ROUND((SUM(CASE WHEN DATEDIFF(ship_date, order_date) = 0 THEN 1 ELSE 0 END) / COUNT(order_id)) * 100, 2) AS same_day_percentage,
    COUNT(order_id) as order_count
FROM Orders
GROUP BY ship_mode
ORDER BY avg_shipping_days;
-- Same Day orders are shipped on the same day 95.49$ of the time
-- First Class: 2.19 days on average, Second Class: 3.23 days on average, Standard Class: 4.99 days on average
-- Standard Class represents approximately 60% of all orders and has the longest processing time

-- How does shipping vary by region?
WITH OrderShipping AS (
    SELECT DISTINCT o.order_id, oi.region, o.ship_mode,
        DATEDIFF(o.ship_date, o.order_date) AS shipping_days
    FROM Orders o
    JOIN OrderItems oi
        ON o.order_id = oi.order_id
)

SELECT region, ship_mode, AVG(shipping_days) AS avg_shipping_days, MIN(shipping_days) AS min_shipping_days,
    MAX(shipping_days) AS max_shipping_days,
    ROUND((SUM(CASE WHEN shipping_days = 0 THEN 1 ELSE 0 END) / COUNT(DISTINCT order_id)) * 100, 2) AS same_day_percentage,
    COUNT(DISTINCT order_id) as order_count
FROM OrderShipping
GROUP BY ship_mode, region
ORDER BY region, ship_mode;
-- Average shipping times are consistent across all four regions for each shipping method.
-- Standard class: approximately 5 days, First class: approximately 2.1-2.2 days, Second class: approximately 3.2-3.4
-- Same day orders are shipped on the same day between 91% and 100% of the time.
-- Differences are minimal, suggesting shipping method is more closely associated with processing time than region


-- Does profitability change by shipping method
SELECT o.ship_mode, ROUND(SUM(oi.sales), 2) as sales, ROUND(SUM(oi.profit), 2) as profit,
    COUNT(DISTINCT o.order_id) as order_count, ROUND((SUM(oi.profit)/ SUM(oi.sales)) * 100, 2) as profit_margin
FROM Orders o
JOIN orderitems oi
ON o.order_id = oi.order_id
GROUP BY o.ship_mode
ORDER BY o.ship_mode;
-- Standard class accounts for the largest share of orders, sales, and total profit.
-- First class has the highest profit margin at 13.93%, while standard class has the lowest at 12.20%
-- Overall, profit margins are relatively consistent across shipping methods, suggesting that shipping method doesn't have a strong association with profitability here
