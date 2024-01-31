/* 
 * NORMALIZATION
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA normalization
--CREATE SCHEMA normalization_filter

/* Non-normalized table (0NF) */
SELECT * FROM demo.financials;

/* TABLES */
/*
-- Category
DROP TABLE IF EXISTS normalization.Category;
CREATE TABLE normalization.Category (
	ID int IDENTITY(1,1),
	Category nvarchar(50)
)
INSERT INTO normalization.Category (Category)
SELECT 
	DISTINCT 
	Category 
FROM 
	demo.ProductSales;

-- Subcategory
DROP TABLE IF EXISTS normalization.Subcategory;
CREATE TABLE normalization.Subcategory (
	ID int IDENTITY(1,1),
	CategoryID INT,
	Subcategory nvarchar(50)
)
INSERT INTO normalization.Subcategory (CategoryID, Subcategory)
SELECT 
	DISTINCT 
	c.ID CategoryID,
	Subcategory
FROM 
	demo.ProductSales ps
LEFT JOIN normalization.Category c ON c.Category=ps.Category;

-- Product
DROP TABLE IF EXISTS normalization.Product;
CREATE TABLE normalization.Product (
	ID int IDENTITY(1,1),
	SubcategoryID INT,
	Product nvarchar(50)
)
INSERT INTO normalization.Product (SubcategoryID, Product)
SELECT 
	DISTINCT 
	s.ID SubcategoryID,
	Product
FROM 
	demo.ProductSales ps
LEFT JOIN normalization.Subcategory s ON s.Subcategory=ps.Subcategory;
*/

/* Finding dimension candidates */
SELECT * FROM demo.financials;
SELECT COUNT(*) CountAll, COUNT(DISTINCT Segment) CountSegment FROM demo.financials;
SELECT Segment, COUNT(*) FROM demo.financials GROUP BY Segment ORDER BY 2 DESC;

SELECT COUNT(*) CountAll, COUNT(DISTINCT Product) CountProduct, COUNT(DISTINCT [Manufacturing Price]) CountManufactoringPrice FROM demo.financials;

SELECT COUNT(*) CountAll, MIN([Date]) MinDate, MAX([Date]) MaxDate, COUNT(DISTINCT [Date]) CountDay  FROM demo.financials;

-- Segment
IF EXISTS (SELECT TOP 1 1 FROM sys.objects where OBJECT_NAME(object_id) = 'FK_Financials_Segment') 
ALTER TABLE normalization.financials
DROP CONSTRAINT FK_Financials_Segment;
DROP TABLE IF EXISTS normalization.Segment;
CREATE TABLE normalization.Segment (
	SegmentID int IDENTITY(1,1) PRIMARY KEY,
	Segment nvarchar(50)
)
GO
INSERT INTO normalization.Segment
SELECT
	DISTINCT
	Segment
FROM
	demo.financials;
SET IDENTITY_INSERT normalization.Segment ON;
INSERT INTO normalization.Segment (SegmentID, Segment) VALUES (-1, 'unknown');
SET IDENTITY_INSERT normalization.Segment OFF;

-- Country
IF EXISTS (SELECT TOP 1 1 FROM sys.objects where OBJECT_NAME(object_id) = 'FK_Financials_Country') 
ALTER TABLE normalization.financials
DROP CONSTRAINT FK_Financials_Country;
DROP TABLE IF EXISTS normalization.Country;
CREATE TABLE normalization.Country (
	CountryID int IDENTITY(1,1) PRIMARY KEY,
	Country nvarchar(50)
)
GO
INSERT INTO normalization.Country
SELECT
	DISTINCT
	Country
FROM
	demo.financials;
SET IDENTITY_INSERT normalization.Country ON;
INSERT INTO normalization.Country (CountryID, Country) VALUES (-1, 'unknown');
SET IDENTITY_INSERT normalization.Country OFF;

-- Product
IF EXISTS (SELECT TOP 1 1 FROM sys.objects where OBJECT_NAME(object_id) = 'FK_Financials_Product') 
ALTER TABLE normalization.financials
DROP CONSTRAINT FK_Financials_Product;
DROP TABLE IF EXISTS normalization.Product;
CREATE TABLE normalization.Product (
	ProductID int IDENTITY(1,1) PRIMARY KEY,
	Product nvarchar(50),
	[Manufacturing Price] decimal(18,2)
)
GO
INSERT INTO normalization.Product
SELECT
	DISTINCT
	Product,
	[Manufacturing Price]
