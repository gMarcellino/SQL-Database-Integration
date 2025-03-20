-- GENERAL INFORMATION

-- This script is used to map the position of all the relevant information about sensors in ifcSQL database's tables. 

-- This script extracts, processes, and maps sensor data according to the IFC standard.

-- The mapping is done creating a new table called MapTable that stores the sensor data. The table is inside the ifcSQL database, but is not part of the IFC file.

-- The script is executed in MSSQL Server Management Studio where:
-- a) the ifc database (called ifcSQL) is loaded with the scripts from ifcSQL project

-- More details about ifcSQL and its organization into tables can be found in the appropriate repository.





-- Execute a stored procedure to select a ifcSQL project with ID 1007.

EXEC [ifcSQL].[app].[SelectProject] 1007;

-- Use the ifcSQL database for all subsequent queries

USE [ifcSQL]; 
GO



-- Step 1: Create a mapping table to store sensor data according to IFC standard, such as AssessmentDate (AD) and SetPointMovement, SetPointHumidity, SetPointTemperature (PROP)

CREATE TABLE [ifcSQL].[cp].[MapTable] (
    AssetIdentifier NVARCHAR(MAX),  -- The name of the sensor from AssetIdentifier property
    ID_AD INT,                      -- The GlobalEntityInstanceId of the AssessmentDate property
    OP_AD INT,                      -- The OrdinalPosition of the AssessmentDate property
    TID_AD INT,                     -- The TypeId of the AssessmentDate property
    Date NVARCHAR(MAX),             -- The value of the AssessmentDate property
    ID_PROP INT,                    -- The GlobalEntityInstanceId of the sensor property (SetPointMovement, SetPointHumidity, SetPointTemperature)
    OP_PROP INT,                    -- The OrdinalPosition of the sensor property (SetPointMovement, SetPointHumidity, SetPointTemperature)
    TID_PROP INT,                   -- The TypeId of the sensor property (SetPointMovement, SetPointHumidity, SetPointTemperature)
    Prop NVARCHAR(MAX),             -- The name of the sensor property (SetPointMovement, SetPointHumidity, SetPointTemperature)
    Value FLOAT                     -- The value of the sensor property (SetPointMovement, SetPointHumidity, SetPointTemperature)
);



-- Step 2: Select all sensors and store their GlobalEntityInstanceIds in the temporary table @SENSOR

DECLARE @SENSOR TABLE (GlobalEntityInstanceId NVARCHAR(MAX), Value NVARCHAR(MAX));

INSERT INTO @SENSOR (GlobalEntityInstanceId, Value)
SELECT E.GlobalEntityInstanceId, H.Value
FROM [ifcSQL].[cp].[Entity] E
INNER JOIN [ifcSQL].[cp].[EntityAttributeOfString] H 
    ON H.GlobalEntityInstanceId = E.GlobalEntityInstanceId 
    AND H.OrdinalPosition = 3                       
INNER JOIN [ifcSQL].[ifcSchema].[Type] T 
    ON E.EntityTypeId = T.TypeId
INNER JOIN [ifcSQL].[cp].[EntityInstanceIdAssignment] EA 
    ON E.GlobalEntityInstanceId = EA.GlobalEntityInstanceId
WHERE 'IFC' + UPPER(T.TypeName) = 'IFCSENSOR';      -- The sensors are selected based on their TypeName 'IFCSENSOR'



-- Step 3: Select all GUIDs of the elements in @SENSOR and store their GlobalEntityInstanceIds and value in the temporary table @GUID

DECLARE @GUID TABLE (GlobalEntityInstanceId NVARCHAR(MAX), Value NVARCHAR(MAX));

