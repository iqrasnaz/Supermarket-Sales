-- Create database 
CREATE DATABASE IF NOT EXISTS supermarket;

-- Create table to store supermarket sales information
CREATE TABLE supermarket_sales(
    invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(30) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    tax_percentage DECIMAL(6,4) NOT NULL,
    total DECIMAL(12, 4) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment_type VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_percentage DECIMAL(11,9),
    gross_income DECIMAL(12, 4),
    rating DECIMAL(3,1)
);

-- Before importing data into the table, use Excel to fix the date column format. 
-- Change it to "YYYY-MM-DD" which is correct MySQL DATETIME format.
-- Otherwise, the following error is displayed: 
-- 0 row(s) affected, 3 warning(s): 1681 Specifying number of digits for floating point data types is deprecated and will be removed in a future release.

-- Verify if tables successfully created/desribe columns and datatypes
DESCRIBE supermarket_sales;