FROM
	demo.financials;
SET IDENTITY_INSERT normalization.Product ON;
INSERT INTO normalization.Product (ProductID, Product, [Manufacturing Price]) VALUES (-1, 'unknown', null);
SET IDENTITY_INSERT normalization.Product OFF;

-- [Discount Band]
IF EXISTS (SELECT TOP 1 1 FROM sys.objects where OBJECT_NAME(object_id) = 'FK_Financials_DiscountBand') 
ALTER TABLE normalization.financials
DROP CONSTRAINT FK_Financials_DiscountBand;
DROP TABLE IF EXISTS normalization.[Discount Band];
CREATE TABLE normalization.[Discount Band] (
	DiscountBandID int IDENTITY(1,1) PRIMARY KEY,
	[Discount Band] nvarchar(50)
)
GO
INSERT INTO normalization.[Discount Band]
SELECT
	DISTINCT
	[Discount Band]
FROM
	demo.financials;
SET IDENTITY_INSERT normalization.[Discount Band] ON;
INSERT INTO normalization.[Discount Band] (DiscountBandID, [Discount Band]) VALUES (-1, 'unknown');
SET IDENTITY_INSERT normalization.[Discount Band] OFF;

-- Financials
DROP TABLE IF EXISTS normalization.Financials;
CREATE TABLE normalization.Financials (
	SegmentID int NOT NULL 
		CONSTRAINT FK_Financials_Segment 
		REFERENCES normalization.Segment(SegmentID),
	CountryID int NOT NULL 
		CONSTRAINT FK_Financials_Country 
		REFERENCES normalization.Country(CountryID),
	ProductID int NOT NULL 
		CONSTRAINT FK_Financials_Product 
		REFERENCES normalization.Product(ProductID),
	DiscountBandID int NOT NULL 
		CONSTRAINT FK_Financials_DiscountBand 
		REFERENCES normalization.[Discount Band](DiscountBandID),
	DateKey int,
	[Units Sold] decimal(18,2),
	[Sales Price] decimal(18,2),
	[Gross Sales] decimal(18,2),
	[Discounts] decimal(18,2),
	[Sales] decimal(18,2),
	[COGS] decimal(18,2),
	[Profit] decimal(18,2)
)
GO
INSERT INTO normalization.Financials
SELECT 
	ISNULL(s.SegmentID, -1)	as SegmentID,
	ISNULL(c.CountryID, -1)	as CountryID,
	ISNULL(p.ProductID, -1)	as ProductID,
	ISNULL(d.DiscountBandID, -1)	as DiscountBandID,
	YEAR(f.[Date]) * 10000 + MONTH(f.[Date]) * 100 + DAY(f.[Date])	as DateKey,
	f.[Units Sold],
	f.[Sale Price],
	f.[Gross Sales],
	f.[Discounts],
	f.[Sales],
	f.[COGS],
	f.[Profit]
FROM 
	demo.financials f
LEFT JOIN normalization.Segment s ON s.Segment = f.Segment
LEFT JOIN normalization.Country c ON c.Country = f.Country
LEFT JOIN normalization.Product p ON p.Product= f.Product
LEFT JOIN normalization.[Discount Band] d ON d.[Discount Band]= f.[Discount Band]
GO
SELECT * FROM normalization.Financials;
GO

/* VIEW */
CREATE OR ALTER VIEW normalization.vw_Financials AS (
SELECT 
	ISNULL(s.SegmentID, -1)	as SegmentID,
	ISNULL(c.CountryID, -1)	as CountryID,
	ISNULL(p.ProductID, -1)	as ProductID,
	ISNULL(d.DiscountBandID, -1)	as DiscountBandID,
	YEAR(f.[Date]) * 10000 + MONTH(f.[Date]) * 100 + DAY(f.[Date])	as DateKey,
	f.[Units Sold],
	f.[Sale Price],
	f.[Gross Sales],
	f.[Discounts],
	f.[Sales],
	f.[COGS],
	f.[Profit]
FROM 
	demo.financials f
LEFT JOIN normalization.Segment s ON s.Segment = f.Segment
LEFT JOIN normalization.Country c ON c.Country = f.Country
LEFT JOIN normalization.Product p ON p.Product= f.Product
LEFT JOIN normalization.[Discount Band] d ON d.[Discount Band]= f.[Discount Band]
)
GO
SELECT * FROM normalization.vw_Financials;
GO