INSERT INTO @GUID (GlobalEntityInstanceId, Value)
SELECT H.GlobalEntityInstanceId, H.Value
FROM [ifcSQL].[cp].[Entity] E
INNER JOIN [ifcSQL].[cp].[EntityAttributeOfString] H ON (H.[GlobalEntityInstanceId] = E.[GlobalEntityInstanceId] and H.OrdinalPosition=1)   -- The GUIDs are filtered based on their OrdinalPosition (1): e.g. IFCSENSOR('1dIT8vQ4HFSAVijQtVuMl6',#18,'Sensore statico:Static Monitoring:866409',$,'Static Sensor',#832903,#832898,'866409',.NOTDEFINED.);
INNER JOIN @SENSOR C ON C.GlobalEntityInstanceId=H.GlobalEntityInstanceId;



-- Step 4: Select all relationships of type 'IFCRELDEFINESBYPROPERTIES' and store their GlobalEntityInstanceIds in the temporary table @RELDEFINESBYPROPERTIES

DECLARE @RELDEFINESBYPROPERTIES TABLE (GlobalEntityInstanceId NVARCHAR(MAX));

INSERT INTO @RELDEFINESBYPROPERTIES (GlobalEntityInstanceId)
SELECT E.GlobalEntityInstanceId
FROM [ifcSQL].[cp].[Entity] E
INNER JOIN [ifcSQL].[ifcSchema].[Type] T ON E.[EntityTypeId] = T.[TypeId]
INNER JOIN [ifcSQL].[cp].[EntityInstanceIdAssignment] EA ON E.[GlobalEntityInstanceId] = EA.[GlobalEntityInstanceId]
WHERE 'IFC' + UPPER(T.[TypeName]) = 'IFCRELDEFINESBYPROPERTIES';



-- Step 5: Select related properties for the relationships of type 'IFCRELDEFINESBYPROPERTIES' and store the values in the temporary table @REL

DECLARE @REL TABLE (Value INT);

INSERT INTO @REL (Value)
SELECT R.Value
FROM [ifcSQL].[cp].[EntityAttributeListElementOfEntityRef] R
JOIN @RELDEFINESBYPROPERTIES W ON R.[GlobalEntityInstanceId] = W.GlobalEntityInstanceId;



-- Step 6: Select all related properties and relationship of the sensors and store their values in the temporary table @RELTOT

DECLARE @RELTOT TABLE (GlobalEntityInstanceId NVARCHAR(MAX), SensorValue NVARCHAR(MAX), GUID NVARCHAR(MAX));

INSERT INTO @RELTOT (GlobalEntityInstanceId, SensorValue, GUID)
SELECT R.GlobalEntityInstanceId, W.Value, L.Value
FROM [ifcSQL].[cp].[EntityAttributeListElementOfEntityRef] R
INNER JOIN [ifcSQL].[cp].[EntityAttributeOfString] H ON (H.[GlobalEntityInstanceId] = R.[Value] and H.OrdinalPosition=3)
INNER JOIN @RELDEFINESBYPROPERTIES REL ON R.GlobalEntityInstanceId = REL.GlobalEntityInstanceId
INNER JOIN @SENSOR W ON R.Value = W.GlobalEntityInstanceId
INNER JOIN @GUID L ON R.Value = L.GlobalEntityInstanceId;



-- Step 7: Select the related properties and insert them into the temporary table @RELPROP

DECLARE @RELPROP TABLE (RValue INT, Value NVARCHAR(MAX), GUID NVARCHAR(MAX));

INSERT INTO @RELPROP (RValue, Value, GUID )
SELECT R.Value, PDS.SensorValue, PDS.GUID
FROM [ifcSQL].[cp].[EntityAttributeOfEntityRef] R
JOIN @RELTOT PDS ON R.[GlobalEntityInstanceId] = PDS.GlobalEntityInstanceId

WHERE R.OrdinalPosition=6



-- Step 8: Collect the GlobalEntityInstaceIds of the necessary PSets and store it into the temporary table @PSET

DECLARE @PSET TABLE (GlobalEntityInstanceId NVARCHAR(MAX), Value NVARCHAR(MAX), GUID NVARCHAR(MAX), Pset NVARCHAR(MAX));

INSERT INTO @PSET (GlobalEntityInstanceId, Value, GUID, Pset)
SELECT R.GlobalEntityInstanceId, PDS.Value, PDS.GUID, R.Value
FROM [ifcSQL].[cp].[EntityAttributeOfString] R
JOIN @RELPROP PDS ON R.[GlobalEntityInstanceId] = PDS.RValue
WHERE R.OrdinalPosition=3 and R.Value IN ('Pset_SensorTypeMovementSensor', 'Pset_SensorTypeHumiditySensor', 'Pset_SensorTypeTemperatureSensor', 'Pset_ConstructionOccurence', 'Pset_Condition')     -- The properties are selected based on the interested Pset names



-- Step 9: Select the property single value and insert them into the temporary table @PROPSINGVAL

DECLARE @PROPSINGVAL TABLE (ValueStr NVARCHAR(MAX), Value NVARCHAR(MAX), GUID NVARCHAR(MAX));

INSERT INTO @PROPSINGVAL (ValueStr, Value, GUID)
SELECT R.ValueStr, PDS.Value, PDS.GUID
FROM [ifcSQL].[cp].[EntityAttributeListElement] R
JOIN @PSET PDS ON R.[GlobalEntityInstanceId] = PDS.GlobalEntityInstanceId
WHERE R.OrdinalPosition=5



-- Step 10: Select the properties based on their name and store them into the temporary table @ListOfProperties

DECLARE @ListOfProperties TABLE (GlobalEntityInstanceId NVARCHAR(MAX), Ordinalposition INT, Value NVARCHAR(MAX));

INSERT INTO @ListOfProperties (GlobalEntityInstanceId, Ordinalposition, Value)
SELECT R.GlobalEntityInstanceId, R.OrdinalPosition, R.Value
FROM [ifcSQL].[cp].[EntityAttributeOfString] R
WHERE (R.Value = 'SetPointMovement' AND R.GlobalEntityInstanceId IN 
       (SELECT ValueStr FROM @PROPSINGVAL WHERE Value IN (SELECT Value FROM @PSET WHERE Pset = 'Pset_SensorTypeMovementSensor')))   -- The property SetPointMovement is a property of the Pset_SensorTypeMovementSensor
OR (R.Value = 'SetPointHumidity' AND R.GlobalEntityInstanceId IN 
       (SELECT ValueStr FROM @PROPSINGVAL WHERE Value IN (SELECT Value FROM @PSET WHERE Pset = 'Pset_SensorTypeHumiditySensor')))   -- The property SetPointHumidity is a property of the Pset_SensorTypeHumiditySensor
OR (R.Value = 'SetPointTemperature' AND R.GlobalEntityInstanceId IN 
       (SELECT ValueStr FROM @PROPSINGVAL WHERE Value IN (SELECT Value FROM @PSET WHERE Pset = 'Pset_SensorTypeTemperatureSensor')))  -- The property SetPointTemperature is a property of the Pset_SensorTypeTemperatureSensor
OR (R.Value = 'AssetIdentifier' AND R.GlobalEntityInstanceId IN 
       (SELECT ValueStr FROM @PROPSINGVAL WHERE Value IN (SELECT Value FROM @PSET WHERE Pset = 'Pset_ConstructionOccurence')))  -- The property AssetIdentifier is a property of the Pset_ConstructionOccurence
 OR (R.Value = 'AssessmentDate' AND R.GlobalEntityInstanceId IN 
       (SELECT ValueStr FROM @PROPSINGVAL WHERE Value IN (SELECT Value FROM @PSET WHERE Pset = 'Pset_Condition')))      -- The property AssessmentDate is a property of the Pset_Condition



-- Step 11: Create the @ASSETIDENTIFIER table and insert the relevant data

DECLARE @ASSETIDENTIFIER TABLE ( GUID_Sensor NVARCHAR(MAX),Sensor NVARCHAR(MAX), Pset NVARCHAR(MAX),  Prop NVARCHAR(MAX), Id INT, OrdinalPosition INT, TypeId INT, Value NVARCHAR(MAX));

INSERT INTO @ASSETIDENTIFIER ( GUID_Sensor, Sensor, Pset, Prop, Id, OrdinalPosition, TypeId, Value)
SELECT V.GUID, V.Value, PSET.Pset, T.Value, F.GlobalEntityInstanceId, F.OrdinalPosition, F.TypeId, F.Value 
FROM [ifcSQL].[cp].[EntityAttributeOfString] F
INNER JOIN @ListOfProperties T ON F.GlobalEntityInstanceId = T.GlobalEntityInstanceId
INNER JOIN @PROPSINGVAL V ON V.ValueStr = T.GlobalEntityInstanceId
INNER JOIN @PSET PSET ON PSET.Value = V.Value
WHERE ((T.Value = 'AssetIdentifier' AND PSET.Pset='Pset_ConstructionOccurence') AND (F.OrdinalPosition = 3))



-- Step 12: Create the @ASSESSMENTDATE table and insert the relevant data

DECLARE @ASSESSMENTDATE TABLE ( GUID_Sensor NVARCHAR(MAX),Sensor NVARCHAR(MAX), Pset NVARCHAR(MAX),  Prop NVARCHAR(MAX), Id INT, OrdinalPosition INT, TypeId INT, Value NVARCHAR(MAX));

INSERT INTO @ASSESSMENTDATE ( GUID_Sensor, Sensor, Pset, Prop, Id, OrdinalPosition, TypeId, Value)
SELECT V.GUID, V.Value, PSET.Pset, T.Value, F.GlobalEntityInstanceId, F.OrdinalPosition, F.TypeId, F.Value 
FROM [ifcSQL].[cp].[EntityAttributeOfString] F
INNER JOIN @ListOfProperties T ON F.GlobalEntityInstanceId = T.GlobalEntityInstanceId
INNER JOIN @PROPSINGVAL V ON V.ValueStr = T.GlobalEntityInstanceId
INNER JOIN @PSET PSET ON PSET.Value = V.Value
WHERE ((T.Value = 'AssessmentDate' AND PSET.Pset='Pset_Condition') AND (F.OrdinalPosition = 3))



-- Step 13: Create a summary table of all the properties @FINALPROPERTIES

DECLARE @FINALPROPERTIES TABLE ( GUID_Sensor NVARCHAR(MAX),Sensor NVARCHAR(MAX), Pset NVARCHAR(MAX),  Prop NVARCHAR(MAX), Id INT, OrdinalPosition INT, TypeId INT, Value FLOAT);
INSERT INTO @FINALPROPERTIES ( GUID_Sensor, Sensor, Pset, Prop, Id, OrdinalPosition, TypeId, Value)
SELECT V.GUID, V.Value, PSET.Pset, T.Value, F.GlobalEntityInstanceId, F.OrdinalPosition, F.TypeId, F.Value
FROM [ifcSQL].[cp].[EntityAttributeOfFloat] F 
INNER JOIN @ListOfProperties T ON F.GlobalEntityInstanceId = T.GlobalEntityInstanceId
INNER JOIN @PROPSINGVAL V ON V.ValueStr = T.GlobalEntityInstanceId
INNER JOIN @PSET PSET ON PSET.Value = V.Value
WHERE ((T.Value = 'SetPointMovement' AND PSET.Pset='Pset_SensorTypeMovementSensor') OR (T.Value = 'SetPointTemperature' AND PSET.Pset='Pset_SensorTypeTemperatureSensor') OR (T.Value = 'SetPointHumidity' AND PSET.Pset='Pset_SensorTypeHumiditySensor'));



-- Step 14: Insert the final properties data into the MapTable

INSERT INTO [ifcSQL].[cp].[MapTable] (AssetIdentifier, ID_AD, OP_AD, TID_AD, Date, ID_PROP, OP_PROP, TID_PROP, Prop, Value )
SELECT C.Value, AD.Id, AD.OrdinalPosition, AD.TypeId, AD.Value, FP.Id, FP.OrdinalPosition, FP.TypeId, FP.Prop, FP.Value
FROM @ASSETIDENTIFIER C
INNER JOIN @FINALPROPERTIES FP 
    ON FP.GUID_Sensor = C.GUID_Sensor 
INNER JOIN @ASSESSMENTDATE AD 
    ON FP.GUID_Sensor = AD.GUID_Sensor 
    AND C.GUID_Sensor = AD.GUID_Sensor  
