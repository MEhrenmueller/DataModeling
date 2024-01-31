/*
 * PARTITIONING
 * Markus Ehrenmueller-Jensen
 */

--CREATE SCHEMA partitioning

DROP TABLE IF EXISTS partitioning.FactResellerSales
IF EXISTS(SELECT TOP 1 1 FROM sys.partition_schemes WHERE name = 'psOrderDate') DROP PARTITION SCHEME psOrderDate
IF EXISTS(SELECT TOP 1 1 FROM sys.partition_functions WHERE name = 'pfOrderDate') DROP PARTITION FUNCTION pfOrderDate


-- Partition function for four (4) partitions
--DROP PARTITION FUNCTION pfOrderDate 
CREATE PARTITION FUNCTION pfOrderDate (datetime2(0))  
     AS RANGE RIGHT FOR VALUES 
     ('2023-09-01', '2023-10-01', '2023-11-01') ;  
GO

-- Assigning the partitions to file groups
--DROP PARTITION SCHEME psOrderDate  
CREATE PARTITION SCHEME psOrderDate  
    AS PARTITION PfOrderDate  
    ALL TO ('PRIMARY') ;  
GO

-- Creating a partitioned table 
DROP TABLE IF EXISTS partitioning.FactResellerSales
CREATE TABLE partitioning.FactResellerSales (
     [OrderDate] datetime2(0), 
     [SalesAmount] decimal(19, 2)
)  
    ON PsOrderDate (OrderDate) ;  
GO

-- Populating the table
INSERT INTO partitioning.FactResellerSales
SELECT OrderDate, SalesAmount
FROM PowerBI.FactResellerSales

-- Count rows per day
SELECT OrderDate, COUNT(*) [RowCount]
FROM PowerBI.FactResellerSales
GROUP BY OrderDate
ORDER BY OrderDate;