/* FUNCTION */
CREATE OR ALTER FUNCTION normalization.fn_Financials (
	@Date date
)
RETURNS TABLE 
AS 
RETURN
SELECT 
	ISNULL(s.SegmentID, -1)	as SegmentID,
	ISNULL(c.CountryID, -1)	as CountryID,
	ISNULL(p.ProductID, -1)	as ProductID,
	ISNULL(d.DiscountBandID, -1)	as DiscountBandID,
	YEAR(f.[Date]) * 10000 + MONTH(f.[Date]) * 100 + DAY(f.[Date])	as DateKey,
	f.[Units Sold],
	f.[Sale Price],
	f.[Gross Sales],
	f.[Discounts],
	f.[Sales],
	f.[COGS],
	f.[Profit]
FROM 
	demo.financials f
LEFT JOIN normalization.Segment s ON s.Segment = f.Segment
LEFT JOIN normalization.Country c ON c.Country = f.Country
LEFT JOIN normalization.Product p ON p.Product= f.Product
LEFT JOIN normalization.[Discount Band] d ON d.[Discount Band]= f.[Discount Band]
WHERE [Date] = ISNULL(@Date, [Date]);
GO
SELECT * FROM normalization.fn_Financials ({d'2014-01-01'});
SELECT * FROM normalization.fn_Financials (null);
GO

/* STORED PROCEDURE */
CREATE OR ALTER PROCEDURE normalization.usp_Financials (
	@Date date = null
)
AS 
SELECT 
	ISNULL(s.SegmentID, -1)	as SegmentID,
	ISNULL(c.CountryID, -1)	as CountryID,
	ISNULL(p.ProductID, -1)	as ProductID,
	ISNULL(d.DiscountBandID, -1)	as DiscountBandID,
	YEAR(f.[Date]) * 10000 + MONTH(f.[Date]) * 100 + DAY(f.[Date])	as DateKey,
	f.[Units Sold],
	f.[Sale Price],
	f.[Gross Sales],
	f.[Discounts],
	f.[Sales],
	f.[COGS],
	f.[Profit]
FROM 
	demo.financials f
LEFT JOIN normalization.Segment s ON s.Segment = f.Segment
LEFT JOIN normalization.Country c ON c.Country = f.Country
LEFT JOIN normalization.Product p ON p.Product= f.Product
LEFT JOIN normalization.[Discount Band] d ON d.[Discount Band]= f.[Discount Band]
WHERE [Date] = ISNULL(@Date, [Date]);
GO
EXEC normalization.usp_Financials {d'2014-01-01'};
EXEC normalization.usp_Financials null;
EXEC normalization.usp_Financials;
GO

--FILTER DIMENSION
DROP TABLE IF EXISTS normalization_filter.[Financials];
DROP TABLE IF EXISTS normalization_filter.[Filter];
CREATE TABLE normalization_filter.[Filter] 
(
	_FilterKey [int] IDENTITY(1, 1) PRIMARY KEY,
	[Segment] [nvarchar](50) NULL,
	[Country] [nvarchar](50) NULL,
	[Product] [nvarchar](50) NULL,
	[Discount Band] [nvarchar](50) NULL,
	[Manufacturing Price] [decimal](18, 2) NULL
) ON [PRIMARY];
INSERT INTO normalization_filter.[Filter]
SELECT
	DISTINCT
	[Segment],
	[Country],
	[Product],
	[Discount Band],
	[Manufacturing Price]
FROM
	demo.financials;

