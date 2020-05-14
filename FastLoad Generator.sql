/*************************************************************************************************************************************
	Title:		FastLoad Script Generator
	Author:		Donny Seward Jr
	Email:		donald.seward.jr@gmail.com
	Desc:

	Generates a FastLoad script based on a single table definition.
	
		- Use Find and Replace to change DatabaseName and TableName values in WHERE clauses.
			- <database> <table>
		- Update source filepath to wherever your source files are.
		- NOTE: The script assumes the source file has the same name as the target table.  Change accordingly.
		- Source file must be tab-delimitted.  Otherwise change 'vartext "	"' to the correct delimitter.
		- Uses VARTEXT format which means all data types must be VARCHAR.

*************************************************************************************************************************************/

/* Session configuration settings */
SELECT
	  1 AS SECTION
	, DatabaseName
	, TableName
	, CAST(1 AS INTEGER) AS ColumnId
	, CAST(
	'sessions 4;' || '0D0A'xc ||
	'errlimit 25;' || '0D0A'xc || '0D0A'xc ||
	'.logon 192.168.100.162/dbc,dbc;' || '0D0A'xc || '0D0A'xc ||
	'.set record vartext "	";' || '0D0A'xc || '0D0A'xc ||
	'DEFINE' AS VARCHAR(500)) AS FL_Script
FROM DBC.TablesV
WHERE DatabaseName = '<database>' AND TableName = '<table>'

UNION ALL

/* List of columns and filepath of source file  */
SELECT
	  2 AS SECTION
	, V1.DatabaseName
	, V1.TableName
	, V1.ColumnId
	, CASE
		WHEN V1.ColumnType IN ('CV','CF') THEN '"' || V1.ColumnName || '"' || 
			 ' (VARCHAR(' || TRIM(V1.ColumnLength) || '))'
		ELSE '"' || V1.ColumnName || '"' || ' (VARCHAR(255))' 
	  END ||
	  	CASE 
			WHEN V1.ColumnId = MAX_COL_ID.ColumnId_Max THEN '0D0A'xc || '0D0A'xc ||
				 -- Change filepath to source of flat file.
				 'FILE= C:\' || 
				 V1.TableName || '.txt;' 
			ELSE ','
	  	END AS FL_Script
FROM DBC.ColumnsV AS V1

LEFT JOIN
	-- find last column to remove comma in output list.
	(
	SELECT
		  DatabaseName
		, TableName
		, MAX(ColumnId) AS ColumnId_Max
	FROM DBC.ColumnsV
	GROUP BY 1,2
	WHERE DatabaseName = '<database>' AND TableName = '<table>'
	) AS MAX_COL_ID
 ON MAX_COL_ID.DatabaseName = V1.DatabaseName
AND MAX_COL_ID.TableName = V1.TableName

WHERE V1.DatabaseName = '<database>' AND V1.TableName = '<table>'

UNION ALL

/* List of column VALUES */
SELECT
	  3 AS SECTION
	, V1.DatabaseName
	, V1.TableName
	, V1.ColumnId
	, CASE 
		WHEN V1.ColumnId = MAX_COL_ID.ColumnId_Min THEN 
			 '0D0A'xc || 'BEGIN LOADING ' || V1.DatabaseName || '.' || V1.TableName ||
			 '0D0A'xc || 'ERRORFILES ' || V1.DatabaseName || '.' || V1.TableName || '_ERROR1, ' ||
			 V1.DatabaseName || '.' || V1.TableName || '_ERROR2' || '0D0A'xc '0D0A'xc 'CHECKPOINT 5000;' ||
			 '0D0A'xc || '0D0A'xc || 'INSERT INTO ' || V1.DatabaseName || '.' || V1.TableName || ' VALUES (' ||
			 '0D0A'xc || ':"' || V1.ColumnName || '",'
		ELSE ':"' || V1.ColumnName || '"' END || 
	  	CASE 
	  		WHEN V1.ColumnId = MAX_COL_ID.ColumnId_Max THEN '); ' || 
	  	   		 '0D0A'xc || '0D0A'xc || 'END LOADING;' || '0D0A'xc || 'LOG OFF;'
	  		WHEN V1.ColumnId = MAX_COL_ID.ColumnId_Min THEN '' 
	  		ELSE ',' 
	    END AS FL_Script

FROM DBC.ColumnsV AS V1

LEFT JOIN
	(
	SELECT
		  DatabaseName
		, TableName
		, MIN(ColumnId) AS ColumnId_Min
		, MAX(ColumnId) AS ColumnId_Max
	FROM DBC.ColumnsV
	GROUP BY 1,2
	WHERE DatabaseName = '<database>' AND TableName = '<table>'
	) AS MAX_COL_ID
 ON MAX_COL_ID.DatabaseName = V1.DatabaseName
AND MAX_COL_ID.TableName = V1.TableName

WHERE V1.DatabaseName = '<database>' AND V1.TableName = '<table>'

ORDER BY 1,2,3,4;