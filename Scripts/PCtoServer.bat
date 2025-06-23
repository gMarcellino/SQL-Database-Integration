@echo off

:: ========================================================================
:: GENERAL INFORMATION
::
:: This script automates the process of updating an IFC file on a server.
:: It uses components from the ifcSQL project, so paths should be adjusted
:: accordingly. Required tools include:
:: - Microsoft SQL Server (with sqlcmd)
:: - Visual Studio (with MSBuild)
:: - WinSCP (for file transfer)
::
:: Update the variables in STEP 0 according to your environment.
:: ========================================================================


:: STEP 0: USER CONFIGURATION (Edit these paths and credentials)

:: SQL Server
set "SQLCMD_PATH=C:\Path\To\sqlcmd.exe"
set "SQL_SERVER=YourSQLServer"
set "SQL_DATABASE=ifcSQL"

:: Solution and Build Tools
set "SLN_FILE=C:\Path\To\Your\Project\from_ifcSQL.sln"
set "MSBUILD_PATH=C:\Path\To\MSBuild.exe"
set "EXE_FILE=C:\Path\To\Built\Executable\from_ifcSQL_IFC4X3_ADD2.exe"

:: SQL script
set "SQL_FILE1=C:\Path\To\Your\SQLScript\DatabaseUpdate.sql"

:: IFC file and WinSCP settings
set "FILE_LOCAL=C:\Path\To\IFCFile\SQLArena.ifc"
set "FILE_REMOTE=/remote/server/path/"
set "WINSCP_PATH=C:\Path\To\WinSCP\winscp.com"

:: FTP credentials (Do NOT hardcode in public repositories!)
set "SERVER_HOST=yourserverhost.com"
set "USERNAME=yourusername"
set "PASSWORD=yoursecretpassword"
set "PORTA=21"    :: Default FTP port, change if needed


:: STEP 1: Validate sqlcmd availability

if not exist "%SQLCMD_PATH%" (
    echo sqlcmd not found: %SQLCMD_PATH%
    pause
    exit /b 1
)


:: STEP 2: Execute SQL script

echo Executing SQL script: %SQL_FILE1%
"%SQLCMD_PATH%" -S %SQL_SERVER% -d %SQL_DATABASE% -E -i "%SQL_FILE1%"
if errorlevel 1 (
    echo Error executing SQL script: %SQL_FILE1%.
    pause
    exit /b 1
)


:: STEP 3: Build the Visual Studio solution

echo Building the solution file...
"%MSBUILD_PATH%" "%SLN_FILE%" /t:Build /p:Configuration=Release
if errorlevel 1 (
    echo Error building the solution. Exiting script.
    pause
    exit /b 1
)
echo Build completed successfully.


:: STEP 4: Run the compiled executable

if exist "%EXE_FILE%" (
    echo Running the compiled application...
    "%EXE_FILE%"
    if errorlevel 1 (
        echo Error while running the application.
        pause
        exit /b 1
    )
) else (
    echo Executable not found: %EXE_FILE%
    pause
    exit /b 1
)


:: STEP 5: Transfer the updated IFC file via WinSCP

"%WINSCP_PATH%" ^
  /command ^
  "option batch on" ^
  "option confirm off" ^
  "open ftp://%USERNAME%:%PASSWORD%@%SERVER_HOST%:%PORTA%" ^
  "put %FILE_LOCAL% %FILE_REMOTE%" ^
  "exit"

echo File transfer completed.
pause
