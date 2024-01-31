/*
 * SET, JOIN & Join Path Problems
 * Markus Ehrenmueller-Jensen
 */

 /*
  * SET OPERATIONS
  */

SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography

-- UNION
SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
UNION 
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography

-- UNION ALL
SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
UNION ALL
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography

-- INTERSECT
SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
INTERSECT
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography

-- EXCEPT
SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
EXCEPT
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography


-- (INTERSECT) UNION (EXCEPT 1 & 2) UNION (EXCEPT 2 & 1)
(SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
INTERSECT
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography)
UNION
-- EXCEPT 1 & 2
(SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory
EXCEPT
SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography)
UNION
-- EXCEPT 2 & 1
(SELECT DISTINCT EnglishCountryRegionName FROM dbo.DimGeography
EXCEPT
SELECT SalesTerritoryRegion FROM dbo.DimSalesTerritory)


/*
 * JOINS
 */

-- JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- INNER JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
INNER JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- LEFT JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
LEFT JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- LEFT OUTER JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
LEFT OUTER JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- LEFT ANTI-JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
LEFT JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion
WHERE dg.EnglishCountryRegionName IS NULL

-- RIGHT JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
RIGHT JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- RIGHT OUTER JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
RIGHT OUTER JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- RIGHT ANTI-JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
RIGHT JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion
WHERE dst.SalesTerritoryRegion IS NULL

-- FULL JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
FULL JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- FULL OUTER JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
FULL OUTER JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion

-- FULL ANTI-JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
FULL JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName = dst.SalesTerritoryRegion
WHERE dst.SalesTerritoryRegion IS NULL


-- CROSS JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
CROSS JOIN dbo.DimGeography dg 

-- NON-EQUI JOIN
SELECT DISTINCT dst.SalesTerritoryRegion, dg.EnglishCountryRegionName
FROM dbo.DimSalesTerritory dst
JOIN dbo.DimGeography dg ON dg.EnglishCountryRegionName <> dst.SalesTerritoryRegion

-- SELF JOIN
SELECT employee.EmployeeKey, employee.ParentEmployeeKey, employee.FirstName, parent.EmployeeKey, parent.FirstName
FROM dbo.DimEmployee employee
JOIN dbo.DimEmployee parent on parent.EmployeeKey = employee.ParentEmployeeKey


 /*
  * JOIN PATH PROBLEMS
  */

-- Loops
-- Multiple paths between tables (directly or indirectly)
-- Possibly too few rows if both paths are used
-- Solution: duplicate referenced table

SELECT
	SUM(SalesAmount) SalesAmount
FROM
	dbo.FactResellerSales frs
JOIN dbo.DimDate dd ON dd.DateKey = frs.OrderDateKey AND dd.DateKey = frs.ShipDateKey

SELECT
	SUM(SalesAmount) SalesAmount
FROM
	dbo.FactResellerSales frs
JOIN dbo.DimDate od ON od.DateKey = frs.OrderDateKey
JOIN dbo.DimDate sd ON sd.DateKey = frs.ShipDateKey

-- Chasm trap
-- Converging many-to-one-to-many  joins (into "gap")
-- Possibly too many rows (and duplicated rows/values for columns of table(s) on "one" side)
SELECT
	dd.DateKey, SUM(frs.SalesAmount) SalesAmount
FROM
	dbo.FactResellerSales frs
JOIN dbo.DimDate dd ON dd.DateKey = frs.OrderDateKey
GROUP BY dd.DateKey
ORDER BY dd.DateKey
--20110101	1,538,408.3122

SELECT
	dd.DateKey, SUM(fis.SalesAmount) SalesAmount
FROM
	dbo.DimDate dd 
JOIN dbo.FactInternetSales fis ON fis.OrderDateKey = dd.DateKey
GROUP BY dd.DateKey
ORDER BY dd.DateKey
--20110101	7,156.54

SELECT
	dd.DateKey, SUM(frs.SalesAmount) ResellerSalesAmount, SUM(fis.SalesAmount) InternetSalesAmount
FROM
	dbo.FactResellerSales frs
JOIN dbo.DimDate dd ON dd.DateKey = frs.OrderDateKey
JOIN dbo.FactInternetSales fis ON fis.OrderDateKey = dd.DateKey
GROUP BY dd.DateKey
ORDER BY dd.DateKey
--20110101	3,076,816.6244	5,617,883.90

