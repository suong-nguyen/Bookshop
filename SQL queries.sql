/* PROJECT WALKTHOUGH

1. What books are the most popular? The least popular? Is that based on sales, reviews, checkouts, or another metric?
2. Who was the youngest debut author? Who was the oldest?
3. Do some publishing houses seem to specialize in any way?
4. What was the longest time between editions of the same book?
5. Are there any seasonal trends for sales? What about checkouts? Do any titles or genres have seasonal fluctuations?
6. Are there any correlations between checkouts, print run size, book review ratings, and sales volume?
7. Do the authors who spend the most time writing have the most successful books? Do they have the highest page count?
8. When are most books published? Are there any anomalies?
9. Are there any trends for genre, format, and price?
10. What sort of distributions do the ratings have? Do those distributions vary by book? By genre? Do they seem to align .  awards?
11. How would you calculate the sales price, given that there is sometimes—but not always—a discount given at the time of sale?
12. Do sales approximate the Pareto principle?
13. Are there any patterns in the discounts?
14. Do any tables in particular appear to have dirty data?



*/



Create database Bookshop
Use Bookshop

-- Duplicate Sales_Q1 structure into a new table called Sales
SELECT *
INTO Sales
FROM [Sales Q1]
WHERE 1 = 0; -- This condition ensures that no data is copied, only the structure

-- Truncate the newly created Sales table to remove any existing data
TRUNCATE TABLE Sales;

-- Rename Sales_Q1 to a temporary name
EXEC sp_rename 'Sales_Temp', 'Sales_Q1';

-- Rename the newly created Sales table to Sales
EXEC sp_rename 'Sales', 'Sales_Q1';

Select * from SalesQ1


-- Insert data from Sales Q1
INSERT INTO Sales(SaleDate, ISBN, Discount, ItemID, OrderID)
SELECT [Sale Date], ISBN, Discount, ItemID, OrderID FROM [dbo].[SalesQ1];

-- Insert data from Sales Q2
INSERT INTO Sales (SaleDate, ISBN, Discount, ItemID, OrderID)
SELECT [Sale Date], ISBN, Discount, ItemID, OrderID FROM[dbo].[Sales Q2] ;

-- Insert data from Sales Q3
INSERT INTO Sales (SaleDate, ISBN, Discount, ItemID, OrderID)
SELECT [Sale Date], ISBN, Discount, ItemID, OrderID FROM[dbo].[Sales Q3] ;

-- Insert data from Sales Q4
INSERT INTO Sales (SaleDate, ISBN, Discount, ItemID, OrderID)
SELECT [Sale Date], ISBN, Discount, ItemID, OrderID FROM[dbo].[Sales Q3] ;


-- 1. Who is the youngest author? Who is the oldest?
SELECT 
  authid,
  CONCAT([First Name], '|', [Last Name]) AS full_name,
  birthday
FROM Author
WHERE birthday = (SELECT MAX(birthday) FROM Author); -- youngest


SELECT 
  authid,
  CONCAT([First Name], '|', [Last Name]) AS full_name,
  birthday
FROM Author
WHERE birthday = (SELECT MIN(birthday) FROM Author); -- oldest





-- 2. What is the youngest age at which an author has a book published? 
SELECT
  b.bookid,
  b.title,
  a.authid,
  a.[First Name] + ' ' + a.[Last Name] AS full_name,
  a.birthday,
  e.[Publication Date],
  DATEDIFF(day, a.birthday, e.[Publication Date]) / 365 AS published_age
FROM Book b 
INNER JOIN edition e 
ON b.bookid = e.bookid 
INNER JOIN Author a 
ON b.authid = a.authid
WHERE e.[Publication Date] IS NOT NULL
ORDER BY published_age ASC, a.authid;

 
-- 3. In which year are most books published? 
SELECT
  YEAR(e.[Publication Date]) AS year_published,
  COUNT(DISTINCT e.bookid) AS total_books
FROM edition e
GROUP BY YEAR(e.[Publication Date])
ORDER BY total_books DESC;


-- 4. Who are the top ten authors that write the longest hours per day and have had their book(s) published before? 
-- How many pages did each of them write in total?
SELECT TOP 10
  a.authid,
  a.[First Name] + ' ' + a.[Last Name] AS full_name,
  a.[Hrs Writing per Day] AS writing_hours,
  b.title,
  b.bookid,
  SUM(e.pages) AS total_pages
FROM Author a
LEFT JOIN Book b ON a.authid = b.authid 
INNER JOIN edition e ON b.bookid = e.bookid 
GROUP BY a.authid, a.[First Name], a.[Last Name], a.[Hrs Writing per Day], b.title, b.bookid
ORDER BY writing_hours DESC;



-- 5.How would you calculate the sales price and add them in the sales tables, given that there is sometimes—but not always—a discount given at the time of sale?
-- sales = price * (1-discount) 
ALTER TABLE Sales
ADD DiscountPrice DECIMAL(10, 2)


UPDATE Sales
SET DiscountPrice = CASE
                        WHEN s.Discount IS NULL THEN e.Price
                        ELSE e.Price * (1 - s.Discount)
                    END
FROM Sales s
JOIN Edition e ON s.ISBN = e.ISBN;


Select * from Sales 

-- 6. What books are the most popular?
-- by number of checkouts?
SELECT c.BookID, b.Title, SUM(c.[Number of Checkouts]) AS TotalCheckouts
FROM Checkouts c
JOIN Book b ON c.BookID = b.BookID
GROUP BY c.BookID, b.Title
ORDER BY TotalCheckouts DESC;


--by ratings?
SELECT r.BookID, b.Title, AVG(r.Rating) AS AverageRating
FROM Ratings r
JOIN Book b ON r.BookID = b.BookID
GROUP BY r.BookID, b.Title
ORDER BY AverageRating DESC;



--by sales quantity?

SELECT s.ISBN, b.Title, count([OrderID]) AS TotalSalesQuantity
FROM Sales s
JOIN Edition e ON s.ISBN = e.ISBN
JOIN Book b ON e.BookID = b.BookID
GROUP BY s.ISBN, b.Title
ORDER BY TotalSalesQuantity DESC;



-- by sales amount ($)?
SELECT e.ISBN, b.Title, SUM(DiscountPrice) AS TotalSalesAmount
FROM Sale s
JOIN Edition e ON s.ISBN = e.ISBN
JOIN Book b ON e.BookID = b.BookID
GROUP BY e.ISBN, b.Title
ORDER BY TotalSalesAmount DESC;




-- 7. What's the return on investment for each Publishing House?  

SELECT 
    p.[Publishing House],
    SUM(s.TotalSalesAmount) AS TotalSales,
    p.[Marketing Spend],
    (SUM(s.TotalSalesAmount)-p.[Marketing Spend])/ p.[Marketing Spend] AS ROI
FROM (
    SELECT 
        e.PubID,
       SUM(s.DiscountPrice) AS TotalSalesAmount
    FROM Sales s
    JOIN Edition e ON s.ISBN = e.ISBN
    GROUP BY e.PubID
) AS s
JOIN Publisher p ON s.PubID = p.PubID
GROUP BY p.[Publishing House],p.[Marketing Spend], p.[Marketing Spend]


