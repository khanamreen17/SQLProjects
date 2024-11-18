--SELECT @@SERVERNAME

--DROP TABLES IF THEY ALREADY EXIST, NEW TABLES BUT BEST PRACTICE if not in prod
IF OBJECT_ID ('products','u') IS NOT NULL DROP TABLE products;
IF OBJECT_ID ('customers','u') IS NOT NULL DROP TABLE customers;
IF OBJECT_ID ('geolocation','u') IS NOT NULL DROP TABLE geolocation;
IF OBJECT_ID ('order_items','u') IS NOT NULL DROP TABLE order_items;
IF OBJECT_ID ('orders','u') IS NOT NULL DROP TABLE orders;
IF OBJECT_ID ('payments','u') IS NOT NULL DROP TABLE payments;
IF OBJECT_ID ('sellers','u') IS NOT NULL DROP TABLE sellers;

GO

--Create Products table and insert records from CSV file
CREATE TABLE products (
	product_id 	VARCHAR(150) PRIMARY KEY,
	product_category TEXT,
	product_name_length integer,
	product_description_length integer,
	product_photos_qty integer,
	product_weight_g integer,
	product_length_cm integer,
	product_height_cm integer,
	product_width_cm integer
)
;

BULK INSERT products 
FROM 'C:\Users\amree\Downloads\archive (2)\products.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR ='\n'
	);

--Create customers table and insert records from CSV file
CREATE TABLE customers (
customer_id VARCHAR(150) NOT NULL,
customer_unique_id VARCHAR(150) NOT NULL,
customer_zip_code_prefix INTEGER,
customer_city TEXT,
customer_state TEXT,
CONSTRAINT CUSTOMER PRIMARY KEY (customer_id,customer_unique_id)
)
;

BULK INSERT customers
FROM 'C:\Users\amree\Downloads\archive (2)\customers.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a'
	);

--Create geolocation tables and insert records from geolocation CSV file
CREATE TABLE geolocation (
geolocation_zip_code_prefix INTEGER,
geolocation_lat FLOAT,
geolocation_lng FLOAT,
geolocation_city TEXT,
geolocation_state TEXT

);

BULK INSERT geolocation
FROM 'C:\Users\amree\Downloads\archive (2)\geolocation.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a'
	);

--Create order_items table and insert records from CSV file
CREATE TABLE order_items (

order_id VARCHAR(150) NOT NULL,
order_item_id INTEGER NOT NULL,
product_id VARCHAR(150) NOT NULL,
seller_id VARCHAR(150) NOT NULL,
shipping_limit_date DATETIME,
price FLOAT,
freight_value FLOAT,
CONSTRAINT items PRIMARY KEY (order_id,order_item_id,product_id,seller_id)

);

BULK INSERT order_items
FROM 'C:\Users\amree\Downloads\archive (2)\order_items.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a'
	);

--Create orders table and insert records from CSV file
CREATE TABLE orders (

order_id VARCHAR(150) NOT NULL,
customer_id VARCHAR(150) NOT NULL,
order_status TEXT,
order_purchase_timestamp TIMESTAMP,
order_approved_at DATETIME,
order_delivered_carrier_date DATETIME,
order_delivered_customer_date DATETIME,
order_estimated_delivery_date DATETIME,
CONSTRAINT orders_unique PRIMARY KEY (order_id,customer_id)

);

BULK INSERT orders 
FROM 'C:\Users\amree\Downloads\archive (2)\orders.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0D0A'
	);


--Create payments table and insert records from CSV file
CREATE TABLE payments (

order_id VARCHAR(150),
payment_sequential INTEGER,
payment_type VARCHAR(150),
payment_installments INTEGER,
payment_value FLOAT,
CONSTRAINT payments_unique PRIMARY KEY (order_id,payment_sequential,payment_type)

);

BULK INSERT payments
FROM 'C:\Users\amree\Downloads\archive (2)\payments.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a'
	);

--Create sellers table and insert records from CSV file
CREATE TABLE sellers (

seller_id VARCHAR(150) PRIMARY KEY,
seller_zip_code_prefix INTEGER,
seller_city VARCHAR(150),
seller_state TEXT

);

BULK INSERT sellers
FROM 'C:\Users\amree\Downloads\archive (2)\sellers.csv'
WITH (
	FORMAT = 'CSV',
	FIRSTROW = 2,
	FIELDTERMINATOR = ',',
	ROWTERMINATOR = '0x0a'
	);


--Check all counts against CSV File Counts
SELECT COUNT(1) FROM products; --32,951
SELECT COUNT(1) FROM customers; --99,441
SELECT COUNT(1) FROM sellers; --3,095
SELECT COUNT(1) FROM geolocation; --1,000,163
SELECT COUNT(1) FROM order_items; -- 112,650
SELECT COUNT(1) FROM orders; --99,441
SELECT COUNT(1) FROM payments; --103,886

