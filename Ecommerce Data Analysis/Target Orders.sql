SET STATISTICS IO,TIME ON

--CREATE INDEXES
CREATE NONCLUSTERED INDEX IDX_ORDERS ON ORDERS(CUSTOMER_ID) INCLUDE (ORDER_PURCHASE_TIMESTAMP,ORDER_DELIVERED_CARRIER_DATE) ;
CREATE INDEX IDX_CUSTOMERS_ID ON CUSTOMERS(CUSTOMER_ID);
CREATE INDEX IDX_ORDERS_ID ON ORDERS(ORDER_ID);
CREATE INDEX IDX_CUSTOMERS_ORDERS ON CUSTOMERS(CUSTOMER_ZIP_CODE_PREFIX) INCLUDE (CUSTOMER_CITY);
CREATE INDEX IDX_ORDERS_CUSTOMER_ID ON ORDERS(CUSTOMER_ID);
CREATE INDEX IDX_ORDER_ITEMS_ORDER_ID ON ORDER_ITEMS(ORDER_ID);
CREATE INDEX IDX_ORDER_ITEMS_PRODUCT_ID ON ORDER_ITEMS(PRODUCT_ID);
CREATE INDEX IDX_PRODUCTS_PRODUCT_ID ON PRODUCTS(PRODUCT_ID);
CREATE INDEX IDX_PAYMENTS_ORDER_ID ON PAYMENTS(ORDER_ID);
CREATE INDEX IDX_ORDER_ITEMS_GROUPING ON ORDER_ITEMS (ORDER_ID, PRODUCT_ID, PRICE);

--PREAGGREGATE DATA
DROP TABLE IF EXISTS STAGED_PAYMENTS;
CREATE TABLE STAGED_PAYMENTS (
    ORDER_ID VARCHAR(150),
    PAYMENT_TYPE VARCHAR(150),
	PAYMENT_VALUE FLOAT,
    MAX_PAYMENT_SEQUENTIAL INT
);

-- ENSURE THE TABLE IS EMPTY BEFORE INSERTION
TRUNCATE TABLE STAGED_PAYMENTS;
INSERT INTO STAGED_PAYMENTS
SELECT 
    ORDER_ID,
    PAYMENT_TYPE,
	PAYMENT_VALUE,
    MAX(PAYMENT_SEQUENTIAL) AS MAX_PAYMENT_SEQUENTIAL
FROM PAYMENTS
GROUP BY 
    ORDER_ID,
    PAYMENT_TYPE,
	PAYMENT_VALUE;


-- CREATE THE STAGING TABLE (IF NOT ALREADY EXISTING)
CREATE TABLE STAGED_ORDER_ITEMS (
    ORDER_ID VARCHAR(150),
    PRODUCT_ID VARCHAR(150),
    TOTAL_PRICE FLOAT,
    PRODUCT_COUNT INT
);

-- ENSURE THE TABLE IS EMPTY BEFORE INSERTION
TRUNCATE TABLE STAGED_ORDER_ITEMS;

-- INSERT AGGREGATED DATA
INSERT INTO STAGED_ORDER_ITEMS
SELECT 
    ORDER_ID,
    PRODUCT_ID,
    SUM(PRICE) AS TOTAL_PRICE,
    COUNT(PRODUCT_ID) AS PRODUCT_COUNT
FROM 
    ORDER_ITEMS
GROUP BY 
    ORDER_ID, 
    PRODUCT_ID;

--JOIN CUSTOMERS AND ORDERS TABLE, THIS IS AN EXPENSIVE HASH JOIN SO DOING THIS SEPARATELY
DROP TABLE IF EXISTS CUSTOMER_ORDERS;
CREATE TABLE CUSTOMER_ORDERS (
    ORDER_ID VARCHAR(150),
    ORDER_STATUS VARCHAR(100),
    CUSTOMER_CITY VARCHAR(100),
    CUSTOMER_ZIP_CODE_PREFIX VARCHAR(100),
	ORDER_PURCHASE_TIMESTAMP DATETIME
);

INSERT INTO CUSTOMER_ORDERS (ORDER_ID, ORDER_STATUS, CUSTOMER_CITY, CUSTOMER_ZIP_CODE_PREFIX,ORDER_PURCHASE_TIMESTAMP)
SELECT 
    O.ORDER_ID,
    O.ORDER_STATUS,
    C.CUSTOMER_CITY,
    C.CUSTOMER_ZIP_CODE_PREFIX,
	O.ORDER_PURCHASE_TIMESTAMP
FROM CUSTOMERS C
INNER JOIN ORDERS O ON C.CUSTOMER_ID = O.CUSTOMER_ID
OPTION (HASH JOIN, MAXDOP 2);

--CREATE FINAL TABLE
DROP TABLE IF EXISTS ORDER_ACTIVITY;
CREATE TABLE ORDER_ACTIVITY (
    ORDER_ID VARCHAR(150),
    PRICE FLOAT,
    PRODUCT_ID VARCHAR(150),
    PRODUCT_CATEGORY VARCHAR(100),
    CUSTOMER_CITY VARCHAR(100),
    CUSTOMER_ZIP_CODE_PREFIX VARCHAR(100),
    MAX_PAYMENT_SEQUENTIAL INT,
    PAYMENT_TYPE VARCHAR(150),
	PAYMENT_VALUE FLOAT,
	ORDER_PURCHASE_TIMESTAMP DATETIME,
    ORDER_STATUS VARCHAR(100)
);


INSERT INTO ORDER_ACTIVITY (
    ORDER_ID,
    PRICE,
    PRODUCT_ID,
    PRODUCT_CATEGORY,
    CUSTOMER_CITY,
    CUSTOMER_ZIP_CODE_PREFIX,
    MAX_PAYMENT_SEQUENTIAL,
    PAYMENT_TYPE,
	PAYMENT_VALUE,
	ORDER_PURCHASE_TIMESTAMP,
    ORDER_STATUS
)
SELECT
    C.ORDER_ID,
    I.TOTAL_PRICE AS PRICE,
    PROD.PRODUCT_ID,
    PROD.PRODUCT_CATEGORY,
    C.CUSTOMER_CITY,
    C.CUSTOMER_ZIP_CODE_PREFIX,
    PAY.MAX_PAYMENT_SEQUENTIAL,
    PAY.PAYMENT_TYPE AS PAYMENT_TYPE,
	PAY.PAYMENT_VALUE,
	C.ORDER_PURCHASE_TIMESTAMP,
    C.ORDER_STATUS
FROM CUSTOMER_ORDERS C
LEFT JOIN STAGED_ORDER_ITEMS I ON I.ORDER_ID = C.ORDER_ID
LEFT JOIN PRODUCTS PROD ON I.PRODUCT_ID = PROD.PRODUCT_ID
LEFT JOIN STAGED_PAYMENTS PAY ON C.ORDER_ID = PAY.ORDER_ID
OPTION (HASH JOIN, MAXDOP 2);

--SELECT DISTINCT COUNT(ORDER_ID) FROM ORDER_ACTIVITY;
