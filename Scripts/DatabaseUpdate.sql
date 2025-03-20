-- GENERAL INFORMATION

-- This script is used to update the database with the latest data from the MySQL database.
-- The script is executed in MSSQL Server Management Studio where:
-- a) the ifc database (called ifcSQL) is loaded with the scripts from ifcSQL project
-- b) the sensor MySQL database (called newage) is connected with the linked server option

-- More details about ifcSQL and its organization into tables can be found in the appropriate repository.
-- More details about the MySQL database can be found in the readme file of this repository.
--      newage.data is organized into the columns:
--            name | AssessmentDate | data_type | value

-- This script extracts, processes, and maps sensor data according to the IFC standard.




-- Execute a stored procedure to select a ifcSQL project with ID 1007.

EXEC [ifcSQL].[app].[SelectProject] 1007; 



-- Step 1: Select the latest data from the sensor MySQL database and store it in the temporary  table @SENSORTABLE.

DECLARE @SENSORTABLE TABLE ( name NVARCHAR(MAX), AssessmentDate NVARCHAR(MAX), data_type NVARCHAR(MAX), value FLOAT);

INSERT INTO @SENSORTABLE (name, AssessmentDate, data_type, value)
SELECT NA.name, NA.AssessmentDate, NA.data_type, NA.value   -- 
FROM OPENQUERY([MYSQL], 'SELECT * FROM newage.data') AS NA
WHERE NA.AssessmentDate = (
    SELECT MAX(NA_inner.AssessmentDate)
    FROM OPENQUERY([MYSQL], 'SELECT * FROM newage.data') AS NA_inner
);



-- Step 2: Update the MapTable with the latest sensor data. 

-- MapTable is updated with the latest value according to same AssetIdentifier and property name.

UPDATE MT
SET MT.Value = ST.value 
FROM [ifcSQL].[cp].[1007_MapTable] MT
INNER JOIN @SENSORTABLE ST
    ON MT.AssetIdentifier COLLATE Latin1_General_100_CS_AS_SC_UTF8 = ST.name COLLATE Latin1_General_100_CS_AS_SC_UTF8
    AND MT.Prop COLLATE Latin1_General_100_CS_AS_SC_UTF8 = ST.data_type COLLATE Latin1_General_100_CS_AS_SC_UTF8;


-- MapTable is updated with the latest assessment date according to same AssetIdentifier

UPDATE MT
SET MT.Date = ST.AssessmentDate
FROM [ifcSQL].[cp].[1007_MapTable] MT
INNER JOIN @SENSORTABLE ST
    ON MT.AssetIdentifier COLLATE Latin1_General_100_CS_AS_SC_UTF8 = ST.name COLLATE Latin1_General_100_CS_AS_SC_UTF8;



-- Step 3: Update the ifcSQL database with the latest sensor data into MapTable.

UPDATE EAOS
SET EAOS.Value = MT.Date
FROM [ifcSQL].[cp].[1007_MapTable] MT
INNER JOIN [ifcSQL].[ifcInstance].[EntityAttributeOfString] EAOS
    ON (MT.ID_AD = EAOS.GlobalEntityInstanceId AND MT.OP_AD=EAOS.OrdinalPosition AND MT.TID_AD=EAOS.TypeId)

UPDATE EAOF
SET EAOF.Value = MT.Value
FROM [ifcSQL].[cp].[1007_MapTable] MT
INNER JOIN [ifcSQL].[ifcInstance].[EntityAttributeOfFloat] EAOF
    ON (MT.ID_PROP = EAOF.GlobalEntityInstanceId AND MT.OP_AD=EAOF.OrdinalPosition AND MT.TID_PROP=EAOF.TypeId)