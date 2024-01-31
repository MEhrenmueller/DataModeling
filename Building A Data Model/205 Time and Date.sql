/* 
 * TIME AND DATE
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA [date]

-- Date
CREATE OR ALTER VIEW [date].vw_Date AS 
WITH 
MinYear AS ( SELECT YEAR(MIN(OrderDate)) MinYear FROM PowerBI.FactResellerSales ),
MinDate AS ( SELECT DATEFROMPARTS(MinYear, 01, 01) MinDate FROM MinYear),
MaxYear AS ( SELECT YEAR(MAX(OrderDate)) MaxYear FROM PowerBI.FactResellerSales),
MaxDate AS ( SELECT DATEFROMPARTS(MaxYear+1, 12, 31) MaxDate FROM MaxYear),
MaxNumber AS ( SELECT CONVERT(bigint, DATEDIFF(day, MinDate, MaxDate)) MaxNumber FROM MinDate CROSS JOIN MaxDate),
NumberTable AS ( SELECT N as Number FROM demo.GetNumsItzikBatch(0, (SELECT MaxNumber FROM MaxNumber))),
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
	[Date]										as [Date],
	CONVERT(int, FORMAT([Date], 'yyyyMMdd'))	as DateKey,
	YEAR([Date])								as Year,
	MONTH([Date])								as [Month Number],
	FORMAT([Date], 'MMMM')						as Month,
	YEAR([Date]) * 12 + MONTH([Date])			as MonthID,
	FORMAT([Date], 'yyyy-MM', 'en-us')			as [YYYY-MM],
	DAY([Date])									as [Day],
	--DATEPART(dw, [Date])						as [Day of Week], -- Sunday = 1
	(DATEPART(dw, [Date]) + 5) % 7 + 1			as [Day of Week], -- Monday = 1, https://stackoverflow.com/questions/24877124/sql-datepartdw-date-need-monday-1-and-sunday-7
	FORMAT([Date], 'dddd', 'en-us')				as [Day Name],
	DATEDIFF(day, '1899-12-30', [Date])			as [DateID],
	DATEPART(ww, [Date])						as [Week Number],
	DATEPART(iso_week, [Date])					as [Week Number ISO]
FROM
	Date
GO
select * from [date].vw_Date

-- Time
GO
CREATE OR ALTER VIEW [date].vw_Time AS 
WITH 
NumberTable AS ( SELECT N as Number FROM demo.GetNumsItzikBatch(1, 24 /* hours */ * 60 /* minutes */)),
[Time] AS (
SELECT
	DATEADD(minute, Number, '00:00:00') as [Time]
FROM
	NumberTable
)
SELECT
	convert(Time, [Time])					as [Time],
	FORMAT(Time, 'HH')						as [Hour],
	FORMAT(Time, 'mm')						as [Minutes],
	FORMAT(Time, 'HH:mm')					as [TimeDescription]
FROM
	Time
GO
select * from [date].vw_Time
