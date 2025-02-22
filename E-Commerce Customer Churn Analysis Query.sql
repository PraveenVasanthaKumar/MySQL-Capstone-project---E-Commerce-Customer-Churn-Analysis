-- Project Title: E-Commerce Customer Churn Analysis -----

USE ecomm;

SELECT * FROM customer_churn;

-- Disable safe updates
SET SQL_SAFE_UPDATES = 0;

-- Project Steps and Objectives: 
-- DATA CLEANING

-- Handling Missing Values and Outliers:
-- ➢ Impute mean for the following columns, and round off to the nearest integer if required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,DaySinceLastOrder.

SET @warehouseToHome_avg = (SELECT AVG(warehouseToHome) FROM customer_churn);
SELECT @warehouseToHome_avg;

UPDATE customer_churn
SET warehouseToHome = @warehouseToHome_avg
WHERE warehouseToHome IS NULL;

SELECT * FROM customer_churn;

SET @HourSpendOnApp_avg = (SELECT AVG(HourSpendOnApp) FROM customer_churn);
SELECT @HourSpendOnApp_avg;

UPDATE customer_churn
SET HourSpendOnApp = @HourSpendOnApp_avg
WHERE HourSpendOnApp IS NULL;

SELECT * FROM customer_churn;

SET @OrderAmountHikeFromlastYear_avg = (SELECT AVG(OrderAmountHikeFromlastYear) FROM customer_churn);
SELECT @OrderAmountHikeFromlastYear_avg;

UPDATE customer_churn
SET OrderAmountHikeFromlastYear = @OrderAmountHikeFromlastYear_avg
WHERE OrderAmountHikeFromlastYear IS NULL;

SELECT * FROM customer_churn;

SET @DaySinceLastOrder_avg = (SELECT AVG(DaySinceLastOrder) FROm customer_churn);
SELECT @DaySinceLastOrder_avg;

UPDATE customer_churn
SET DaySinceLastOrder = @DaySinceLastOrder_avg
WHERE DaySinceLastOrder IS NULL;

SELECT * FROM customer_churn;

-- ➢ Impute mode for the following columns: Tenure, CouponUsed, OrderCount.

SET @Tenure_mode = (SELECT Tenure FROM customer_churn GROUP BY Tenure ORDER BY  COUNT(*) DESC LIMIT 1);
SELECT @Tenure_mode;

UPDATE customer_churn
SET Tenure = @Tenure_mode
WHERE Tenure IS NULL;

SELECT * FROM customer_churn;

SET @CouponUsed_mode = (SELECT CouponUsed FROM customer_churn GROUP BY CouponUsed ORDER BY COUNT(*) DESC LIMIT 1);
SELECT @CouponUsed_mode;

UPDATE customer_churn
SET CouponUsed = @CouponUsed_mode
WHERE CouponUsed IS NULL;

SELECT * FROM customer_churn;

SET @OrderCount_mode = (SELECT OrderCount FROM customer_churn GROUP BY OrderCount ORDER BY COUNT(*) DESC LIMIT 1);
SELECT @OrderCount_mode;

UPDATE customer_churn
SET OrderCount = @OrderCount_mode
WHERE OrderCount IS NULL;

SELECT * FROM customer_churn;

-- ➢ Handle outliers in the 'WarehouseToHome' column by deleting rows where the values are greater than 100.

DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- Dealing with Inconsistencies:

-- ➢ Replace occurrences of “Phone” in the 'PreferredLoginDevice' column and “Mobile” in the 'PreferedOrderCat' column with “Mobile Phone” to ensure uniformity.

UPDATE customer_churn
SET PreferredLoginDevice = CASE
							 WHEN PreferredLoginDevice = 'Phone' THEN 'Mobile Phone'
                             ELSE PreferredLoginDevice
                             END,
	PreferedOrderCat = CASE
                          WHEN PreferedOrderCat = 'Mobile' THEN 'Mobile Phone'
                          ELSE PreferedOrderCat
                          END;

SELECT * FROM customer_churn;