CREATE TABLE normalization_filter.[Financials] 
(
	[_FilterKey] [int] NULL REFERENCES normalization_filter.[Filter](_FilterKey),
	[Units Sold] [decimal](18, 2) NULL,
	[Sale Price] [decimal](18, 2) NULL,
	[Gross Sales] [decimal](18, 2) NULL,
	[Discounts] [decimal](18, 2) NULL,
	[Sales] [decimal](18, 2) NULL,
	[COGS] [decimal](18, 2) NULL,
	[Profit] [decimal](18, 2) NULL,
	[Date] [date] NULL
) ON [PRIMARY];
INSERT INTO normalization_filter.[Financials]
SELECT 
	d._FilterKey
	,f.[Units Sold]
	,f.[Sale Price]
	,f.[Gross Sales]
	,f.[Discounts]
	,f.[Sales]
	,f.[COGS]
	,f.[Profit]
	,f.[Date]
FROM 
	[demo].[financials] f
LEFT JOIN 
	normalization_filter.[Filter] d ON
		d.[Segment] = f.[Segment] AND
		d.[Country] = f.[Country] AND
		d.[Product] = f.[Product] AND
		d.[Discount Band] = f.[Discount Band] AND
		d.[Manufacturing Price]  = f.[Manufacturing Price] 


CREATE OR ALTER VIEW normalization_filter.[vw_Filter] AS
SELECT
	 [Segment] + '|'
	+[Country] + '|'
	+[Product] + '|'
	+[Discount Band]
	as _FilterKey
	,[Segment]
	,[Country]
	,[Product]
	,[Discount Band]
FROM 
	[demo].[financials]

CREATE OR ALTER VIEW normalization_filter.[vw_Financials] AS
SELECT
	 [Segment] + '|'
	+[Country] + '|'
	+[Product] + '|'
	+[Discount Band]
	as _FilterKey
	,[Manufacturing Price]
	,[Sale Price]
	,[Gross Sales]
	,[Discounts]
	,[Sales]
	,[COGS]
	,[Profit]
	,[Date]
FROM 
	[demo].[financials]




/* VIEWS */
/*
CREATE OR ALTER VIEW normalization.vw_Category AS (
SELECT 
	DISTINCT 
	Category 
FROM 
	demo.ProductSales
);
GO

-- Subcategory
CREATE OR ALTER VIEW normalization.vw_Subcategory AS (
SELECT 
	DISTINCT 
	Category,
	Subcategory
FROM 
	demo.ProductSales ps
)
GO

-- Product
CREATE OR ALTER VIEW normalization.vw_Product AS (
SELECT 
	DISTINCT 
	Subcategory,
	Product
FROM 
	demo.ProductSales ps
)
GO
*/

---- Sales
--CREATE OR ALTER VIEW normalization.vw_Sales AS (
--SELECT 
--	p.ID ProductID,
--	ps.SalesAmount
--FROM 
--	demo.ProductSales ps
--LEFT JOIN PowerBI.Product p ON p.Product=ps.Product
--)
--GO

/* STORED PROCEDURES */
/*
CREATE OR ALTER PROCEDURE normalization.usp_Category AS (
SELECT 
	DISTINCT 
	Category 
FROM 
	demo.ProductSales
);
GO

-- Subcategory
CREATE OR ALTER PROCEDURE normalization.usp_Subcategory AS (
SELECT 
	DISTINCT 
	Category,
	Subcategory
FROM 
	demo.ProductSales ps
)
GO

-- Product
CREATE OR ALTER PROCEDURE normalization.usp_Product AS (
SELECT 
	DISTINCT 
	Subcategory,
	Product
FROM 
	demo.ProductSales ps
)
GO
*/

---- Sales
--CREATE OR ALTER FUNCTION normalization.fn_Sales ()
--RETURNS TABLE
--RETURN
--SELECT 
--	p.ID ProductID,
--	ps.SalesAmount
--FROM 
--	demo.ProductSales ps
--LEFT JOIN PowerBI.Product p ON p.Product=ps.Product
--GO

---- Sales
--CREATE OR ALTER PROCEDURE normalization.usp_Sales AS (
--SELECT 
--	p.ID ProductID,
--	ps.SalesAmount
--FROM 
--	demo.ProductSales ps
--LEFT JOIN PowerBI.Product p ON p.Product=ps.Product
--)
--GO
