/* 
 * DATA VS. QUERY
 * Markus Ehrenmueller-Jensen
 */

-- DATA
-- s. ETL

-- QUERY
CREATE OR ALTER VIEW dbo.vw_Sales AS
SELECT 
	DISTINCT 
	p.ID ProductID,
	SalesAmount
FROM 
	dbo.ProductSales ps
LEFT JOIN dbo.Product p ON p.Product=ps.Product;

-- STORED PROC (parameterized)
