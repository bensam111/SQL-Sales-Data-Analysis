/*==========================================================
   CREATE DATABASE
   This ensures a fresh database is created for the project
===========================================================*/

IF DB_ID('SalesDB') IS NOT NULL
    DROP DATABASE SalesDB;
GO

CREATE DATABASE SalesDB;
GO

USE SalesDB;
GO


/*==========================================================
   CREATE TABLES
   Define structure for Products, Customers, and Sales
===========================================================*/

-- Products Table: Stores product details
CREATE TABLE Products (
    ProductID INT IDENTITY(1,1) PRIMARY KEY,  -- Unique product ID
    ProductName VARCHAR(100),                 -- Name of product
    Category VARCHAR(50),                     -- Product category
    Price DECIMAL(10,2)                       -- Product price
);

-- Customers Table: Stores customer information
CREATE TABLE Customers (
    CustomerID INT IDENTITY(1,1) PRIMARY KEY, -- Unique customer ID
    CustomerName VARCHAR(100),                -- Customer name
    Email VARCHAR(100),                       -- Email (can be NULL)
    Region VARCHAR(50)                        -- Customer region
);

-- Sales Table: Stores transaction data
CREATE TABLE Sales (
    SaleID INT IDENTITY(1,1) PRIMARY KEY,     -- Unique sale ID
    ProductID INT,                            -- Linked product
    CustomerID INT,                           -- Linked customer
    Quantity INT,                             -- Quantity sold
    Price DECIMAL(10,2),                      -- Price at time of sale
    Region VARCHAR(50),                       -- Region of sale
    SaleDate DATE,                            -- Date of transaction

    -- Foreign key relationships
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);
GO


/*==========================================================
   INSERT SAMPLE DATA
   Populate tables with realistic business data
===========================================================*/

-- Insert products
INSERT INTO Products (ProductName, Category, Price)
VALUES
('Sony Headphones', 'Electronics', 180.00),
('MacBook Air', 'Computers', 1350.00),
('Gaming Mouse', 'Computers', 75.00),
('Dining Table', 'Furniture', 450.00),
('Bookshelf', 'Furniture', 220.00),
('Vacuum Cleaner', 'Home Appliance', 160.00),
('Coffee Maker', 'Home Appliance', 95.00),
('Smart TV', 'Electronics', 800.00),
('Printer', 'Office Equipment', 210.00),
('Air Purifier', 'Home Appliance', 190.00);

-- Insert customers
INSERT INTO Customers (CustomerName, Email, Region)
VALUES
('Emma Johnson', 'emma@example.com', 'North'),
('David Clark', 'david@example.com', 'South'),
('Olivia Harris', NULL, 'East'),
('Noah Walker', 'noah@example.com', 'West'),
('Lily Turner', 'lily@example.com', 'North'),
('Ethan Scott', NULL, 'South'),
('Mia Green', 'mia@example.com', 'East'),
('Lucas Hall', 'lucas@example.com', 'West');

-- Insert sales transactions
INSERT INTO Sales (ProductID, CustomerID, Quantity, Price, Region, SaleDate)
VALUES
(1, 1, 2, 180.00, 'North', '2025-01-12'),
(2, 2, 1, 1350.00, 'South', '2025-02-05'),
(3, 3, 3, 75.00, 'East', '2025-02-18'),
(4, 4, 1, 450.00, 'West', '2025-03-10'),
(5, 5, 2, 220.00, 'North', '2025-03-25'),
(6, 6, 1, 160.00, 'South', '2025-04-08'),
(7, 7, 4, 95.00, 'East', '2025-04-22'),
(8, 8, 1, 800.00, 'West', '2025-05-15'),
(9, 1, 2, 210.00, 'North', '2025-06-01'),
(10, 2, 1, 190.00, 'South', '2025-06-20'),
(3, 7, 2, 75.00, 'East', '2025-07-05'),
(8, 4, 1, 800.00, 'West', '2025-07-18');

SELECT * FROM Products
SELECT * FROM Customers
SELECT * FROM Sales



/*==========================================================
   SECTION A: DATA EXPLORATION
===========================================================*/

-- Display customers and their orders
-- INNER JOIN shows only customers who made purchases
SELECT c.CustomerName, s.SaleID, s.ProductID, s.Quantity, s.Price, s.SaleDate
FROM Customers c
INNER JOIN Sales s 
ON c.CustomerID = s.CustomerID;


/*==========================================================
   SECTION B: JOINS
===========================================================*/

-- 1. All customers including those without orders
SELECT c.CustomerName, s.SaleID, s.ProductID, s.Quantity, s.Price
FROM Customers c
LEFT JOIN Sales s 
ON c.CustomerID = s.CustomerID;

-- 2. All orders including orphan orders
SELECT c.CustomerName, s.SaleID, s.ProductID
FROM Customers c
RIGHT JOIN Sales s
ON c.CustomerID = s.CustomerID;

-- 3. Full dataset (all customers + all orders)
SELECT c.CustomerName, s.SaleID, s.ProductID
FROM Customers c
FULL OUTER JOIN Sales s
ON c.CustomerID = s.CustomerID;


/*==========================================================
   SECTION C: SUBQUERIES
===========================================================*/

