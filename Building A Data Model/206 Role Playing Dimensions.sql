/* 
 * ROLE PLAYING DIMENSIONS
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA roleplaying

-- Example
SELECT
	od.CalendarYear OrderYear,
	sd.CalendarYear ShipYear,
	frs.SalesAmount
FROM
	PowerBI.FactResellerSales frs
JOIN PowerBI.DimDate od ON od.DateKey=frs.OrderDateKey
JOIN PowerBI.DimDate sd ON sd.DateKey=frs.ShipDateKey

-- Role Playing Dimensions
GO
CREATE OR ALTER VIEW roleplaying.vw_OrderDate AS (
SELECT
	DateKey			as OrderDateKey,
	Date			as OrderDate,
	CalendarYear	as OrderYear
FROM
	PowerBI.DimDate
)
GO
CREATE OR ALTER VIEW roleplaying.vw_ShipDate AS (
SELECT
	DateKey			as ShipDateKey,
	Date			as ShipDate,
	CalendarYear	as ShipYear
FROM
	PowerBI.DimDate
)
GO
SELECT
	od.OrderCalendarYear,
	sd.ShipYear ,
	frs.SalesAmount
FROM
	PowerBI.FactResellerSales frs
JOIN PowerBI.vw_OrderDate od ON od.OrderDateKey=frs.OrderDateKey
JOIN PowerBI.vw_ShipDate sd ON sd.ShipDateKey=frs.ShipDateKey

-- Automate renaming
DECLARE 
	@SchemaName sysname = 'PowerBI',
	@TableName sysname = 'DimDate',
	@SchemaNameTarget sysname = 'roleplaying',
	@TableNameTarget sysname = 'Date',
	@Prefix nvarchar(50) = 'Ship';

DECLARE
	@ColumnList nvarchar(max),
	@Separator nvarchar(50) = N',' + char(10) + char(09) -- + char(13)
	;

/*
select 
s.name, * 
--STRING_AGG(QUOTENAME(c.name) + ' AS ' + QUOTENAME(@Prefix + c.name), @Separator) WITHIN GROUP(ORDER BY c.column_id)
from sys.views t 
join sys.schemas s on s.schema_id=t.schema_id 
join sys.columns c on c.object_id=t.object_id
where t.name='DimDate' and s.name='PowerBI'
*/

SELECT
	@ColumnList = STRING_AGG(QUOTENAME(c.name) + ' AS ' + QUOTENAME(@Prefix + c.name), @Separator) WITHIN GROUP(ORDER BY c.column_id)
--select *
FROM
	(SELECT t.object_id, t.schema_id FROM sys.tables t UNION ALL
	 SELECT v.object_id, v.schema_id FROM sys.views v) t
JOIN sys.columns c ON c.object_id=t.object_id
WHERE
	OBJECT_NAME(t.object_id) = @TableName AND
	SCHEMA_NAME(t.schema_id) = @SchemaName;
print '
CREATE OR ALTER VIEW ' + QUOTENAME(@SchemaNameTarget) + '.' +	QUOTENAME('vw_' + @Prefix + @TableNameTarget) + ' AS ( 
SELECT 
	' + @ColumnList + '
FROM 
	' + QUOTENAME(@SchemaName) + '.' + QUOTENAME(@TableName) + '
)
'
GO
--
CREATE OR ALTER VIEW [roleplaying].[vw_OrderDate] AS ( 
SELECT 
	[DateKey] AS [OrderDateKey],
	[Date] AS [OrderDate],
	[CalendarYear] AS [OrderCalendarYear],
	[EnglishMonthName] AS [OrderEnglishMonthName],
	[MonthNumberOfYear] AS [OrderMonthNumberOfYear],
	[EnglishDayNameOfWeek] AS [OrderEnglishDayNameOfWeek]
FROM 
	[PowerBI].[DimDate]
)
GO
CREATE OR ALTER VIEW [roleplaying].[vw_ShipDate] AS ( 
SELECT 
	[DateKey] AS [ShipDateKey],
	[Date] AS [ShipDate],
	[CalendarYear] AS [ShipCalendarYear],
	[EnglishMonthName] AS [ShipEnglishMonthName],
	[MonthNumberOfYear] AS [ShipMonthNumberOfYear],
	[EnglishDayNameOfWeek] AS [ShipEnglishDayNameOfWeek]
FROM 
	[PowerBI].[DimDate]
)
GO

--

