SELECT COUNT(*) FROM supermarket_sales;

SELECT * FROM supermarket_sales;

-- DATA CLEANING 
-- check for duplicate values in the data
SELECT invoice_id, date, total, unit_price, cogs, gross_income, time, COUNT(*)
FROM supermarket_sales
GROUP BY invoice_id, date, total, unit_price, cogs, gross_income, time
HAVING COUNT(*) > 1;

-- check for null values 
SELECT *
FROM supermarket_sales
WHERE invoice_id IS NULL; -- (only one row is fully null)

-- get rid of 00:00:00 after each date (convert from DATETIME TO DATE)
ALTER TABLE supermarket_sales MODIFY COLUMN date DATE; 

-- Convert the military time to standard time
SET SQL_SAFE_UPDATES = 0;
ALTER TABLE supermarket_sales
MODIFY COLUMN standard_time VARCHAR(11);

UPDATE supermarket_sales
SET standard_time = DATE_FORMAT(time, '%r');
SET SQL_SAFE_UPDATES = 1;

-- GENERAL QUESTIONS 
-- How many cities are there? 
SELECT DISTINCT City 
FROM supermarket_sales;

-- How many branches are there?
SELECT DISTINCT branch 
FROM supermarket_sales;

-- Which city is associated with what branch? 
SELECT DISTINCT City, branch 
FROM supermarket_sales;

-- CUSTOMER ANALYSIS 
-- How many customer types are there?
SELECT DISTINCT customer_type 
FROM supermarket_sales;

-- What are the payment methods?
SELECT DISTINCT(payment_type) 
FROM supermarket_sales;

-- What is the most common customer type? 
SELECT customer_type, COUNT(customer_type) AS customer_count
FROM supermarket_sales 
GROUP BY customer_type
ORDER BY customer_count DESC;

-- From the customers, what is the most common gender?
SELECT gender, COUNT(gender) AS gender_count
FROM supermarket_sales
GROUP BY gender
ORDER BY gender_count DESC;

-- What is the gender distribution per branch?
SELECT gender, COUNT(*) AS gender_count
FROM supermarket_sales
WHERE branch = 'C' -- can replace branch letter here to check for banch B and branch C too
GROUP BY gender
ORDER BY gender_count DESC;

-- Which time of the day do customers give most ratings per branch?
-- Create new time column
SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales
SET time_of_day =
CASE 
    WHEN standard_time BETWEEN '12:00:00 AM' AND '12:00:00 PM' THEN 'Morning'
    WHEN standard_time BETWEEN '12:01:00 PM' AND '04:00:00 PM' THEN 'Afternoon'
    ELSE 'Evening'
END
WHERE time_of_day IS NULL;
SET SQL_SAFE_UPDATES = 1;

SELECT time_of_day, AVG(rating)
FROM supermarket_sales
WHERE branch = 'A' -- can replace 'A' with 'B'/'C' to check most ratings per branch for each day
GROUP BY time_of_day
ORDER BY AVG(rating) DESC;

-- Which day of the week has the best average ratings?
-- Create day name column in table --
ALTER TABLE supermarket_sales
ADD COLUMN day_name VARCHAR(10),
ADD COLUMN season VARCHAR(10); 

SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales 
SET day_name = DAYNAME(date), 
season = CASE 
	WHEN month_name IN ("December", "January", "February") THEN "Winter"
	WHEN month_name IN ("March", "April", "May") THEN "Spring"
	WHEN month_name IN ("June", "July", "August") THEN "Summer"
	ELSE "Fall"
	END
WHERE date IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

SELECT day_name, AVG(rating)
FROM supermarket_sales
GROUP BY day_name
ORDER BY AVG(rating) DESC;

-- Which day of the week has the best average ratings per branch?
SELECT day_name, AVG(rating)
FROM supermarket_sales
WHERE branch = 'A' -- can replace 'A' with 'B'/'C' to check best avg rating per branch for each day
GROUP BY day_name
ORDER BY AVG(rating) DESC;

