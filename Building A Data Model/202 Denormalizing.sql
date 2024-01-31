/* 
 * NORMALIZATION
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA denormalization

-- Normalized Tables
select * from dbo.DimProduct;
select * from dbo.DimProductSubcategory;
select * from dbo.DimProductCategory;

/* TABLES */
DROP TABLE IF EXISTS denormalization.Product
CREATE TABLE denormalization.Product (
	ProductID int IDENTITY(1,1) PRIMARY KEY,
	Product nvarchar(50),
	Subcategory nvarchar(50),
	Category nvarchar(50)
)

INSERT INTO denormalization.Product
SELECT
	dp.EnglishProductName Product,
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') Subcategory,
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') Category
FROM
	dbo.DimProduct dp 
LEFT JOIN dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey=dp.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory dpc ON dpc.ProductCategoryKey=dps.ProductCategoryKey

select * from denormalization.Product;
GO

/* VIEW */
CREATE OR ALTER VIEW denormalization.vw_Product AS (
SELECT
	dp.EnglishProductName Product,
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') Subcategory,
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') Category
FROM
	dbo.DimProduct dp 
LEFT JOIN dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey=dp.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory dpc ON dpc.ProductCategoryKey=dps.ProductCategoryKey
)
GO

/* FUNCTION */
CREATE OR ALTER FUNCTION denormalization.fn_Product (
	@Product nvarchar(50),
	@Subcategory nvarchar(50),
	@Category nvarchar(50)
)
RETURNS TABLE 
AS 
RETURN
SELECT
	dp.EnglishProductName Product,
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') Subcategory,
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') Category
FROM
	dbo.DimProduct dp 
LEFT JOIN dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey=dp.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory dpc ON dpc.ProductCategoryKey=dps.ProductCategoryKey
WHERE 
	dp.EnglishProductName like ISNULL(@Product, '%') AND
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') like ISNULL(@Subcategory, '%') AND
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') like ISNULL(@Category, '%')
GO


/* STORED PROCEDURE */
CREATE OR ALTER PROCEDURE denormalization.usp_Product (
	@Product nvarchar(50) = '%',
	@Subcategory nvarchar(50) = '%',
	@Category nvarchar(50) = '%'
)
AS (
SELECT
	dp.EnglishProductName Product,
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') Subcategory,
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') Category
FROM
	dbo.DimProduct dp 
LEFT JOIN dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey=dp.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory dpc ON dpc.ProductCategoryKey=dps.ProductCategoryKey
WHERE 
	dp.EnglishProductName like ISNULL(@Product, '%') AND
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') like ISNULL(@Subcategory, '%') AND
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') like ISNULL(@Category, '%')
)
GO
