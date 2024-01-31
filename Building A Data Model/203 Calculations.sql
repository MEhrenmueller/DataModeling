/* 
 * CALCULATIONS
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA calc

 --Preparation
CREATE OR ALTER VIEW calc.SalesAggregation AS (
SELECT
	frs.ProductKey,
	SUM(frs.SalesAmount) as SalesAmount,
	SUM(frs.TotalProductCost) as TotalProductCost,
	SUM(SalesAmount) - SUM(frs.TotalProductCost) Margin,
	AVG(frs.UnitPrice) as UnitPrice, -- dangerous
	SUM(frs.OrderQuantity) as OrderQuantity,
	SUM(frs.DiscountAmount) as DiscountAmount,
	(SUM(SalesAmount) - SUM(frs.TotalProductCost)) / SUM(SalesAmount) MarginPct,

	COUNT(frs.SalesAmount) as SalesAmountCount,
	AVG(frs.SalesAmount) as SalesAmountAvg -- dangerous
FROM
	dbo.FactResellerSales frs
GROUP BY frs.ProductKey
);
GO

-- Margin
SELECT
	FORMAT(SUM(SalesAmount) - SUM(TotalProductCost), '#,###')  Margin1,
	FORMAT(SUM(Margin), '#,###') Margin2
FROM
	calc.SalesAggregation;

-- SalesAmount
-- calc.SalesAggregation.UnitPrice is not correct
SELECT
	FORMAT(SUM(SalesAmount), '#,###')  SalesAmount1,
	FORMAT(SUM((UnitPrice * OrderQuantity) - DiscountAmount), '#,###')  SalesAmount2,
	FORMAT((AVG(UnitPrice) * SUM(OrderQuantity)) - SUM(DiscountAmount), '#,###')  SalesAmount3
FROM
	calc.SalesAggregation
GO
SELECT
	FORMAT(SUM(SalesAmount4), '#,###') SalesAmount4, 
	FORMAT(SUM(SalesAmount5), '#,###') SalesAmount5
FROM 
	(SELECT 
		SalesAmount as SalesAmount4, 
		(UnitPrice*OrderQuantity)-DiscountAmount SalesAmount5
	 FROM dbo.FactResellerSales
	 ) x


-- MarginPct
SELECT
	FORMAT(SUM(Margin), '#,###')  Margin,
	FORMAT(SUM(SalesAmount), '#,###')  SalesAmount,
	FORMAT(AVG(MarginPct), '0.00%')  MarginPct1,
	FORMAT(SUM(Margin) / SUM(SalesAmount), '0.00%')  MarginPct2
FROM
	calc.SalesAggregation;

-- Average over Aggregates
SELECT
	FORMAT(SUM(SalesAmount), '#,###')  SalesAmount,
	FORMAT(SUM(SalesAmountCount), '#,###')  SalesAmountCount,
	FORMAT(SUM(SalesAmount) / SUM(SalesAmountCount), '#,###')  SalesAmountAvg1,
	FORMAT(AVG(SalesAmountAvg), '#,###')  SalesAmountAvg2,
	FORMAT(SUM(SalesAmountAvg), '#,###')  SalesAmountAvg,
	FORMAT(COUNT(SalesAmountAvg), '#,000')  SalesAmountAvgCount,
	FORMAT(SUM(SalesAmountAvg)  / COUNT(SalesAmountAvg), '#,###')   SalesAmountAvg3
FROM
	calc.SalesAggregation;

--CREATE SCHEMA numericcalculations
GO
CREATE OR ALTER VIEW numericcalculations.Sales AS (
SELECT
	x.*, 
	Price * Quantity as SalesAmount,
	(Price * Quantity) - TotalCost as Margin,
	((Price * Quantity) - TotalCost) / (Price * Quantity) as [Margin%],
	SUM(Quantity) OVER () as TotalQuantity
FROM (
	SELECT DATEADD(month, DATEDIFF(month, 0, SYSDATETIME()), 0) as Date, 100 as [Product ID],  10 as Price, 3 as Quantity,  25 as Totalcost UNION ALL
	SELECT DATEADD(month, DATEDIFF(month, 0, SYSDATETIME()), 0) as Date, 110 as [Product ID],  20 as Price, 1 as Quantity,  15 as Totalcost UNION ALL
	SELECT DATEADD(month, DATEDIFF(month, 0, SYSDATETIME()), 0) as Date, 110 as [Product ID],  30 as Price, 4 as Quantity,  75 as Totalcost UNION ALL
	SELECT DATEADD(month, DATEDIFF(month, 0, SYSDATETIME()), 0) as Date, 120 as [Product ID], 100 as Price, 5 as Quantity, 350 as Totalcost 
	) x
)
GO
CREATE OR ALTER VIEW numericcalculations.Product AS (
SELECT 100 as [Product ID], 'A' as [Product Desc], 'Subgroup X' as [Product Subgroup],  10 as [List Price] UNION ALL
SELECT 110 as [Product ID], 'B' as [Product Desc], 'Subgroup Y' as [Product Subgroup],  30 as [List Price] UNION ALL
SELECT 120 as [Product ID], 'C' as [Product Desc], 'Subgroup Z' as [Product Subgroup], 110 as [List Price] UNION ALL
SELECT 130 as [Product ID], 'D' as [Product Desc], 'Subgroup Z' as [Product Subgroup], 200 as [List Price] 
)
GO
CREATE OR ALTER VIEW numericcalculations.[Date] AS 
WITH 
MinDate AS ( SELECT DATEFROMPARTS(YEAR(SYSDATETIME()),   01, 01) as MinDate),
MaxDate AS ( SELECT DATEFROMPARTS(YEAR(SYSDATETIME())+1, 01, 01) as MaxDate),
MaxNumber AS ( SELECT CONVERT(bigint, DATEDIFF(day, MinDate, MaxDate)) MaxNumber FROM MinDate CROSS JOIN MaxDate),
NumberTable AS ( SELECT N as Number FROM demo.GetNumsItzikBatch(1, (SELECT MaxNumber FROM MaxNumber))),
Date AS (
SELECT
	DATEADD(
		day,
		n.Number,
		d.MinDate
		) Date
FROM
	NumberTable n
CROSS JOIN MinDate d
)
SELECT
	Date									as [Date],
	YEAR(Date)								as [Year],
	FORMAT(Date, 'yyyy-MM')					as [Month]
FROM
	Date
GO