-- ➢ Standardize payment mode values: Replace "COD" with "Cash on Delivery" and "CC" with "Credit Card" in the PreferredPaymentMode column.

UPDATE customer_churn
SET PreferredPaymentMode = CASE
                             WHEN PreferredPaymentMode = 'COD' THEN 'Cash on Delivery'
                             WHEN PreferredPaymentMode = 'CC' THEN 'Credit Card'
                             ELSE PreferredPaymentMode
                             END;
                             
SELECT * FROM customer_churn;     

-- Data Transformation:  
-- ➢ Rename the column "PreferedOrderCat" to "PreferredOrderCat".
-- ➢ Rename the column "HourSpendOnApp" to "HoursSpentOnApp".

ALTER TABLE customer_churn
RENAME COLUMN PreferedOrderCat to PreferredOrderCat,
RENAME COLUMN HourSpendOnApp to HoursSpentOnApp;     

-- Creating New Columns:      

-- ➢ Create a new column named ‘ComplaintReceived’ with values "Yes" if the corresponding value in the ‘Complain’ is 1, and "No" otherwise.  
-- ➢ Create a new column named 'ChurnStatus'. Set its value to “Churned” if the corresponding value in the 'Churn' column is 1, else assign “Active”.

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR (3),
ADD COLUMN ChurnStatus VARCHAR (10);      

SELECT * FROM customer_churn;  

-- Set values for the new columns based on existing  data
UPDATE customer_churn
SET ComplaintReceived = IF(Complain = 1, 'Yes', 'No'),
    ChurnStatus =IF (Churn = 1, 'Churned', 'Active');
    
SELECT * FROM customer_churn; 

-- Column Dropping:
-- ➢ Drop the columns "Churn" and "Complain" from the table.

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

SELECT * FROM customer_churn; 


-- Data Exploration and Analysis:

-- 1. Retrieve the count of churned and active customers from the dataset.
SELECT ChurnStatus, Count(*) AS CustomerCount
FROM customer_churn
GROUP BY ChurnStatus;

-- 2. Display the average tenure of customers who churned.
SELECT ChurnStatus, AVG(Tenure) AS Avg_tenure
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 3. Calculate the total cashback amount earned by customers who churned.
SELECT ChurnStatus, SUM(CashbackAmount) AS Totalcashbackamount
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 4. Determine the percentage of churned customers who complained.
SELECT ChurnStatus, CONCAT(ROUND((SELECT COUNT(*) FROM customer_churn WHERE ComplaintReceived = 'Yes'
AND ChurnStatus = 'Churned') / COUNT(*) * 100, 2), '%') AS PercentageofChurnedcustomer
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- 5. Find the gender distribution of customers who complained.
SELECT Gender, COUNT(*) AS TotalComplaint
FROM customer_churn
WHERE ComplaintReceived = 'Yes'
GROUP BY Gender;

-- 6. Identify the city tier with the highest number of churned customers whose preferred order category is Laptop & Accessory.
SELECT PreferredOrderCat, CityTier, COUNT(*) AS ChurnedCount
FROM customer_churn
WHERE ChurnStatus = 'Churned'
  AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY CityTier
ORDER BY ChurnedCount DESC
LIMIT 1;

-- 7. Identify the most preferred payment mode among active customers.
SELECT PreferredPaymentMode, COUNT(*) AS TotalPurchaseCount
FROM customer_churn
WHERE ChurnStatus = 'Active'
GROUP BY PreferredPaymentMode
ORDER BY TotalPurchaseCount DESC
LIMIT 1;

-- 8. List the preferred login device(s) among customers who took more than 10 days since their last order.
SELECT PreferredLoginDevice, COUNT(*) AS DeviceCount
FROM customer_churn
WHERE DaySinceLastOrder > 10
GROUP BY PreferredLoginDevice
ORDER BY DeviceCount DESC;

-- 9. List the number of active customers who spent more than 3 hours on the app.
SELECT ChurnStatus, COUNT(*) AS TotalCountofCustomer
FROM customer_churn
WHERE ChurnStatus = 'Active' AND HoursSpentOnApp > 3;

