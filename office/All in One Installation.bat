@echo off
setlocal EnableDelayedExpansion
title Office LTSC 2021 Installer

REM =====================================================
REM  SELF-RELOCATE TO C:\office IF NOT ALREADY THERE
REM =====================================================

set TARGETDIR=C:\office
set CURRENTDIR=%~dp0
set CURRENTDIR=%CURRENTDIR:~0,-1%
set ODTEXE=officedeploymenttool_17830-20162.exe
set ODTURL=https://github.com/mrgargsir/msofficeLTSC2021/releases/download/21.1/officedeploymenttool_17830-20162.exe

if /i not "%CURRENTDIR%"=="%TARGETDIR%" (
    echo Moving installer file to %TARGETDIR% ...
    echo.

    if not exist "%TARGETDIR%" (
        mkdir "%TARGETDIR%"
    )

    REM Copy only the BAT file itself
    copy "%~f0" "%TARGETDIR%\%~nx0" >nul

    REM Relaunch BAT from target directory
    start "" "%TARGETDIR%\%~nx0"

    REM Exit current instance so files are not locked
    exit /b
)
cd /d "%TARGETDIR%"

REM =====================================================
REM  ENSURE OFFICE DEPLOYMENT TOOL EXISTS
REM =====================================================

if not exist "%TARGETDIR%\%ODTEXE%" (
    echo Office Deployment Tool not found.
    echo Downloading %ODTEXE% ...
    echo.

    REM Check for available download tools (Windows 7 compatible)
    set DOWNLOAD_TOOL=
    
    REM Check for curl first
    where curl >nul 2>&1
    if not errorlevel 1 (
        set DOWNLOAD_TOOL=curl
    ) else (
        REM Check for bitsadmin (Windows 7/8 built-in)
        bitsadmin >nul 2>&1
        if not errorlevel 1 (
            set DOWNLOAD_TOOL=bitsadmin
        ) else (
            REM Check for certutil (Windows built-in)
            certutil >nul 2>&1
            if not errorlevel 1 (
                set DOWNLOAD_TOOL=certutil
            )
        )
    )
    
    if "!DOWNLOAD_TOOL!"=="" (
        echo ERROR: No download tool found.
        echo.
        echo Please install one of these:
        echo 1. Download and install curl from: https://curl.se/windows/
        echo 2. Or download the file manually from:
        echo    !ODTURL!
        echo    And save it to: %TARGETDIR%\%ODTEXE%
        pause
        exit /b 1
    )
    
    echo Using !DOWNLOAD_TOOL! to download...
    
    if "!DOWNLOAD_TOOL!"=="curl" (
        curl -L --progress-bar "%ODTURL%" -o "%TARGETDIR%\%ODTEXE%"
    ) else if "!DOWNLOAD_TOOL!"=="bitsadmin" (
        bitsadmin /transfer ODTDownload /download /priority normal "%ODTURL%" "%TARGETDIR%\%ODTEXE%"
    ) else if "!DOWNLOAD_TOOL!"=="certutil" (
        certutil -urlcache -split -f "%ODTURL%" "%TARGETDIR%\%ODTEXE%"
    )
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download Office Deployment Tool.
        echo Please download manually from:
        echo !ODTURL!
        pause
        exit /b 1
    )

    echo.
    echo Office Deployment Tool downloaded successfully.
    echo.
) else (
    echo Office Deployment Tool already exists. Skipping download.
    echo.
)

echo =========================================
echo Installing Office Deployment Tool
echo =========================================
echo.

if not exist "%ODTEXE%" (
    echo ERROR: %ODTEXE% not found.
    pause
    exit /b 1
)

REM Extract ODT (this creates setup.exe)
"%ODTEXE%" /quiet /extract:"%TARGETDIR%"

if errorlevel 1 (
    echo ERROR: Office Deployment Tool failed.
    pause
    exit /b 1
)

echo ODT installation completed.
echo.

echo =========================================
echo Microsoft Office LTSC 2021 Setup
echo Running from %CD%
echo =========================================
echo.

REM =====================================================
REM  CREATE configuration.xml IF MISSING
REM =====================================================

if not exist "%TARGETDIR%\configuration.xml" (
    echo configuration.xml not found. Creating default configuration...
    echo.

    (
        echo ^<Configuration ID="e42bc234-f06a-4393-91f0-d5998e1bea8f"^>
        echo   ^<Info Description="" /^>
        echo   ^<Add OfficeClientEdition="64" Channel="PerpetualVL2021" MigrateArch="TRUE"^>
        echo     ^<Product ID="Standard2021Volume" PIDKEY="KDX7X-BNVR8-TXXGX-4Q7Y8-78VT3"^>
        echo       ^<Language ID="en-us" /^>
        echo       ^<Language ID="MatchPreviousMSI" /^>
        echo       ^<ExcludeApp ID="OneDrive" /^>
        echo       ^<ExcludeApp ID="OneNote" /^>
        echo       ^<ExcludeApp ID="Outlook" /^>
        echo       ^<ExcludeApp ID="Publisher" /^>
        echo     ^</Product^>
        echo   ^</Add^>
        echo   ^<Property Name="SharedComputerLicensing" Value="0" /^>
        echo   ^<Property Name="FORCEAPPSHUTDOWN" Value="FALSE" /^>
        echo   ^<Property Name="DeviceBasedLicensing" Value="0" /^>
        echo   ^<Property Name="SCLCacheOverride" Value="0" /^>
        echo   ^<Property Name="AUTOACTIVATE" Value="1" /^>
        echo   ^<Updates Enabled="TRUE" /^>
        echo   ^<RemoveMSI /^>
        echo   ^<AppSettings^>
        echo     ^<Setup Name="Company" Value="ssb" /^>
        echo   ^</AppSettings^>
        echo   ^<Display Level="Full" AcceptEULA="TRUE" /^>
        echo ^</Configuration^>
    ) > "%TARGETDIR%\configuration.xml"

    if errorlevel 1 (
        echo ERROR: Failed to create configuration.xml
        pause
        exit /b 1
    )

    echo configuration.xml created successfully.
    echo.
)

