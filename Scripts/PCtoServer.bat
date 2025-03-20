:: GENERAL INFORMATION

:: This script is used to automate the process of updating the IFC file on the server.
:: Some of the files are from ifcSQL project, so the path is set to the project folder.

:: In the script are used some programs and tools that must be installed on the machine or similar (Winscp, Visual Studio, etc.). 


@echo off



:: Step 1: Set path for files and tools

set "SLN_FILE=C:\Users\giorgia\Desktop\Publications\2025\EC3\SQLArena\IfcSQL_Arena\IfcSharpApps\IfcSql\from_ifcSQL\from_ifcSQL.sln"
set "MSBUILD_PATH=C:\Program Files\Microsoft Visual Studio\2022\Professional\MSBuild\Current\Bin\amd64\MSBuild.exe"
set "EXE_FILE=C:\Users\giorgia\Desktop\Publications\2025\EC3\SQLArena\IfcSQL_Arena\IfcSharpApps\IfcSql\from_ifcSQL\bin\Release\from_ifcSQL_IFC4X3_ADD2.exe"

echo Compiling the .sln file...
"%MSBUILD_PATH%" "%SLN_FILE%" /t:Build /p:Configuration=Release
if errorlevel 1 (
    echo  Error during solution compilation. Script execution aborted.
    pause
    exit /b 1
)

echo Compilation completed successfully.



:: Step 2: Execute the generated application

if exist "%EXE_FILE%" (
    echo Running the generated application..
    "%EXE_FILE%"
    if errorlevel 1 (
        echo Error while running the application.
        pause
        exit /b 1
    )
) else (
    echo Unable to find the generated executable: %EXE_FILE%
    pause
    exit /b 1
)



:: Step 3: Set variables for WinSCP file transfer

:: Set the local and remote file paths
set "FILE_LOCAL=C:\Users\giorgia\Desktop\Publications\2025\EC3\SQLArena\SQLArena.ifc"
set "FILE_REMOTE=/Publications/2025/EC3/SQLArena/Ifc/"
set "WINSCP_PATH=C:\Program Files (x86)\WinSCP\winscp.com"

:: Set the FTP server connection parameters
:: The value are not written due to privacy. Replace the values with your own
set "SERVER_HOST=yourserverhost.com"
set "USERNAME=yourusername"
set "PASSWORD=yoursecretpassword"
set "PORTA=yourserverport" 



:: Step 4: Execute direct file transfer using WinSCP

"%WINSCP_PATH%" ^
  /command ^
  "open ftp://%USERNAME%:%PASSWORD%@%SERVER_HOST%:%PORTA%" ^
  "put %FILE_LOCAL% %FILE_REMOTE%" ^
  "exit"

echo File transfer completed.
pause