-- Which branch has the most loyal customers (based off of number of repeated purchases)?
SELECT branch, customer_type, COUNT(invoice_id) AS repeated_purchases
FROM supermarket_sales
WHERE customer_type = "Normal" -- or "Normal" customer type
GROUP BY branch, customer_type
ORDER BY repeated_purchases DESC; 

-- What is the average spending per customer type?
SELECT customer_type, AVG(total) AS avg_spending
FROM supermarket_sales
GROUP BY customer_type
ORDER BY avg_spending DESC;

-- Rank the customer type by their total spending
SELECT customer_type, SUM(total) AS total_spent,
RANK() OVER (ORDER BY SUM(total) DESC) AS spending_rank
FROM supermarket_sales
GROUP BY customer_type
ORDER BY spending_rank;

-- What gender spends more on average?
SELECT gender, AVG(total) AS avg_spending
FROM supermarket_sales
GROUP BY gender
ORDER BY avg_spending DESC;

-- What time of day do customers spend the most (peak purchasing time)?
SELECT time_of_day, AVG(total) AS avg_spending
FROM supermarket_sales
-- WHERE customer_type = "Member" -- can specify what customer type or gender/otherwise can keep it general
GROUP BY time_of_day
ORDER BY avg_spending DESC;

-- What payment type is preferred by different customer types?
SELECT customer_type, payment_type, COUNT(*) AS count
FROM supermarket_sales
GROUP BY customer_type, payment_type
ORDER BY customer_type, count DESC;

-- Segment the top spenders by gender
SELECT gender,customer_type, SUM(total) AS total_spending,
NTILE(10) OVER (PARTITION BY gender ORDER BY SUM(total) DESC) AS spending_decile
FROM supermarket_sales
GROUP BY gender, customer_type
ORDER BY gender, spending_decile;

-- PRODUCT ANALYSIS 
-- How many product lines are in the data?
SELECT DISTINCT product_line 
FROM supermarket_sales;

-- What product line sells the most?
SELECT product_line, SUM(quantity) AS qty
FROM supermarket_sales 
GROUP BY product_line
ORDER BY qty DESC;

-- What is the most common payment method?
SELECT payment_type, COUNT(payment_type) AS count 
FROM supermarket_sales 
GROUP BY payment_type
ORDER BY count DESC;

-- What is the total revenue by month?
-- Create month name column in table --
SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales 
SET month_name = MONTHNAME(date)
WHERE date IS NOT NULL;
SET SQL_SAFE_UPDATES = 1;

SELECT month_name, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY month_name
ORDER BY total_revenue DESC;

-- What month had the largest COGS?
SELECT month_name, SUM(cogs) AS largest_cog
FROM supermarket_sales
GROUP BY month_name
ORDER BY largest_cog DESC;

-- What product line had the largest revenue?
SELECT product_line, 
SUM(total) AS total_revenue,
RANK() OVER (ORDER BY SUM(total) DESC) AS revenue_rank
FROM supermarket_sales
GROUP BY product_line
ORDER BY revenue_rank;

-- Create view for total sales per day
CREATE VIEW daily_sales AS
SELECT date, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY date
ORDER BY date;
SELECT * FROM daily_sales;

-- What is the city with the largest revenue?
SELECT branch, city, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY branch, city
ORDER BY total_revenue DESC;

-- What product line gets taxed the most?
SELECT product_line, AVG(tax_percentage) AS tax
FROM supermarket_sales
GROUP BY product_line
ORDER BY tax DESC;

-- How can I categorize product lines as 
-- "Highly Rated" or "Poorly Rated" based on their average customer rating?
-- Create temp table and ...
SELECT product_line,
CASE
	WHEN AVG(rating) BETWEEN 5 AND 7 THEN "Average Rated"
	WHEN AVG(rating) > 7 THEN "Highly Rated"
    ELSE "Poorly Rated"
END AS Rating_Result
FROM supermarket_sales
GROUP BY product_line;

