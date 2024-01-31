/* 
 * SLOWLY CHANGING DIMENSIONS
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA scd

DROP TABLE IF EXISTS scd.SCDSource;
CREATE TABLE scd.SCDSource (
	AlternateKey int,
	Region nvarchar(50)
);
INSERT INTO scd.SCDSource 
SELECT  0, 'NA'				UNION ALL
SELECT  1, 'Northwest'		UNION ALL
SELECT 10, 'United Kingdom' 

--select * from scd.SCDSource

-- Change
DELETE FROM scd.SCDSource WHERE AlternateKey=0;
UPDATE scd.SCDSource SET Region='Nordwest' WHERE AlternateKey=1
INSERT INTO scd.SCDSource SELECT 11, 'Austria' 

UPDATE scd.SCDSource SET Region='Nordwest2' WHERE AlternateKey=1

/*************/
-- SCD Type 0
DROP TABLE IF EXISTS scd.SCD0;
CREATE TABLE scd.SCD0 (
	AlternateKey int,
	Region nvarchar(50),
	CreatedAt datetime2
);

-- INSERT
INSERT INTO scd.SCD0
SELECT AlternateKey, Region, SYSDATETIME()
FROM scd.SCDSource stage
WHERE NOT EXISTS (SELECT TOP 1 1 FROM scd.SCD0 dwh WHERE dwh.AlternateKey = stage.AlternateKey)

--select * from scd.SCD0

/*************/
-- SCD Type 1
DROP TABLE IF EXISTS scd.SCD1;
CREATE TABLE scd.SCD1 (
	AlternateKey int,
	Region nvarchar(50),
	ChangedAt datetime2,
	DeletedAt datetime2
);

-- INSERT
INSERT INTO scd.SCD1 
SELECT AlternateKey, Region, SYSDATETIME(), null
FROM scd.SCDSource stage
WHERE NOT EXISTS (SELECT TOP 1 1 FROM scd.SCD1 dwh WHERE dwh.AlternateKey = stage.AlternateKey)
-- UPDATE
UPDATE [dwh]
SET 
	 [dwh].[Region] = [stage].[Region]
	,[dwh].[ChangedAt] = SYSDATETIME()
	,[dwh].[DeletedAt] = null
FROM [scd].[SCD1] dwh
INNER JOIN [scd].[SCDSource] stage on dwh.AlternateKey=stage.AlternateKey
WHERE 
([dwh].[Region] <> [stage].[Region] OR ([dwh].[Region] IS NOT NULL AND [stage].[Region] IS NULL) OR ([dwh].[Region] IS NULL AND [stage].[Region] IS NOT NULL)) 
--OR ([dwh].[RegionDesc] <> [stage].[Region] OR ([dwh].[Region] IS NOT NULL AND [stage].[Region] IS NULL) OR ([dwh].[Region] IS NULL AND [stage].[Region] IS NOT NULL))
OR [dwh].[DeletedAt] IS NOT NULL

--SQL Server 2022: dwh.Region IS DISTINCT FROM stage.Region
--https://docs.microsoft.com/en-us/sql/t-sql/queries/is-distinct-from-transact-sql?view=sql-server-ver16

-- DELETE
UPDATE dwh
SET 
	dwh.[DeletedAt] = SYSDATETIME()						
FROM [scd].[SCD1] dwh
WHERE NOT EXISTS (SELECT TOP 1 1 FROM scd.SCDSource stage WHERE stage.AlternateKey = dwh.AlternateKey)

-- Query
SELECT * FROM scd.SCD1

/************/
-- SCD Type 2
DROP TABLE IF EXISTS scd.SCD2;
CREATE TABLE scd.SCD2 (
	SID int identity(1,1),
	AlternateKey int,
	Region nvarchar(50),
	ValidFrom datetime2,
	ValidUntil datetime2
);

-- INSERT NEW ROWS
INSERT INTO [scd].[SCD2] ([AlternateKey], [Region], [ValidFrom], [ValidUntil]) 
SELECT [stage].[AlternateKey], [stage].[Region], SYSDATETIME() AS [ValidFrom], null AS [ValidUntil]
FROM [scd].[SCDSource] [stage]
WHERE NOT EXISTS (
	SELECT TOP 1 1 
	FROM [scd].[SCD2] [dwh] 
	WHERE [dwh].AlternateKey=[stage].AlternateKey 
		AND [dwh].[ValidUntil] IS NULL
	)


-- UPDATE
-- a) INSERT NEW VERSION
INSERT INTO [scd].[SCD2] ([AlternateKey], [Region], [ValidFrom], [ValidUntil])
SELECT [stage].[AlternateKey], [stage].[Region], SYSDATETIME() AS [ValidFrom], null AS [ValidUntil]
FROM [scd].[SCDSource] stage
WHERE
	EXISTS (SELECT TOP 1 1 FROM [scd].[SCD2] dwh WHERE dwh.AlternateKey=stage.AlternateKey
	AND ([dwh].[Region] <> [stage].[Region] OR ([dwh].[Region] IS NOT NULL AND  [stage].[Region] IS NULL) OR ([dwh].[Region] IS NULL AND  [stage].[Region] IS NOT NULL))
	--OR [dwh].[ValidUntil] IS NULL)
	AND dwh.SID >= 1
	)


-- b) INACTIVATE OLD VERSION
UPDATE dwh
SET dwh.[ValidUntil] = SYSDATETIME()
FROM [scd].[SCD2] dwh
INNER JOIN [scd].[SCDSource] stage on dwh.AlternateKey=stage.AlternateKey 
WHERE 
	dwh.SID >= 1 AND
	ISNULL(dwh.[ValidUntil], SYSDATETIME()) >= SYSDATETIME() AND
	([dwh].[Region] <> [stage].[Region] OR ([dwh].[Region] IS NOT NULL AND  [stage].[Region] IS NULL) OR ([dwh].[Region] IS NULL AND  [stage].[Region] IS NOT NULL))

-- DELETE
UPDATE dwh
SET dwh.[ValidUntil] = SYSDATETIME()
FROM [scd].[SCD2] dwh
WHERE 
	dwh.SID >= 1 AND
	ISNULL(dwh.[ValidUntil], SYSDATETIME()) >= SYSDATETIME() AND
	NOT EXISTS (SELECT TOP 1 1 FROM [scd].[SCDSource] stage WHERE dwh.AlternateKey=stage.AlternateKey) 

-- QUERY
SELECT * FROM scd.SCD2