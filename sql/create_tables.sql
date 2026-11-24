CREATE TABLE IF NOT EXISTS Customer (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_name VARCHAR(255) NOT NULL,
    segment VARCHAR(100) NOT NULL );


CREATE TABLE IF NOT EXISTS Managers (
    region VARCHAR(50) PRIMARY KEY,
    regional_manager VARCHAR(255) NOT NULL );


CREATE TABLE IF NOT EXISTS Products (
    product_key INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    product_id VARCHAR(100) NOT NULL,
	product_name VARCHAR(255) NOT NULL,
    category VARCHAR(255) NOT NULL,
	sub_category VARCHAR(255) NOT NULL );

CREATE TABLE IF NOT EXISTS Orders (
    order_id VARCHAR(255) PRIMARY KEY,
    order_date DATE NOT NULL,
    ship_date DATE NOT NULL,
    ship_mode VARCHAR(255) NOT NULL,
    customer_id VARCHAR(50) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES Customer(customer_id) );

CREATE TABLE IF NOT EXISTS Returns(
	order_id VARCHAR(255) PRIMARY KEY,
	returned VARCHAR(25) NOT NULL,
	FOREIGN KEY (order_id) REFERENCES Orders(order_id) );


CREATE TABLE IF NOT EXISTS OrderItems (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(255) NOT NULL,
    product_key INT NOT NULL,
    sales DECIMAL(12,4) NOT NULL,
    quantity INT NOT NULL,
    discount DECIMAL(12,4) NOT NULL,
    profit DECIMAL(12,4) NOT NULL,
    country_region VARCHAR(100) NOT NULL,
    state_province VARCHAR(255) NOT NULL,
    city VARCHAR(255) NOT NULL,
    postal_code VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_key) REFERENCES Products(product_key),
    FOREIGN KEY (region) REFERENCES Managers(region) );