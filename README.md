# SQL Database Integration

## General Information  
This research proposes a framework for integrating data between SQL databases from different platforms, such as Microsoft SQL Server (MSSQL) and MySQL.    
The goal is to ensure system compatibility and facilitate the exchange and synchronization of information, particularly in Building Information Modeling (BIM) and other sources.  

### Case Study  
The proposed framework enables the synchronization of an IFC-based database (generated using the [ifcSQL](https://github.com/IfcSharp/IfcSQL) project) in MSSQL Server with an external MySQL database that stores real-time SHM sensor data. 
The scripts provided in this repository are part of the framework, which is detailed in a conference paper.    

### Objectives 
This work aims to develop a framework that integrates real-time sensor data with BIM using the IFC standard. The research focuses on utilizing relational SQL databases across different platforms and establishing seamless communication between them. The IFC communication standard serves as both the starting and ending point for managing and visualizing information.  


## Framework Overview  
The framework consists of the following four phases:  
<img src="https://github.com/gMarcellino/SQL-Database-Integration/blob/main/image/Framework.jpg" alt="Framework" width="600" />

### Phase 1: Database Analysis  
The databases involved in this study are relational SQL databases that were pre-generated using external scripts (not part of this study).  

- **IFC Database (ifcSQL)**  
  The ifcSQL database stores IFC-based models, including all data schemas defined by buildingSMART International. It was created following the [official GitHub guide](https://github.com/IfcSharp/IfcSQL).  

- **Sensor Database (MySQL)**  
  Sensor data is collected and stored in a MySQL database, which is updated every hour with real-time SHM information.  

### Phase 2: Database Integration  
The integration of the two databases is performed within Microsoft SQL Server, where the ifcSQL database resides. This enables efficient synchronization between the IFC database and the sensor database.  

To achieve this, two SQL scripts are executed in MSSQL Server:  
1. `MapTable_Creation.sql` – Creates mapping tables to link the IFC model with sensor data.  
2. `DatabaseUpdate.sql` – Updates the IFC database with the latest sensor readings.  
The scripts are reported into the repository.

An overview of the general connection between the scripts is shown:
<img src="https://github.com/gMarcellino/SQL-Database-Integration/blob/main/image/Map.jpeg" alt="Map" width="600" />


### Phase 3: Ifc update 
To fully automate the data exchange process, a batch script `PCtoServer.bat` is used.
This file contains a series of commands executed sequentially, namely MapTable_Creation.sql, DatabaseUpdate.sql, and finally the C# script SQLtoIFC. The file is reported in the repository.

### Phase 4: Updated IFC Model
At the end of the process, the IFC file is updated and stored on the server, ready for further analysis and visualization.


---


## Repository Contents
This repository includes the following files:

- **SQL Scripts**:
`MapTable_Creation.sql` – Mapping table creation.
`DatabaseUpdate.sql` – Database synchronization.
- **Batch File**:
`PCtoServer.bat` - Automates the execution of all scripts.

## How to Use
1. Ensure that Microsoft SQL Server and MySQL are installed and configured.
2. Run the SQL scripts in Microsoft SQL Server.
3. Execute the batch script.
The updated IFC file will be generated and stored on the server.


---

## Other applications
The scripts provided are specific to the case study. However, they can be easily modified to be applied to other areas (e.g., energy, degradation, etc.).
Below are some changes to apply for generalization:

1. **MAPTABLE_CREATION.SQL**
Line 20
Modify the ID with the one generated in the SelectProject table of the ifcSQL script.
Line 31-42
You can insert all the columns you need, each for the respective property you want to report. For each property, it is important to print both the TID (TypeId) and the value.
Line 60
You can replace “IFCSENSOR” with any other IFC class whose properties you want to link. For example, IFCWALL.
Line 135
You can select the relevant Psets based on your needs.
Line 158-167
It is necessary to modify the properties contained within the Psets if they were changed in the previous section.
Line 173-181 and 187-195
The tables must be kept if the elements are recognized via AssetIdentifier and if the date information is required. Additional tables can be added, constructed in a similar way.
Line 208
It is necessary to modify the properties contained within the Psets if they were modified in lines 158-167.

2. **DATABASEUPDATE.SQL**
Line 20
Modify the ID with the one generated in the SelectProject table of the ifcSQL script.
Line 26-34
You need to modify the columns of the SENSORTABLE based on the structure of the database table you want to link. Additionally, you need to insert the name of the database.
Keep lines 31-34 if you want the most recent data.
Line 42-56
In these lines, the connection between MapTable and SensorTable is made using the same AssetIdentifier and the same property names. You can modify this.