REM ---- CONFIG ----
set SETUPURL=https://officecdn.microsoft.com/pr/wsus/setup.exe
set SETUPEXE=%CD%\setup.exe
set CONFIG=%CD%\configuration.xml

REM ---- DOWNLOAD setup.exe IF MISSING (Windows 7 compatible) ----
if not exist "%SETUPEXE%" (
    echo Downloading setup.exe...
    echo.

    REM Check for available download tools
    set DOWNLOAD_TOOL=
    
    where curl >nul 2>&1
    if not errorlevel 1 (
        set DOWNLOAD_TOOL=curl
    ) else (
        bitsadmin >nul 2>&1
        if not errorlevel 1 (
            set DOWNLOAD_TOOL=bitsadmin
        ) else (
            certutil >nul 2>&1
            if not errorlevel 1 (
                set DOWNLOAD_TOOL=certutil
            )
        )
    )
    
    if "!DOWNLOAD_TOOL!"=="" (
        echo ERROR: No download tool found for setup.exe.
        echo Please download manually from:
        echo !SETUPURL!
        echo And save to: !SETUPEXE!
        pause
        exit /b 1
    )
    
    echo Using !DOWNLOAD_TOOL! to download setup.exe...
    
    if "!DOWNLOAD_TOOL!"=="curl" (
        curl -L --progress-bar "%SETUPURL%" -o "%SETUPEXE%"
    ) else if "!DOWNLOAD_TOOL!"=="bitsadmin" (
        bitsadmin /transfer SetupDownload /download /priority normal "%SETUPURL%" "%SETUPEXE%"
    ) else if "!DOWNLOAD_TOOL!"=="certutil" (
        certutil -urlcache -split -f "%SETUPURL%" "%SETUPEXE%"
    )
    
    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download setup.exe
        echo Please download manually from:
        echo !SETUPURL!
        pause
        exit /b 1
    )
) else (
    echo setup.exe already exists. Skipping download.
)

echo.
echo =========================================
echo Downloading Office files (please wait)
echo =========================================
echo.

REM ---- START OFFICE DOWNLOAD IN BACKGROUND ----
start "" /b "%SETUPEXE%" /download "%CONFIG%"

REM 👉 SIMPLIFIED: Show downloaded data size instead of speed
set spinner=^|/-\
set index=0
set downloaded_size=0
set formatted_size=0 KB

REM 👉 Get initial Office folder size for tracking
if exist "%TARGETDIR%\Office" (
    for /f "tokens=3" %%a in ('dir /s /-c "%TARGETDIR%\Office" 2^>nul ^| find "File(s)"') do set "downloaded_size=%%a"
    set "downloaded_size=!downloaded_size:,=!"
    call :FORMAT_SIZE
) else (
    set downloaded_size=0
    set formatted_size=0 KB
)

:SPINNER
REM Check if setup.exe is still running
tasklist /fi "imagename eq setup.exe" 2>nul | find /i "setup.exe" >nul
if errorlevel 1 goto DOWNLOAD_DONE

REM 👉 Get current Office folder size
set current_size=0
if exist "%TARGETDIR%\Office" (
    for /f "tokens=3" %%a in ('dir /s /-c "%TARGETDIR%\Office" 2^>nul ^| find "File(s)"') do set "current_size=%%a"
    set "current_size=!current_size:,=!"
    
    REM Update if size changed
    if !current_size! neq !downloaded_size! (
        set downloaded_size=!current_size!
        call :FORMAT_SIZE
    )
) else (
    set downloaded_size=0
    set formatted_size=0 KB
)

REM 👉 Get spinner character
if !index!==0 (
    set spinchar=^|
) else if !index!==1 (
    set spinchar=/
) else if !index!==2 (
    set spinchar=-
) else if !index!==3 (
    set spinchar=\
)

REM 👉 Display spinner with downloaded size
<nul set /p "=Downloading Office files... !spinchar! Downloaded: !formatted_size!         "
echo.

REM 👉 Increment index and wrap around
set /a index=!index!+1
if !index!==4 set index=0

timeout /t 1 >nul
goto SPINNER

:FORMAT_SIZE
REM 👉 Format size to KB, MB, or GB
set formatted_size=!downloaded_size! B

if !downloaded_size! gtr 1024 (
    set /a kb_size=downloaded_size / 1024
    set formatted_size=!kb_size! KB
    
    if !kb_size! gtr 1024 (
        set /a mb_size=kb_size / 1024
        set formatted_size=!mb_size! MB
        
    )
)
exit /b

:DOWNLOAD_DONE
echo.
echo Office download completed.
echo.

REM ---- RUN INSTALL ----
echo =========================================
echo Starting Office installation
echo =========================================
echo.

"%SETUPEXE%" /configure "%CONFIG%"

if errorlevel 1 (
    echo.
    echo ERROR: Installation failed.
    pause
    exit /b 1
)

echo.
echo =========================================
echo Office installed successfully
echo =========================================
pause