set statistics io,time on

--Create Indexes
CREATE NONCLUSTERED INDEX IDX_Orders ON orders(customer_id) INCLUDE (order_purchase_timestamp,order_delivered_carrier_date) ;
CREATE INDEX idx_customers_id ON customers(customer_id);
CREATE INDEX idx_orders_id ON orders(order_id);
CREATE INDEX idx_customers_orders ON customers(customer_zip_code_prefix) INCLUDE (customer_city);
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_products_product_id ON products(product_id);
CREATE INDEX idx_payments_order_id ON payments(order_id);
CREATE INDEX idx_order_items_grouping ON order_items (order_id, product_id, price);

--Preaggregate data
DROP TABLE IF EXISTS staged_payments;
CREATE TABLE staged_payments (
    order_id VARCHAR(150),
    payment_type VARCHAR(150),
    max_payment_sequential INT
);

-- Ensure the table is empty before insertion
TRUNCATE TABLE staged_payments;
INSERT INTO staged_payments
SELECT 
    order_id,
    payment_type,
    MAX(payment_sequential) AS max_payment_sequential
FROM payments
GROUP BY 
    order_id,
    payment_type;


-- Create the staging table (if not already existing)
CREATE TABLE staged_order_items (
    order_id VARCHAR(150),
    product_id VARCHAR(150),
    total_price FLOAT,
    product_count INT
);

-- Ensure the table is empty before insertion
TRUNCATE TABLE staged_order_items;

-- Insert aggregated data
INSERT INTO staged_order_items
SELECT 
    order_id,
    product_id,
    SUM(price) AS total_price,
    COUNT(product_id) AS product_count
FROM 
    order_items
GROUP BY 
    order_id, 
    product_id;

--Join customers and orders table, this is an expensive hash join so doing this separately
DROP TABLE IF EXISTS customer_orders;
CREATE TABLE customer_orders (
    order_id VARCHAR(150),
    order_status VARCHAR(100),
    customer_city VARCHAR(100),
    customer_zip_code_prefix VARCHAR(100),
	order_purchase_timestamp DATETIME
);

INSERT INTO customer_orders (order_id, order_status, customer_city, customer_zip_code_prefix,order_purchase_timestamp)
SELECT 
    o.order_id,
    o.order_status,
    c.customer_city,
    c.customer_zip_code_prefix,
	o.order_purchase_timestamp
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
OPTION (HASH JOIN, MAXDOP 2);

--Create Final Table
DROP TABLE IF EXISTS order_activity;
CREATE TABLE order_activity (
    order_id VARCHAR(150),
    price FLOAT,
    product_id VARCHAR(150),
    product_category VARCHAR(100),
    customer_city VARCHAR(100),
    customer_zip_code_prefix VARCHAR(100),
    max_payment_sequential INT,
    payment_type VARCHAR(150),
	order_purchase_timestamp DATETIME,
    order_status VARCHAR(100)
);


INSERT INTO order_activity (
    order_id,
    price,
    product_id,
    product_category,
    customer_city,
    customer_zip_code_prefix,
    max_payment_sequential,
    payment_type,
	order_purchase_timestamp,
    order_status
)
SELECT
    c.order_id,
    i.total_price AS price,
    prod.product_id,
    prod.product_category,
    c.customer_city,
    c.customer_zip_code_prefix,
    pay.max_payment_sequential,
    pay.payment_type AS payment_type,
	c.order_purchase_timestamp,
    c.order_status
FROM customer_orders c
LEFT JOIN staged_order_items i ON i.order_id = c.order_id
LEFT JOIN products prod ON i.product_id = prod.product_id
LEFT JOIN staged_payments pay ON c.order_id = pay.order_id
OPTION (HASH JOIN, MAXDOP 2);

--SELECT distinct count(order_id) from order_activity;
