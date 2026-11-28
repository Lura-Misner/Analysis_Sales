from config import DB_HOST, DB_USER, DB_PASSWORD, DB_NAME
import pandas as pd
import mysql.connector
from mysql.connector import Error

try:
    # Connect to database
    connection = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )

# ------------------------------------------------ Shipping Stats --------------------------------------
    # Orders Table, convert dates
    query = "SELECT * FROM Orders"
    orders_df = pd.read_sql(query, connection)
    orders_df['order_date'] = pd.to_datetime(orders_df['order_date'])
    orders_df['ship_date'] = pd.to_datetime(orders_df['ship_date'])

    # Add columns to help break down statistics further
    orders_df['shipping_days'] = (orders_df['ship_date'] - orders_df['order_date']).dt.days
    same_day_count = (orders_df['shipping_days'] == 0).sum()
    same_day_percentage = (same_day_count / len(orders_df)) * 100

    shipping_analysis = orders_df.groupby('ship_mode')['shipping_days'].agg(['count', 'mean', 'min', 'max'])

    # Grab Region from OrderItems so we can Merge
    query = "SELECT order_id, region FROM OrderItems"
    order_regions = pd.read_sql(query, connection)
    orders_region = order_regions.drop_duplicates()

    # Merge the tables
    regional_shipping = orders_df.merge(
        orders_region,
        on = 'order_id',
        how = 'inner'
    )
    regional_shipping['same_day'] = (regional_shipping['shipping_days'] == 0)

    regional_shipping_analysis = regional_shipping.groupby(['region', 'ship_mode']).agg(
        order_count=('order_id', 'count'),
        avg_shipping_days=('shipping_days', 'mean'),
        min_shipping_days=('shipping_days', 'min'),
        max_shipping_days=('shipping_days', 'max'),
        same_day_percentage=('same_day', 'mean')
    )

    # Multiply same day by 100 to convert to percentage
    regional_shipping_analysis['same_day_percentage'] *= 100
    print(regional_shipping_analysis)

# ------------------------------------------------ Customer Stats ------------------------------
    # Set up and merge the tables we need
    query = 'SELECT * FROM Customer'
    customer_df = pd.read_sql(query, connection)

    customer_orders = orders_df.merge(
        customer_df,
        on = 'customer_id',
        how = 'left'
    )

    query = 'SELECT * FROM OrderItems'
    order_items_df = pd.read_sql(query, connection)

    customer_oi = order_items_df.merge(
        customer_orders,
        on = 'order_id',
        how = 'left'
    )

    # Calculate total spending per customer
    customer_spending_analysis = customer_oi.groupby(['customer_id', 'customer_name']).agg(
        total_spent=('sales', 'sum'),
        order_count=('order_id', 'nunique')
    )
    print(customer_spending_analysis.sort_values(by='total_spent', ascending=False).head(10))

    # Average order cost per customer
    customer_spending_analysis['avg_order_value']= (customer_spending_analysis['total_spent'] / customer_spending_analysis['order_count'])
    print(customer_spending_analysis.sort_values(by='avg_order_value', ascending=False).head(10))

    # Which Customer Segment generates the most revenue
    segment_spending_analysis = customer_oi.groupby(['segment']).agg(
        total_spent=('sales', 'sum'),
        order_count=('order_id', 'nunique'),
        customer_count=('customer_id', 'nunique')
    )
    segment_spending_analysis['avg_per_segment'] = (segment_spending_analysis['total_spent'] / segment_spending_analysis['order_count'])
    segment_spending_analysis['avg_per_customer'] = (segment_spending_analysis['total_spent'] / segment_spending_analysis['customer_count'])

    print(segment_spending_analysis.sort_values(by='avg_per_customer', ascending=False).head(10))



    # Export Used Tables to CSV (for Tableau)
    shipping_analysis.reset_index().to_csv('../data/shipping_analysis.csv', index=False)
    regional_shipping_analysis.reset_index().to_csv('../data/regional_shipping_analysis.csv', index=False)
    customer_spending_analysis.reset_index().to_csv('../data/customer_shipping_analysis.csv', index=False)
    segment_spending_analysis.reset_index().to_csv('../data/segment_shipping_analysis.csv', index=False)



except Error as e:
    print(f"Error connecting to MySQL: {e}")

finally:
    # Close the Connection
    if 'connection' in locals() and connection.is_connected():
        connection.close()
