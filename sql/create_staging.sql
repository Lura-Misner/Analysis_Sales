CREATE TABLE IF NOT EXISTS Staging(
            row_id INT PRIMARY KEY,
            order_id VARCHAR(50),
            order_date DATE,
            ship_date DATE,
            ship_mode VARCHAR(50),
            customer_id VARCHAR(50),
            customer_name VARCHAR(100),
            segment VARCHAR(50),
            country_region VARCHAR(100),
            city VARCHAR(100),
            state_province VARCHAR(100),
            postal_code VARCHAR(50),
            region VARCHAR(50),
            product_id VARCHAR(50),
            category VARCHAR(50),
            sub_category VARCHAR(50),
            product_name VARCHAR(255),
            sales DECIMAL(12, 4),
            quantity INT,
            discount DECIMAL(12, 4),
            profit DECIMAL(12, 4) );

CREATE TABLE IF NOT EXISTS ManagerStaging(
            region VARCHAR(50) PRIMARY KEY,
            regional_manager VARCHAR(100) );

CREATE TABLE IF NOT EXISTS ReturnsStaging(
             order_id VARCHAR(50) PRIMARY KEY,
             returned VARCHAR(10) );