:: 1. Define Variables
set "JAR_NAME=Authorisation-0.0.1-SNAPSHOT.jar"
set "WORKSPACE_DIR=C:\ProgramData\Jenkins\.jenkins\workspace\b2b-qa-auth-migration\target"
set "DEPLOY_DIR=D:\JenkinsBuilds\b2b"
set "SERVICE_NAME=API-AUTH-B2B"
set "JAVA_PATH=C:\Program Files\Java\jdk-21\bin\java.exe"
set "NSSM_PATH=C:\Users\SRK\Downloads\nssm-2.24\nssm-2.24\win64\nssm.exe"  

:: 2. Move the JAR file to the deployment directory
echo Moving JAR to deployment directory...
move "%WORKSPACE_DIR%\%JAR_NAME%" "%DEPLOY_DIR%"
if %errorlevel% neq 0 (
    echo Failed to move JAR file. Check if the source and destination paths are correct.
    exit /b 1
)

:: 3. Stop the service if it is running
echo Checking if the service %SERVICE_NAME% is running...
sc query "%SERVICE_NAME%" | findstr /C:"RUNNING" >nul
if %errorlevel% equ 0 (
    echo Service is running, stopping it...
    net stop "%SERVICE_NAME%"
    timeout /t 5
) else (
    echo Service is not running, no need to stop.
)

:: 4. Remove and reinstall the service using NSSM
echo Reinstalling the service %SERVICE_NAME%...
sc query "%SERVICE_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    echo Service %SERVICE_NAME% exists, removing it...
    "%NSSM_PATH%" remove "%SERVICE_NAME%" confirm
    timeout /t 3
)

:: Install the service with the new JAR
"%NSSM_PATH%" install "%SERVICE_NAME%" "%JAVA_PATH%" -jar "%DEPLOY_DIR%\%JAR_NAME%" 
if %errorlevel% neq 0 (
    echo Failed to install the service using NSSM.
    exit /b 1
)



:: Configure logging for the service
echo Configuring log files for the service...
"%NSSM_PATH%" set "%SERVICE_NAME%" AppStdout "%DEPLOY_DIR%\b2b_auth.log"



:: 5. Start the service
echo Starting service %SERVICE_NAME%...
net start "%SERVICE_NAME%"
if %errorlevel% neq 0 (
    echo Failed to start service %SERVICE_NAME%.
    exit /b 1
)