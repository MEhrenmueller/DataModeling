/* 
 * BUDGET
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA budget;

-- Product
CREATE OR ALTER VIEW budget.Product AS
SELECT 100 ID, 'A' Product, 'Group 1' ProductGroup UNION ALL
SELECT 110 ID, 'B' Product, 'Group 1' ProductGroup UNION ALL
SELECT 120 ID, 'C' Product, 'Group 2' ProductGroup UNION ALL
SELECT 130 ID, 'D' Product, 'Group 2' ProductGroup 
GO

-- Sales
CREATE OR ALTER VIEW budget.Sales AS
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 01  ) AS Date, 100 Product,  3000 Amount UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 01  ) AS Date, 110 Product, 20000 Amount UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 01+1) AS Date, 110 Product, 10000 Amount UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()), 01+2) AS Date, 120 Product, 15000 Amount 
GO

-- Budget
CREATE OR ALTER VIEW budget.Budget AS
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()),   01) AS Date, 'Group 2' ProductGroup, 20000 Budget UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME()),   01) AS Date, 'Group 3' ProductGroup,  7000 Budget UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME())+1, 01) AS Date, 'Group 2' ProductGroup, 25000 Budget UNION ALL
SELECT DATEFROMPARTS(YEAR(SYSDATETIME()), MONTH(SYSDATETIME())+1, 01) AS Date, 'Group 3' ProductGroup,  8000 Budget 
GO

-- BRIDGE
CREATE OR ALTER VIEW budget.ProductGroup AS
SELECT DISTINCT ProductGroup from budget.Product 
UNION
SELECT DISTINCT ProductGroup from budget.Budget
GO	