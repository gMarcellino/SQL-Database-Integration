# SQL Database Integration Framework for IFC-Based BIM and SHM Systems  

## General Information  
This research proposes a framework for integrating data between SQL databases from different platforms, such as **Microsoft SQL Server (MSSQL)** and **MySQL**. The goal is to ensure system compatibility and facilitate the exchange and synchronization of information, particularly in **Building Information Modeling (BIM)** and **Structural Health Monitoring (SHM)** applications.  

## Case Study  
The proposed framework enables the synchronization of an **IFC-based database** (generated using the [ifcSQL](https://github.com/IfcSharp/IfcSQL) project) in **MSSQL Server** with an **external MySQL database** that stores real-time SHM sensor data. The scripts provided in this repository are part of the framework, which is detailed in a conference paper.  

## Objectives  
This work aims to develop a framework that integrates **real-time sensor data with BIM using the IFC standard**. The research focuses on utilizing **relational SQL databases** across different platforms and establishing seamless communication between them. The **IFC communication standard** serves as both the starting and ending point for managing and visualizing information.  

---

## Framework Overview  
The framework consists of the following **four phases**:  

### Phase 1: Database Analysis  
The databases involved in this study are **relational SQL databases** that were pre-generated using external scripts (not part of this study).  

- **IFC Database (ifcSQL):**  
  The **ifcSQL database** stores **IFC-based models**, including all data schemas defined by **buildingSMART International**. It was created following the [official GitHub guide](https://github.com/IfcSharp/IfcSQL).  

- **Sensor Database (MySQL):**  
  Sensor data is collected and stored in a **MySQL database**, which is **updated every hour** with real-time SHM information.  

### Phase 2: Database Integration  
The integration of the two databases is performed within **Microsoft SQL Server**, where the **ifcSQL database** resides. This enables efficient synchronization between the **IFC database** and the **sensor database**.  

To achieve this, two SQL scripts are executed in **MSSQL Server**:  
1. **`MapTable_Creation.sql`** – Creates mapping tables to link the IFC model with sensor data.  
2. **`DatabaseUpdate.sql`** – Updates the IFC database with the latest sensor readings.  

An overview of the general connection between the scripts is shown in the repository.  

### Phase 3: Automation with Batch Scripts  
To fully automate the data exchange process, a **batch script** is used. It sequentially executes the following commands:  

```bash
1. Run MapTable_Creation.sql  
2. Run DatabaseUpdate.sql  
3. Run the C# script SQLtoIFC  