-- Count rows per partition
SELECT
	s.[name] AS SchemaName 
	, t.[name] AS TableName 
	--, i.name AS IndexName
	--, p.index_id AS IndexID 
	, ds.[name] AS PartitionScheme 
	, p.partition_number AS PartitionNumber 
	, COALESCE(f.[name], d.[name]) AS [FileGroup]
	, p.[rows] AS [RowCount]
	, c.[name] PartitionKey
	, prv_left.[value] AS LowerBoundaryValue 
	, prv_right.[value] AS UpperBoundaryValue 
	, CASE pf.boundary_value_on_right 
	  WHEN 1 
	  THEN 'RIGHT' 
	  ELSE 'LEFT' 
	  END AS PartitionFunctionRange 
	, QUOTENAME(c.name) + ' IS NOT NULL AND ' + 
		CASE pf.boundary_value_on_right WHEN 1 THEN 
		--'RIGHT' 
		ISNULL(QUOTENAME(c.name) + ' >= ''' + 
		convert(varchar, prv_left.[value], 126) + '''', '') + 
		case when p.partition_number NOT IN (1, MAX(p.partition_number) OVER()) 
		then ' AND ' 
		else '' 
		end + 
		ISNULL(QUOTENAME(c.name) + ' < ''' +  
		convert(varchar, prv_right.[value], 126) + '''', '')
		ELSE 
		--'LEFT' 
		ISNULL('[PartitionKey] > ''' + 
		convert(varchar, prv_left.[value], 126) + '''', '') + 
		case when p.partition_number NOT IN (1, MAX(p.partition_number) OVER()) 
		then ' AND ' 
		else '' 
		end + ISNULL(QUOTENAME(c.name) + ' <= ''' +  
		convert(varchar, prv_right.[value], 126) + '''', '')
		END as CheckConstraint
		--,*
FROM
    sys.schemas AS s
INNER JOIN sys.tables AS t ON 
	t.schema_id = s.schema_id
INNER JOIN sys.partitions AS p ON 
	p.object_id = t.object_id
INNER JOIN sys.indexes AS i ON 
	i.[object_id] = p.[object_id] AND 
	i.index_id = p.index_id
LEFT JOIN sys.index_columns AS ic ON 
	ic.[object_id] = i.[object_id] AND 
	ic.index_id = i.index_id
LEFT JOIN sys.columns AS c ON 
	c.[object_id] = ic.[object_id] AND
    c.column_id = ic.column_id
LEFT JOIN sys.data_spaces AS ds ON 
	ds.data_space_id = i.data_space_id
LEFT JOIN sys.partition_schemes AS ps ON 
	ps.data_space_id = ds.data_space_id
LEFT JOIN sys.partition_functions AS pf ON 
	pf.function_id = ps.function_id
--INNER JOIN sys.destination_data_spaces AS dds2 ON dds2.partition_scheme_id = ps.data_space_id AND dds2.destination_id = p.partition_number
--INNER JOIN sys.filegroups AS fg ON fg.data_space_id = dds2.data_space_id
LEFT JOIN sys.filegroups AS f ON 
	f.data_space_id = i.data_space_id
LEFT JOIN sys.destination_data_spaces AS dds ON 
	dds.partition_scheme_id = i.data_space_id AND 
	dds.destination_id = p.partition_number
LEFT JOIN sys.filegroups AS d ON 
	d.data_space_id = dds.data_space_id
LEFT JOIN sys.partition_range_values AS prv_left ON 
	ps.function_id = prv_left.function_id AND 
	prv_left.boundary_id = p.partition_number - 1
LEFT JOIN sys.partition_range_values AS prv_right ON 
	ps.function_id = prv_right.function_id AND 
	prv_right.boundary_id = p.partition_number
WHERE
	s.[name] = 'partitioning' AND
	t.[name] IN ( 'FactResellerSales', 'FactResellerSales_STAGE' ) AND
	t.[type] = 'U' AND 
	i.index_id IN (0, 1) 
ORDER BY
      s.[name]
	, t.[name]
    , p.index_id
    , p.partition_number;



-- Creating a table to host the partition that needs to be updated
-- This table is not partitioned
DROP TABLE IF EXISTS partitioning.FactResellerSales_STAGE;
SELECT TOP 0 *
INTO partitioning.FactResellerSales_STAGE ON [PRIMARY]
FROM partitioning.FactResellerSales
GO


ALTER TABLE partitioning.FactResellerSales 
SWITCH PARTITION 3 
TO partitioning.FactResellerSales_STAGE

-- rerun query to count rows per partition

--Statement fails due to missing check constraints
ALTER TABLE partitioning.FactResellerSales_STAGE SWITCH TO partitioning.FactResellerSales PARTITION 3
/*
ALTER TABLE SWITCH statement failed. Check constraints of source table 
'AdventureWorksDW.partitioning.FactResellerSales_STAGE' allow values that 
are not allowed by range defined by partition 3 on target table 
'AdventureWorksDW.partitioning.FactResellerSales'.
*/

-- create check constraints reflecting the partition borders
-- RANGE RIGHT --> ">= and <"
-- RANGE LEFT  --> ">  and <=" 
ALTER TABLE partitioning.FactResellerSales_STAGE 
WITH CHECK 
ADD CONSTRAINT CK_FactResellerSales_STAGE_OrderDate CHECK (OrderDate IS NOT NULL AND OrderDate >= {d'2023-10-01'} AND OrderDate < {d'2023-11-01'})
--ALTER TABLE partitioning.FactResellerSales_STAGE 
--WITH CHECK 
--ADD CONSTRAINT CK_FactResellerSales_STAGE_MinOrderDate CHECK (OrderDate IS NOT NULL AND OrderDate >= {d'2023-10-01'})
--ALTER TABLE partitioning.FactResellerSales_STAGE 
--WITH CHECK 
--ADD CONSTRAINT CK_FactResellerSales_STAGE_MaxOrderDate CHECK (OrderDate IS NOT NULL AND OrderDate < {d'2023-11-01'})

ALTER TABLE partitioning.FactResellerSales_STAGE SWITCH TO partitioning.FactResellerSales PARTITION 3

-- clean up
ALTER TABLE partitioning.FactResellerSales_STAGE 
drop CONSTRAINT CK_FactResellerSales_STAGE_MinOrderDate 
ALTER TABLE partitioning.FactResellerSales_STAGE 
DROP CONSTRAINT CK_FactResellerSales_STAGE_MaxOrderDate 
