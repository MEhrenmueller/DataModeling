/* 
 * HIERARCHIES
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA hierarchy

-- Natural Hierarchy
CREATE OR ALTER VIEW hierarchy.vw_ProductHierarchy AS
SELECT
	dp.ProductKey,
	dp.EnglishProductName Product,
	ISNULL(dps.EnglishProductSubcategoryName, 'unknown') Subcategory,
	ISNULL(dpc.EnglishProductCategoryName, 'unknown') Category
FROM dbo.DimProduct dp
LEFT JOIN dbo.DimProductSubcategory dps ON dps.ProductSubcategoryKey = dp.ProductSubcategoryKey
LEFT JOIN dbo.DimProductCategory dpc ON dpc.ProductCategoryKey = dps.ProductCategoryKey
GO
SELECT * FROM hierarchy.vw_ProductHierarchy
GO

-- Parent-Child Hierarchy
CREATE OR ALTER VIEW hierarchy.vw_EmployeeHierarchy AS
WITH PCCTE AS (
SELECT 
	EmployeeKey, ParentEmployeeKey, 
	convert(varchar(max), FirstName + ' ' + LastName) as FullName, 
	1 as Lvl, 
	convert(varchar(max), FirstName + ' ' + LastName) as [Path],
	CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM dbo.DimEmployee sde WHERE sde.ParentEmployeeKey = DimEmployee.EmployeeKey) THEN 0 ELSE 1 END) IsLeaf
FROM dbo.DimEmployee
WHERE ParentEmployeeKey IS NULL
UNION ALL
SELECT 
	child.EmployeeKey, child.ParentEmployeeKey, 
	convert(varchar(max), FirstName + ' ' + LastName) as FullName, 
	parent.Lvl + 1 as Lvl, 
	convert(varchar(max), parent.[Path] + '|' + child.FirstName + ' ' + child.LastName) as [Path],
	CONVERT(bit, CASE WHEN EXISTS (SELECT 1 FROM dbo.DimEmployee sde WHERE sde.ParentEmployeeKey = child.EmployeeKey) THEN 0 ELSE 1 END) IsLeaf
FROM dbo.DimEmployee child
JOIN PCCTE parent ON parent.EmployeeKey= child.ParentEmployeeKey
)
SELECT * 
--from pccte
FROM (
	SELECT c.*, [split].[Value], 'Level ' +  convert(varchar, ROW_NUMBER() OVER(PARTITION BY EmployeeKey ORDER BY [Lvl] DESC)) AS [ColumnName]
	FROM   PCCTE AS c
	CROSS APPLY STRING_SPLIT([Path], '|') AS split
	) AS t 
PIVOT( 
	MAX([Value]) 
	FOR ColumnName 
	IN([Level 1], [Level 2], [Level 3], [Level 4], [Level 5], [Level 6], [Level 7]) 
	) p
GO
SELECT * FROM hierarchy.vw_EmployeeHierarchy