-- 1. Customers spending above average
SELECT c.CustomerID, c.CustomerName,
SUM(s.Quantity * s.Price) AS Total_Spending
FROM Customers c 
JOIN Sales s 
ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerID, c.CustomerName
HAVING SUM(s.Quantity * s.Price) >
(
    SELECT AVG(CustomerTotal)
    FROM (
        SELECT CustomerID,
        SUM(Quantity * Price) AS CustomerTotal
        FROM Sales
        GROUP BY CustomerID
    ) AS AvgTable
);

-- 2. Products never ordered
SELECT ProductName
FROM Products
WHERE ProductID NOT IN
(SELECT ProductID FROM Sales);

-- 3. Orders above average value
SELECT SaleID, (Quantity * Price) AS Order_Value
FROM Sales
WHERE (Quantity * Price) >
(SELECT AVG(Quantity * Price) FROM Sales);


/*==========================================================
   SECTION D: CTEs
===========================================================*/

-- 1. Total revenue per customer
WITH CustomerRevenue AS
(
    SELECT c.CustomerName,
    SUM(s.Quantity * s.Price) AS Total_Revenue
    FROM Customers c
    JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerName
)
SELECT * FROM CustomerRevenue;

-- 2. High-value customers
WITH CustomerRevenue AS
(
    SELECT c.CustomerName,
    SUM(s.Quantity * s.Price) AS Total_Revenue
    FROM Customers c
    JOIN Sales s ON c.CustomerID = s.CustomerID
    GROUP BY c.CustomerName
)
SELECT * FROM CustomerRevenue
WHERE Total_Revenue > 1000;

-- 3. Low-stock (high selling) products
WITH ProductSales AS
(
    SELECT p.ProductName,
    SUM(s.Quantity) AS Total_Quantity_Sold
    FROM Products p
    JOIN Sales s ON p.ProductID = s.ProductID
    GROUP BY p.ProductName
)
SELECT * FROM ProductSales
WHERE Total_Quantity_Sold >= 3;


/*==========================================================
   SECTION E: WINDOW FUNCTIONS
===========================================================*/

-- Rank customers by total spending
SELECT c.CustomerName,
SUM(s.Quantity * s.Price) AS Total_Spending,
RANK() OVER (ORDER BY SUM(s.Quantity * s.Price) DESC) AS Rank
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName;

-- Assign row numbers to orders
SELECT SaleID, SaleDate,
ROW_NUMBER() OVER (ORDER BY SaleDate) AS Row_Num
FROM Sales;

-- Difference from previous order
SELECT SaleID,
(Quantity * Price) AS Order_Value,
LAG(Quantity * Price) OVER (ORDER BY SaleDate) AS Previous_Order,
(Quantity * Price) - LAG(Quantity * Price) OVER (ORDER BY SaleDate) AS Difference
FROM Sales;

-- Predict next order value
SELECT SaleID,
(Quantity * Price) AS Order_Value,
LEAD(Quantity * Price) OVER (ORDER BY SaleDate) AS Next_Order
FROM Sales;


/*==========================================================
   SECTION F: SET OPERATIONS
===========================================================*/

-- UNION: combine product categories
SELECT ProductName FROM Products WHERE Category = 'Electronics'
UNION
SELECT ProductName FROM Products WHERE Category = 'Home Appliance';

-- INTERSECT: customers with orders and payments (simulated using CTE)
WITH Payments AS (
    SELECT 1 AS CustomerID UNION
    SELECT 2 UNION
    SELECT 3 UNION
    SELECT 6
)
SELECT CustomerID FROM Sales
INTERSECT
SELECT CustomerID FROM Payments;

-- UNION ALL: combine monthly sales
SELECT SaleID, (Quantity * Price) AS Order_Value, 'Jan' AS Month
FROM Sales WHERE MONTH(SaleDate) = 1
UNION ALL
SELECT SaleID, (Quantity * Price), 'Feb'
FROM Sales WHERE MONTH(SaleDate) = 2;


/*==========================================================
   SECTION G: BUSINESS QUESTIONS
===========================================================*/

-- Top 5 customers by revenue
SELECT TOP 5 c.CustomerName,
SUM(s.Quantity * s.Price) AS Total_Revenue
FROM Customers c
JOIN Sales s ON c.CustomerID = s.CustomerID
GROUP BY c.CustomerName
ORDER BY Total_Revenue DESC;

-- Best-performing products
SELECT p.ProductName,
SUM(s.Quantity * s.Price) AS Total_Revenue
FROM Products p
JOIN Sales s ON p.ProductID = s.ProductID
GROUP BY p.ProductName
ORDER BY Total_Revenue DESC;

-- Inactive customers (no purchases)
SELECT c.CustomerName
FROM Customers c
LEFT JOIN Sales s ON c.CustomerID = s.CustomerID
WHERE s.CustomerID IS NULL;

-- Average order value
SELECT AVG(Quantity * Price) AS Avg_Order_Value
FROM Sales;

-- High-value orders
SELECT SaleID, (Quantity * Price) AS Order_Value
FROM Sales
WHERE (Quantity * Price) > 1000;

-- Sales trends over time (monthly)
SELECT DATENAME(MONTH, SaleDate) AS Month,
SUM(Quantity * Price) AS Total_Sales
FROM Sales
GROUP BY DATENAME(MONTH, SaleDate), MONTH(SaleDate)
ORDER BY MONTH(SaleDate);