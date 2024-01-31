/* 
 * FLAGS AND INDICATORS
 * Markus Ehrenmueller-Jensen
 */

--select * from dbo.DimProduct;
--CREATE SCHEMA flag

--FinishedGoodsFlag: 0 = Product is not a salable item. 1 = Product is salable.
CREATE OR ALTER VIEW flag.Finishedgoods AS (
SELECT
	FinishedGoodsFlag as _FinishedGoodsFlag,
	CASE 
	WHEN FinishedGoodsFlag=0 THEN 'not salable'
	WHEN FinishedGoodsFlag=1 THEN 'salable'
	ELSE						  'unknown'
	END [Finished Goods Flag]
	,*
FROM dbo.DimProduct
);
GO

-- ProductLine: R = Road, M = Mountain, T = Touring, S = Standard
CREATE OR ALTER VIEW flag.ProductLine AS (
SELECT
	ProductLine as _ProductLine,
	CASE ProductLine
	WHEN 'R' THEN 'Road'
	WHEN 'M' THEN 'Mountain'
	WHEN 'T' THEN 'Touring'
	WHEN 'S' THEN 'Standard'
	ELSE		  'other'
	END [Product Line]
	,*
FROM dbo.DimProduct
);
GO

-- Class: H = High, M = Medium, L = Low
CREATE OR ALTER VIEW flag.Class AS 
WITH Class AS (
SELECT 'H' Class, 'High'	ClassDescription UNION ALL
SELECT 'M' Class, 'Medium'	ClassDescription UNION ALL
SELECT 'L' Class, 'Low'		ClassDescription 
)
SELECT
	dp.Class as _Class,
	c.ClassDescription as [Class Description]
	,dp.*
FROM dbo.DimProduct dp
JOIN Class c ON c.Class=dp.Class
;
GO

-- Style: W = Womens, M = Mens, U = Universal
DROP TABLE IF EXISTS flag.Styles;
CREATE TABLE flag.Styles (
	Style char(1),
	StyleDescription nvarchar(50)
	)
INSERT INTO flag.Styles
SELECT 'W' Class, 'Womens'		StyleDescription UNION ALL
SELECT 'M' Class, 'Mens'		StyleDescription UNION ALL
SELECT 'U' Class, 'Universal'	StyleDescription 
GO
CREATE OR ALTER VIEW flag.Style AS (
SELECT
	s.Style as _Style,
	ISNULL(s.StyleDescription, 'Unkown') as [Style Description]
	,dp.*
FROM dbo.DimProduct dp
LEFT JOIN flag.Styles s ON s.Style=dp.Style
);
GO
-- Replace NULL
CREATE OR ALTER VIEW flag.[Null] AS (
SELECT 
	EnglishProductName, 
	WeightUnitMeasureCode as WeightUnitMeasureCode,
	ISNULL(WeightUnitMeasureCode, 'N/A') [Weight Unit Measure Code]
FROM dbo.DimProduct dp
)