-- What is the most common product line by gender?
SELECT gender, product_line, SUM(quantity) AS total_quantity
FROM supermarket_sales
GROUP BY gender, product_line
ORDER BY gender, total_quantity DESC;

-- How do different genders rate each product line?
SELECT gender, product_line, AVG(rating) AS avg_rating
FROM supermarket_sales
GROUP BY gender, product_line
ORDER BY gender, avg_rating DESC;

-- What is the average rating of each product line?
SELECT product_line, AVG(rating) AS avg_rating
FROM supermarket_sales
GROUP BY product_line
ORDER BY avg_rating;

-- What branch is most successful in selling high priced items?
SELECT branch, AVG(unit_price) AS avg_price
FROM supermarket_sales
GROUP BY branch
ORDER BY avg_price DESC;

-- What is the total revenue per product line by branch?
SELECT branch, product_line, SUM(total) as total_revenue
FROM supermarket_sales
GROUP BY branch, product_line
ORDER BY branch, total_revenue DESC; 

-- What product lines are most popular in each city
SELECT city, product_line, COUNT(*) AS purchase_count
FROM supermarket_sales
GROUP BY city, product_line
ORDER BY city, purchase_count DESC;

-- What is the average gross margin percentage for each branch?
SELECT branch, AVG(gross_margin_percentage) AS avg_gross_margin
FROM supermarket_sales
GROUP BY branch
ORDER BY avg_gross_margin DESC;

-- SALES ANALYSIS 
-- Number of sales every day of the week (at different times of day)
SELECT time_of_day, COUNT(*) AS total_sales
FROM supermarket_sales
WHERE day_name = "Sunday"
GROUP BY time_of_day
ORDER BY total_sales DESC;
-- Most sales are made in the Evening time for most days of the week 
-- (sometimes Afternoon some days)

-- Total sales per day?
SELECT day_name, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY day_name
ORDER BY total_revenue DESC; 

-- Which of the customer type brings in the most revenue?
SELECT customer_type, SUM(total) AS total_revenue
FROM supermarket_sales 
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Which customer type pays the most in tax?
SELECT customer_type, AVG(tax_percentage) 
FROM supermarket_sales 
GROUP BY customer_type
ORDER BY AVG(tax_percentage) DESC;

-- How does total revenue compare between weekdays and the weekend?
ALTER TABLE supermarket_sales
ADD COLUMN day_type VARCHAR(10);

SET SQL_SAFE_UPDATES = 0;
UPDATE supermarket_sales 
SET day_type = CASE
	WHEN day_name IN ("Saturday", "Sunday") THEN "Weekend"
	ELSE "Weekday"
END;
SET SQL_SAFE_UPDATES = 1;

SELECT day_type, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY day_type
ORDER BY total_revenue DESC;

-- Days where the total sales were above the average daily sales for each branch
SELECT branch, date,
SUM(total) AS total_revenue,
AVG(SUM(total)) OVER (PARTITION BY branch) AS avg_daily_sales,

CASE
	WHEN SUM(total) > AVG(SUM(total)) OVER (PARTITION BY branch) THEN 'Above Average'
	ELSE 'Below Average'
END AS sales_comparison

FROM supermarket_sales
GROUP BY branch, date
ORDER BY branch, date;

-- SEASONAL SALES TREND 
-- How do sales vary by season?
-- Create new season column 
SELECT season, SUM(total) AS total_revenue
FROM supermarket_sales
GROUP BY season
ORDER BY total_revenue DESC;

-- Which season has the highest average customer rating?
-- Create view for seasonal sales 
CREATE VIEW seasonal_sales_trends AS
SELECT season, SUM(total) AS total_sales, AVG(rating) AS avg_rating
FROM supermarket_sales
GROUP BY season
ORDER BY total_sales DESC;
SELECT * FROM seasonal_sales_trends; 
-- does not have any Summer or Fall data

-- Which branch has better seasonal sales?
SELECT season, SUM(total) AS total_sales, branch
FROM supermarket_sales
GROUP BY season, branch
ORDER BY total_sales DESC;
