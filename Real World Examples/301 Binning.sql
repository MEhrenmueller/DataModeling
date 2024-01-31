/* 
 * BINNING
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA bin

-- Less ideal solution
CREATE OR ALTER VIEW bin.vw_FactResellerSales AS
SELECT
	DISTINCT
	--*,
	CASE
		WHEN OrderQuantity <=  5 THEN 'Small'
		WHEN OrderQuantity <= 10 THEN 'Medium'
		ELSE                          'Large'
	END QuantityBin
FROM
	PowerBI.FactResellerSales frs
GO

-- Static Bin
GO
CREATE OR ALTER VIEW bin.vw_QuantityBin AS
SELECT
	DISTINCT
	OrderQuantity,
	CASE
	WHEN OrderQuantity <=  5 THEN 'Small'
	WHEN OrderQuantity <= 10 THEN 'Medium'
	ELSE					      'Large'
	END QuantityBin
FROM
	PowerBI.FactResellerSales
GO
SELECT
	*
FROM
	bin.vw_QuantityBin

-- Apply in a query
SELECT
	frs.OrderQuantity,
	qb.QuantityBin,
	frs.*
FROM
	PowerBI.FactResellerSales frs
JOIN bin.vw_QuantityBin qb ON qb.OrderQuantity = frs.OrderQuantity

-- Static Bin V2
GO
CREATE OR ALTER VIEW bin.vw_SalesAmountBin AS
SELECT
	DISTINCT
	CONVERT(int, SalesAmount/1000) SalesAmountK,
	CASE
	WHEN SalesAmount/1000 <=  5 THEN 'Small'
	WHEN SalesAmount/1000 <= 10 THEN 'Medium'
	ELSE					         'Large'
	END SalesAmountBin
FROM
	PowerBI.FactResellerSales
GO
SELECT
	*
FROM
	bin.vw_SalesAmountBin

-- Apply in a query
SELECT
	frs.SalesAmount,
	sb.SalesAmountBin,
	frs.*
FROM
	PowerBI.FactResellerSales frs
JOIN bin.vw_SalesAmountBin sb ON sb.SalesAmountK = CONVERT(int, frs.SalesAmount/1000)

-- Static bin V3
CREATE OR ALTER VIEW bin.vw_QuantityBin AS
WITH 
MinNumber AS (SELECT MIN(OrderQuantity) MinNumber FROM PowerBI.FactResellerSales),
MaxNumber AS (SELECT MAX(OrderQuantity) MaxNumber FROM PowerBI.FactResellerSales),
NumberTable AS ( SELECT N as Number FROM demo.GetNumsItzikBatch(0, (SELECT MaxNumber FROM MaxNumber)))
SELECT
	Number as OrderQuantity,
	CASE
	WHEN Number <=  5 THEN 'Small'
	WHEN Number <= 10 THEN 'Medium'
	ELSE                   'Large'
	END QuantityBin
FROM
	NumberTable
GO
SELECT
	*
FROM
	bin.vw_QuantityBin

-- Apply in a query
SELECT
	frs.OrderQuantity,
	qb.QuantityBin,
	frs.*
FROM
	PowerBI.FactResellerSales frs
JOIN bin.vw_QuantityBin qb ON qb.OrderQuantity = frs.OrderQuantity




-- Dynamic Bin Table
CREATE OR ALTER VIEW bin.[vw_QuantityBin Range] AS (
SELECT 'Small'  [QuantityBin], null [Low (incl.)],    5 [High (excl.)] UNION ALL
SELECT 'Medium' [SalesAmountBin],    5 [Low (incl.)],   10 [High (excl.)] UNION ALL
SELECT 'Large'  [QuantityBin],   10 [Low (incl.)], null [High (excl.)] 
)
GO
SELECT
	frs.OrderQuantity,
	sb.QuantityBin,
	frs.*
FROM
	PowerBI.FactResellerSales frs
JOIN bin.[vw_QuantityBin Range] sb ON 
	(frs.OrderQuantity >= sb.[Low (incl.)]  OR sb.[Low (incl.)]   IS NULL) AND
	(frs.OrderQuantity <  sb.[High (excl.)] OR sb.[High (excl.)]  IS NULL)

GO
CREATE OR ALTER VIEW bin.[vw_SalesAmountBin Range] AS (
SELECT 'Small'  [SalesAmountBin], null [Low (incl.)],    5 [High (excl.)] UNION ALL
SELECT 'Medium' [SalesAmountBin],    5 [Low (incl.)],   10 [High (excl.)] UNION ALL
SELECT 'Large'  [SalesAmountBin],   10 [Low (incl.)], null [High (excl.)] 
)
GO

SELECT
	frs.SalesAmount,
	sb.SalesAmountBin,
	frs.*
FROM
	PowerBI.FactResellerSales frs
JOIN bin.[vw_Bin Range] sb ON 
	(CONVERT(int, frs.SalesAmount/1000) >= sb.[Low (incl.)]  OR sb.[Low (incl.)]   IS NULL) AND
	(CONVERT(int, frs.SalesAmount/1000) <  sb.[High (excl.)] OR sb.[High (excl.)]  IS NULL)
