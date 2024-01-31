/* 
 * KEY-VALUE PAIR TABLE
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA KeyValue;
--CREATE SCHEMA dwh;

DROP TABLE IF EXISTS [dwh].[KeyValue];

CREATE TABLE [dwh].[KeyValue] (
	[_Source] varchar(20),
	[ID] int,
	[Key] nvarchar(3000),
	[Value] nvarchar(3000),
	[Type] nvarchar(125)
)
;

INSERT INTO [dwh].[KeyValue] VALUES 
('[dwh].[KeyValue]', 1,	'name'			,'Bill'			,'text'),
('[dwh].[KeyValue]', 1,	'city'			,'Seattle'		,'text'),
('[dwh].[KeyValue]', 2,	'name'			,'Jeff'			,'text'),
('[dwh].[KeyValue]', 2,	'city'			,'Seattle'		,'text'),
('[dwh].[KeyValue]', 3,	'name'			,'Markus'		,'text'),
('[dwh].[KeyValue]', 3,	'city'			,'Alkoven'		,'text'),
('[dwh].[KeyValue]', 1,	'revenue'		,'20000'		,'Int64.Type'),
('[dwh].[KeyValue]', 2,	'revenue'		,'19000'		,'Int64.Type'),
('[dwh].[KeyValue]', 3,	'revenue'		,'5'			,'Int64.Type'),
('[dwh].[KeyValue]', 1,	'firstPurchase'	,'1980-01-01'	,'date'),
('[dwh].[KeyValue]', 2,	'firstPurchase'	,'2000-01-01'	,'date'),
('[dwh].[KeyValue]', 3,	'firstPurchase'	,'2021-01-01'	,'date'),
('[dwh].[KeyValue]', 1,	'zip'			,'0100'			,'text'),
('[dwh].[KeyValue]', 2,	'zip'			,'0200'			,'text'),
('[dwh].[KeyValue]', 3,	'zip'			,'0300'			,'text')

--select * from dwh.KeyValue
-- PIVOT
SELECT
	*
FROM
	[dwh].[KeyValue] kv
PIVOT 
(
	MIN([Value])
	FOR [Key]
	IN ( 
		[name],
		[city],
		[revenue],
		[firstPurchase],
		[zip]			
	)
) p

-- PIVOT without Type column
SELECT
	*
FROM
	(SELECT [ID], [Key], [Value] FROM [dwh].[KeyValue]) kv
PIVOT 
(
	MIN([Value])
	FOR [Key]
	IN ( 
		[name],
		[city],
		[revenue],
		[firstPurchase],
		[zip]			
	)
) p
GO

-- PIVOT with the right column data type
CREATE OR ALTER VIEW [PowerBI].[KeyValue] 
AS 
(
SELECT
	p.ID [ID]
	, TRY_CONVERT(NVARCHAR(3000),	[city])				AS [city]
	, TRY_CONVERT(DATE,				[firstPurchase])	AS [firstPurchase]
	, TRY_CONVERT(NVARCHAR(3000),	[name])				AS [name]
	, TRY_CONVERT(BIGINT,			[revenue])			AS [revenue]
	, TRY_CONVERT(NVARCHAR(3000),	[zip])				AS [zip]
FROM (SELECT [ID], [Key], [Value] FROM [dwh].[KeyValue]) kv
PIVOT
	(MIN([Value]) FOR [Key] IN (
	  [city]
	, [firstPurchase]
	, [name]
	, [revenue]
	, [zip]
	)
) as p
)
--select * from [PowerBI].[KeyValue]

-- KeyType
DROP TABLE IF EXISTS [KeyValue].[KeyType];
CREATE TABLE [KeyValue].[KeyType] (
	KeyType nvarchar(128),
	KeyDescription nvarchar(128),
	DataType nvarchar(128)
)
INSERT INTO [KeyValue].[KeyType] VALUES 
(N'text',			N'Text',					N'NVARCHAR(3000)' ),
(N'Int64.Type',		N'Whole Number',			N'BIGINT'),
(N'number',			N'Decimal Number',			N'DOUBLE' ),
(N'currency',		N'Fixed Decimal Number',	N'DECIMAL(19,4)' ),
(N'Percentage',		N'Percentage',				N'DECIMAL(19,4)' ),
(N'datetime',		N'Date/Time',				N'DATETIME2' ),
(N'date',			N'Date',					N'DATE' ),
(N'time',			N'Time',					N'TIME' ),
(N'datetimezone',	N'Date/Time/Timezone',		N'DATETIMEOFFSET' ),
(N'duration',		N'Duration',				N'DOUBLE' ),
(N'logical',		N'True/False',				N'BIT' ),
(N'binary',			N'Binary',					N'VARCHAR(max)' )
--select * from [KeyValue].[KeyType]

/*
exec [KeyValue].[CreateViewKeyValue] @debug=1, @_Source = 'KeyValue'
*/
CREATE or ALTER PROC [KeyValue].[CreateViewKeyValue] (
	@_Source varchar(50),
	@debug bit = 1
)
AS
BEGIN