-- 10. Find the average cashback amount received by customers who spent at least 2 hours on the app.
SELECT ROUND(AVG(CashbackAmount),2) AS Avg_cashback
FROM customer_churn
WHERE HoursSpentOnApp >= 2;

-- 11. Display the maximum hours spent on the app by customers in each preferred order category.
SELECT PreferredOrderCat, MAX(HoursSpentOnApp) AS Max_Hours_Spent
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY Max_Hours_Spent DESC;

-- 12. Find the average order amount hike from last year for customers in each marital status category.
SELECT MaritalStatus, ROUND(AVG(OrderAmountHikeFromlastYear),2) AS Avg_Order_Hike_Lastyear
FROM customer_churn
GROUP BY MaritalStatus
ORDER BY Avg_Order_Hike_lastyear DESC;

-- 13. Calculate the total order amount hike from last year for customers who are single and prefer mobile phones for ordering.
SELECT SUM(OrderAmountHikeFromlastYear) AS Total_order_amount
FROM customer_churn
WHERE MaritalStatus = 'Single' AND PreferredLoginDevice = 'Mobile Phone';

-- 14. Find the average number of devices registered among customers who used UPI as their preferred payment mode.
SELECT PreferredPaymentMode, ROUND(AVG(NumberOfDeviceRegistered)) AS Avg_No_of_Reg_Device
FROM customer_churn
WHERE PreferredPaymentMode = 'UPI';

-- 15. Determine the city tier with the highest number of customers.
SELECT CityTier, COUNT(*) AS Total_customers
FROM customer_churn
GROUP BY CityTier
ORDER BY Total_customers DESC
LIMIT 1;

-- 16. Find the marital status of customers with the highest number of addresses.
-- Status
SELECT MaritalStatus 
FROM customer_churn
WHERE NumberOfAddress =(SELECT MAX(NumberOfAddress) FROM customer_churn);
-- Status and Values
SELECT MaritalStatus, MAX(NumberOfAddress) AS Max_Address
FROM customer_churn
GROUP BY MaritalStatus
ORDER BY Max_Address DESC
LIMIT 1;

-- 17. Identify the gender that utilized the highest number of coupons.
SELECT Gender, SUM(CouponUsed) AS Total_Coupon_Used
FROM customer_churn
GROUP BY Gender
ORDER BY Total_Coupon_Used DESC
LIMIT 1;

-- 18. List the average satisfaction score in each of the preferred order categories.
SELECT PreferredOrderCat, ROUND(AVG(SatisfactionScore)) AS Avg_satisfaction_Score
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY Avg_satisfaction_Score;

-- 19. Calculate the total order count for customers who prefer using credit cards and have the maximum satisfaction score.
SELECT PreferredPaymentMode, COUNT(*) AS Total_order_count
FROM customer_churn
WHERE PreferredPaymentMode = 'Credit Card' AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- 20. How many customers are there who spent only one hour on the app and days since their last order was more than 5?
SELECT COUNT(*) AS Customer_count
FROM customer_churn
WHERE HoursSpentOnApp = 1 AND DaySinceLastOrder > 5;

-- 21. What is the average satisfaction score of customers who have complained?
SELECT ComplaintReceived, ROUND(AVG(SatisfactionScore)) AS Avg_Satisfaction_Score
FROM customer_churn
WHERE ComplaintReceived = 'Yes';

-- 22. How many customers are there in each preferred order category?
SELECT PreferredOrderCat, COUNT(*) AS Customer_count
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY Customer_count DESC;

-- 23. What is the average cashback amount received by married customers?
SELECT MaritalStatus, ROUND(AVG(CashbackAmount)) AS Avg_cashback_amount
FROM customer_churn
WHERE MaritalStatus = 'Married';

