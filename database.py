import openpyxl
import mysql.connector
from mysql.connector import Error

try:
    # Establish a connection to the MySQL server
    connection = mysql.connector.connect(
        host="localhost",
        user="root",
        password="password",
        database = "StoreAnalysis"
    )

    if connection.is_connected():
        cursor = connection.cursor()

        # Create The Database
        cursor.execute("CREATE DATABASE IF NOT EXISTS StoreAnalysis")
        print("Database created or verified successfully.")

        try:
            # Try to create staging tables, handle errors.
            with open("sql/create_staging.sql", "r") as file:
                create_staging = file.read()

            for statement in create_staging.split(";"):
                if statement.strip():
                    cursor.execute(statement)

            print("Staging Tables created or verified successfully.")


            # Clear tables
            with open("sql/clear_staging.sql", "r") as file:
                clear_staging = file.read()

            for statement in clear_staging.split(";"):
                if statement.strip():
                    cursor.execute(statement)

            print("Staging Tables cleared successfully.")


            # Establish connection to data file
            workbook = openpyxl.load_workbook("sample_-_superstore.xlsx")
            orders_sheet = workbook["Orders"]
            people_sheet = workbook["People"]
            returns_sheet = workbook["Returns"]

            # Set up query for inserting rows
            orders_query = """ INSERT INTO Staging(
                row_id, order_id, order_date, ship_date, ship_mode,
                customer_id, customer_name, segment, country_region,
                city, state_province, postal_code, region, product_id,
                category, sub_category, product_name, sales, quantity,
                discount, profit)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s,
                    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                """

            people_query = "INSERT INTO ManagerStaging (region, regional_manager) VALUES (%s, %s)"

            returns_query = "INSERT INTO ReturnsStaging (order_id, returned) VALUES (%s, %s)"


            # Iterate through Order sheet, and gather rows for table
            orders_list = []
            for row in orders_sheet.iter_rows(min_row=2, values_only=True):
                # Date objects need to be converted to proper format
                values = list(row)

                values[2] = values[2].date()
                values[3]= values[3].date()

                orders_list.append(tuple(values))

            # Iterate through People Sheet, and gather rows for table
            people_list = []
            for row in people_sheet.iter_rows(min_row=2, values_only=True):
                # Columns are given in reverse order, so we must switch them
                values = list(row)
                values[0], values[1] = values[1], values[0]
                people_list.append(tuple(values))

            # Iterate through returns sheet, and gather rows for table
            returns_list = []
            for row in returns_sheet.iter_rows(min_row=2, values_only=True):
                returns_list.append(row)

            # Add rows to table
            cursor.executemany(orders_query, orders_list)
            orders_count = cursor.rowcount

            cursor.executemany(people_query, people_list)
            people_count = cursor.rowcount

            cursor.executemany(returns_query, returns_list)
            returns_count = cursor.rowcount

            connection.commit()

            print(f"Staging Table: {orders_count} rows added. "
                  f"ManagerStaging Table: {people_count} rows added. "
                  f"ReturnsStaging Table: {returns_count} rows added.")

            # Now we will create the actual tables for our database.
            with open("sql/create_tables.sql", "r") as file:
                create_tables = file.read()

            for statement in create_tables .split(";"):
                if statement.strip():
                    cursor.execute(statement)

            print("Normalized Tables created or verified successfully.")

            # TODO: Populate actual tables






        except Error as e:
            print(f"Error creating or populating staging table: {e}")


except Error as e:
    print(f"Error connecting to MySQL: {e}")

finally:
    # Close the Connection
    if 'connection' in locals() and connection.is_connected():
        cursor.close()
        connection.close()