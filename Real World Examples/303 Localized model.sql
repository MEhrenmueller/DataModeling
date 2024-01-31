/* 
 * MULTI-LANGUAGE REPORTS
 * Markus Ehrenmueller-Jensen
 */

 --CREATE SCHEMA language

CREATE OR ALTER VIEW [language].[TextComponent] AS
(
SELECT 'EN' [LanguageID], 'SalesOverview' [TextComponent], 'Sales Overview' [DisplayText] UNION ALL
SELECT 'EN' [LanguageID], 'SalesDetails' [TextComponent], 'Sales Details' [DisplayText] UNION ALL
SELECT 'tlh-Latn' [LanguageID], 'SalesOverview' [TextComponent], 'QI''yaH' [DisplayText] UNION ALL
SELECT 'tlh-Latn' [LanguageID], 'SalesDetails' [TextComponent], 'qeylIS belHa''' [DisplayText] 
)

CREATE OR ALTER VIEW [language].[vw_TextComponent]
SELECT
	*
FROM
	[language].[TextComponent] tc
PIVOT 
(
	MIN([DisplayText])
	FOR [TextComponent]
	IN ( 
		[SalesOverview],
		[SalesDetails] 
	)
) p
GO

DECLARE
	--@debug bit = 1,
	--@_Source varchar(50), 
	@CRLF nvarchar(MAX) = CHAR(13)+CHAR(10),
	@cmd nvarchar(MAX),
	@ColumnNameList nvarchar(max)
SELECT
	@ColumnNameList   = STRING_AGG([ColumnNameKey],   ', ')	WITHIN GROUP (ORDER BY [ColumnNameKey])
FROM
	(SELECT
		CONVERT(nvarchar(max), [TextComponent] + @CRLF) as [ColumnNameKey]
	FROM
		(
		SELECT 
			DISTINCT 
			QUOTENAME(TRIM(tc.[TextComponent])) [TextComponent]
		FROM [language].[TextComponent] tc
		) k
	) x;

-- VIEW
SET @cmd=N'
--CREATE OR ALTER VIEW [language].[vw_TextComponent]
--AS 
--(
--/*** DO NOT MAKE ANY CHANGES DIRECTLY ***/
--/*** This code was generated ***/
SELECT
	*
FROM [language].[TextComponent] tc
PIVOT
(
	MIN([DisplayText]) 
	FOR [TextComponent] IN (
'	+ @ColumnNameList + N'
	)
) as p
'
exec sp_executesql @stmt = @cmd
print @cmd

