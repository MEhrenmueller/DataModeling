/*
 * AGGREGATED FACTS
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA agg

-- Aggregation table fact
GO
CREATE OR ALTER VIEW agg.FactResellerSalesAgg AS
SELECT
	OrderDate,
	COUNT(*) SalesCount,
	SUM(SalesAmount) SalesAmount
FROM
	PowerBI.FactResellerSales
GROUP BY OrderDate
GO
SELECT * FROM agg.FactResellerSalesAgg ORDER BY OrderDate

-- Periodic Snapshot Fact
GO
CREATE OR ALTER VIEW agg.FactResellerSalesPeriodic AS
SELECT
	--DATEFROMPARTS(dd.CalendarYear, dd.MonthNumberOfYear, 01) OrderDate,
	DATEADD(dd, -(DAY(dd.Date)-1), dd.Date) OrderDate,
	COUNT(frs.SalesAmount) SalesCount,
	SUM(frs.SalesAmount) SalesAmount
	--select *
FROM
	PowerBI.DimDate dd
LEFT JOIN PowerBI.FactResellerSales frs ON frs.OrderDate = dd.Date
GROUP BY DATEADD(dd, -(DAY(dd.Date)-1), dd.Date)
GO
SELECT * FROM agg.FactResellerSalesPeriodic ORDER BY OrderDate