-- 24. What is the average number of devices registered by customers who are not using Mobile Phone as their preferred login device?
SELECT PreferredLoginDevice, ROUND(AVG(NumberOfDeviceRegistered)) AS Avg_device_registered
FROM customer_churn
GROUP BY PreferredLoginDevice 
HAVING PreferredLoginDevice <> 'Mobile Phone';

-- 25. List the preferred order category among customers who used more than 5 coupons.
SELECT PreferredOrderCat, COUNT(*) AS Order_Count
FROM customer_churn
WHERE CouponUsed > 5
GROUP BY PreferredOrderCat
ORDER BY Order_Count DESC;

-- 26. List the top 3 preferred order categories with the highest average cashback amount.
SELECT PreferredOrderCat, ROUND(AVG(CashbackAmount)) AS Avg_cash_back
FROM customer_churn
GROUP BY PreferredOrderCat
ORDER BY Avg_cash_back DESC
LIMIT 3;

-- 27. Find the preferred payment modes of customers whose average tenure is 10 months and have placed more than 500 orders.
SELECT PreferredPaymentMode, ROUND(AVG(Tenure)) AS Avg_Tenure, COUNT(*) OrderCount
FROM customer_churn
GROUP BY PreferredPaymentMode
HAVING Avg_tenure = 10 AND OrderCount > 500;

-- 28. Categorize customers based on their distance from the warehouse to home such as 'Very Close Distance'
-- for distances <=5km, 'Close Distance' for <=10km, 'Moderate Distance' for <=15km, and 'Far Distance' for >15km. 
-- Then, display the churn status breakdown for each distance category.

SELECT
      CASE 
		  WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
          WHEN WarehouseToHome <= 10 THEN 'Close Distance'
          WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
          ELSE 'Far Distance'
      END AS Distance_Category,
      ChurnStatus, COUNT(*) AS Customer_count
      FROM customer_churn
      GROUP BY Distance_Category, ChurnStatus
      ORDER BY FIELD(Distance_Category, 
      'Very Close Distance', 
      'Close Distance', 
      'Moderate Distance',
      'Fare Distance'),
      ChurnStatus;

-- 29. List the customer’s order details who are married, live in City Tier-1, and their order counts are 
-- more than the average number of orders placed by all customers.      

SELECT * FROM customer_churn
WHERE MaritalStatus = 'Married'
      AND CityTier = 1
      AND OrderCount >(SELECT ROUND(AVG(OrderCount)) FROM customer_churn)
      ORDER BY CustomerID;
      
-- 30. a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the
-- following data:
-- ReturnID CustomerID ReturnDate RefundAmount
-- 1001 50022 2023-01-01 2130
-- 1002 50316 2023-01-23 2000
-- 1003 51099 2023-02-14 2290
-- 1004 52321 2023-03-08 2510
-- 1005 52928 2023-03-20 3000
-- 1006 53749 2023-04-17 1740
-- 1007 54206 2023-04-21 3250
-- 1008 54838 2023-04-30 1990

CREATE TABLE customer_returns(
	ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount DECIMAL(10, 2));
    
INSERT INTO customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount)
VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);  

-- b) Display the return details along with the customer details of those who have churned and have made complaints. 

SELECT 
     cr.*,
     cc.Tenure,
     cc.PreferredLoginDevice,
     cc.CityTier,
     cc.WarehouseToHome,
     cc.PreferredPaymentMode,
     cc.Gender,
     cc.HoursSpentOnApp,
     cc.NumberOfDeviceRegistered,
     cc.PreferredOrderCat,
     cc.SatisfactionScore,
     cc.MaritalStatus,
     cc.NumberOfAddress,
     cc.OrderAmountHikeFromlastYear,
     cc.CouponUsed,
     cc.OrderCount,
     cc.DaySinceLastOrder,
     cc.CashbackAmount
FROM customer_returns cr
JOIN customer_churn cc
ON cc.CustomerID = cr.CustomerID
WHERE cc.Churnstatus = 'Churned' AND cc.ComplaintReceived = 'Yes';     
     
     
------------------------------------------------------------ END --------------------------------------------------------------------------------------
     
     


      