SET NOCOUNT ON;

DECLARE
	--@debug bit = 1,
	--@_Source varchar(50), 
	@CRLF nvarchar(MAX) = CHAR(13)+CHAR(10),
	@cmd nvarchar(MAX),
	@ColumnNameKey nvarchar(max),
	@ColumnNamePivot nvarchar(max)
SELECT
	@ColumnNameKey   = STRING_AGG([ColumnNameKey],   ', ')	WITHIN GROUP (ORDER BY [ColumnNameKey]),
	@ColumnNamePivot = STRING_AGG([ColumnNamePivot], ', ')	WITHIN GROUP (ORDER BY [ColumnNameKey])
FROM
	(SELECT
		DISTINCT
		CONVERT(varchar(max), [Key] + @CRLF)					as [ColumnNameKey],
		CONVERT(varchar(max), 
			N'TRY_CONVERT(' + [DataType] + N', ' + [Key] 
			+ N') AS ' + [Key] + @CRLF)						as [ColumnNamePivot]
	FROM
		(
		SELECT DISTINCT 
			kv.[_source]
			,QUOTENAME(TRIM(kv.[key])) [Key]
			,ISNULL(kt.[DataType], 'NVARCHAR(3000)') [DataType]
		FROM [dwh].[KeyValue] kv
		LEFT JOIN [KeyValue].[KeyType] kt ON kt.KeyType = kv.[Type]
		) k
	) x;

if @debug = 1 exec [KeyValue].[Print] '@ColumnNameKey';
if @debug = 1 exec [KeyValue].[Print] @ColumnNameKey;
if @debug = 1 exec [KeyValue].[Print] '@ColumnNamePivot';
if @debug = 1 exec [KeyValue].[Print] @ColumnNamePivot;

-- VIEW
SET @cmd=N'
CREATE OR ALTER VIEW [PowerBI].[KeyValue] 
AS 
(
/*** DO NOT MAKE ANY CHANGES DIRECTLY ***/
/*** This code was generated ***/
SELECT
	p.ID [ID],
'	+ @ColumnNamePivot + N'
FROM (SELECT [ID], [Key], [Value] FROM [dwh].[KeyValue]) kv
PIVOT
	(MIN([Value]) FOR [Key] IN (
'	+ @ColumnNameKey + N'
)
	) as p
)
'
if @debug = 1 exec [KeyValue].[Print] @cmd;
exec sp_executesql @stmt = @cmd

END
GO


/*
CREATE OR ALTER VIEW [PowerBI].[KeyValue] 
AS 
(
/*** DO NOT MAKE ANY CHANGES DIRECTLY ***/
/*** This code was generated ***/
SELECT
	p.ID [ID],
TRY_CONVERT(NVARCHAR(3000), [city]) AS [city]
, TRY_CONVERT(DATE, [firstPurchase]) AS [firstPurchase]
, TRY_CONVERT(NVARCHAR(3000), [name]) AS [name]
, TRY_CONVERT(BIGINT, [revenue]) AS [revenue]
, TRY_CONVERT(NVARCHAR(3000), [zip]) AS [zip]
 
FROM (SELECT [ID], [Key], [Value] FROM [dwh].[KeyValue]) kv
PIVOT
	(MIN([Value]) FOR [Key] IN (
[city]
, [firstPurchase]
, [name]
, [revenue]
, [zip]
 
)
	) as p
)

*/