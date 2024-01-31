/*
 * ETL
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA etl

-- Full Load
-- Sales
TRUNCATE TABLE demo.Sales;
INSERT INTO demo.Sales (ProductID, SalesAmount)
SELECT 
	ISNULL(p.ID, -1) ProductID,
	ps.SalesAmount
FROM 
	demo.ProductSales ps
LEFT JOIN demo.Product p ON p.Product=ps.Product;


-- Delta Load
INSERT INTO demo.Sales (ProductID, SalesAmount)
SELECT 
	ISNULL(p.ID, -1) ProductID,
	ps.SalesAmount
FROM 
	demo.ProductSales ps
LEFT JOIN demo.Product p ON p.Product=ps.Product
WHERE NOT EXISTS (SELECT TOP 1 1 FROM demo.Sales ss WHERE ss.ProductID = ISNULL(p.ID, -1))
;

SELECT 
	DISTINCT 
	p.ID ProductID,
	SalesAmount
FROM 
	demo.ProductSales ps
LEFT JOIN demo.Product p ON p.Product=ps.Product /* dbo.Product loaded in Script Normalizing */
WHERE NOT EXISTS (SELECT TOP 1 1 FROM demo.Sales ss WHERE ss.ProductID = p.ID);


-- Avoid NULL in foreign keys
GO
CREATE OR ALTER VIEW etl.vw_ProductSubcategory AS
(
	SELECT ProductSubcategoryKey, EnglishProductSubcategoryName
	FROM dbo.DimProductSubcategory
	UNION ALL
	SELECT -1 ProductSubcategoryKey, 'N/A' EnglishProductSubcategoryName
)
GO
CREATE OR ALTER VIEW etl.vw_Product AS
(
	SELECT ISNULL(ProductKey, -1) ProductKey, ISNULL(ProductSubcategoryKey, -1) ProductSubcategoryKey, EnglishProductName
	FROM dbo.DimProduct
	UNION ALL
	SELECT -1 ProductKey, -1 ProductSubcategoryKey, 'N/A' EnglishProductSubcategoryName
)
GO
SELECT * 
FROM etl.vw_Product p
JOIN etl.vw_ProductSubcategory ps ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
-- 607 rows

-- vs null values
SELECT *
FROM dbo.DimProduct p
JOIN dbo.DimProductSubcategory ps ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
-- 397 rows
SELECT *
FROM dbo.DimProduct p
LEFT JOIN dbo.DimProductSubcategory ps ON ps.ProductSubcategoryKey = p.ProductSubcategoryKey
-- 606 rows

-- Safe data type conversion
SELECT
	EnglishProductName,
	Size,
	--CONVERT(int, Size) SizeInt
	TRY_CONVERT(int, Size) SizeInt
FROM
	dbo.DimProduct
ORDER BY Size DESC