-- Fan trap
-- Series of one-to-many joins (“fan out”)
-- Possibly too many rows (and duplicated rows/values for columns of table(s) on “one” side)
SELECT
	soh.OrderDate, SUM(soh.Freight) Freight
FROM
	Sales.SalesOrderHeader soh
GROUP BY soh.OrderDate
ORDER BY soh.OrderDate
--2011-05-31 00:00:00.000	15051.1984

SELECT
	soh.OrderDate, SUM(soh.Freight) Freight, SUM(sod.OrderQty) OrderQty
FROM
	Sales.SalesOrderHeader soh
JOIN Sales.SalesOrderDetail sod ON sod.SalesOrderID = soh.SalesOrderID
GROUP BY soh.OrderDate
ORDER BY soh.OrderDate
--2011-05-31 00:00:00.000	215802.2969	825


/****************************/
--CREATE SCHEMA setjoin
/*
DROP TABLE IF EXISTS setjoin.blue 
CREATE TABLE setjoin.blue (
	id int,
	abc char(1)
)
INSERT INTO setjoin.blue VALUES(1, 'a');
INSERT INTO setjoin.blue VALUES(2, 'b');

DROP TABLE IF EXISTS setjoin.red
CREATE TABLE setjoin.red (
	id int,
	abc char(1),
	xyz char(1)
)
INSERT INTO setjoin.red VALUES(2, 'b', 'x');
INSERT INTO setjoin.red VALUES(3, 'c', 'y');
*/

SELECT 'BLUE'
SELECT 
	blue.id		as [blue.id],
	blue.abc	as [blue.abc]
FROM setjoin.blue;

SELECT 'RED'
SELECT
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM setjoin.red;

SELECT 'INNER JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
INNER JOIN setjoin.red ON red.id = blue.id;

SELECT 'LEFT OUTER JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
LEFT OUTER JOIN setjoin.red ON red.id = blue.id;

SELECT 'RIGHT OUTER JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
RIGHT OUTER JOIN setjoin.red ON red.id = blue.id;

SELECT 'FULL OUTER JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
FULL OUTER JOIN setjoin.red ON red.id = blue.id;

SELECT 'CROSS JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
CROSS JOIN setjoin.red 
order by 1;

SELECT 'LEFT ANTI JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
LEFT OUTER JOIN setjoin.red ON red.id = blue.id
WHERE red.id IS NULL;

SELECT 'RIGHT ANTI JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
RIGHT OUTER JOIN setjoin.red ON red.id = blue.id
WHERE blue.id IS NULL;

SELECT 'FULL ANTI JOIN'
SELECT
	blue.id		as [blue.id],
	blue.abc	as [blue.abc],
	red.id		as [red.id],
	red.xyz		as [red.xyz]
FROM
	setjoin.blue
FULL OUTER JOIN setjoin.red ON red.id = blue.id
WHERE blue.id IS NULL OR red.id IS NULL;


---
SELECT 'UNION ALL'
SELECT blue.id, blue.abc FROM setjoin.blue
UNION ALL
SELECT red.id, red.abc FROM setjoin.red

SELECT 'UNION'
SELECT blue.id, blue.abc FROM setjoin.blue
UNION 
SELECT red.id, red.abc FROM setjoin.red

SELECT 'INTERSECT'
SELECT blue.id, blue.abc FROM setjoin.blue
INTERSECT
SELECT red.id, red.abc FROM setjoin.red

SELECT 'EXCEPT'
SELECT blue.id, blue.abc FROM setjoin.blue
EXCEPT
SELECT red.id, red.abc FROM setjoin.red

SELECT '(INTERSECT) UNION (EXCEPT 1 & 2) UNION (EXCEPT 2 & 1)'
-- INTERSECT 1 & 2
(SELECT blue.id, blue.abc FROM setjoin.blue
INTERSECT
SELECT red.id, red.abc FROM setjoin.red)
UNION
-- EXCEPT 1 & 2
(SELECT blue.id, blue.abc FROM setjoin.blue
EXCEPT
SELECT red.id, red.abc FROM setjoin.red)
UNION
-- EXCEPT 2 & 1
(SELECT red.id, red.abc FROM setjoin.red
EXCEPT
SELECT blue.id, blue.abc FROM setjoin.blue)
