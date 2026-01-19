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

if /i not "%CURRENTDIR%"=="%TARGETDIR%" (
    echo Moving installer files to %TARGETDIR% ...
    echo.

    if not exist "%TARGETDIR%" (
        mkdir "%TARGETDIR%"
    )

    REM Copy everything first (safer than move)
    xcopy "%CURRENTDIR%\*" "%TARGETDIR%\" /E /H /C /I /Y >nul

    REM Relaunch BAT from target directory
    start "" "%TARGETDIR%\%~nx0"

    REM Exit current instance so files are not locked
    exit /b
)
cd /d "%TARGETDIR%"

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

    echo.
    echo Relaunching installer...
    start "" "%TARGETDIR%\%~nx0"
    exit /b

echo =========================================
echo Microsoft Office LTSC 2021 Setup
echo Running from %CD%
echo =========================================
echo.

REM ---- CONFIG ----
set SETUPURL=https://officecdn.microsoft.com/pr/wsus/setup.exe
set SETUPEXE=%CD%\setup.exe
set CONFIG=%CD%\configuration.xml

REM ---- REQUIRE curl ----
where curl >nul 2>&1
if errorlevel 1 (
    echo ERROR: curl not found. Windows 10+ required.
    pause
    exit /b 1
)

REM ---- DOWNLOAD setup.exe IF MISSING ----
if not exist "%SETUPEXE%" (
    echo Downloading setup.exe...
    echo.

    curl -L --progress-bar "%SETUPURL%" -o "%SETUPEXE%"

    if errorlevel 1 (
        echo.
        echo ERROR: Failed to download setup.exe
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

REM ---- SPINNER ----
set spinner=|/-\
set index=0

:SPINNER
tasklist /fi "imagename eq setup.exe" | find /i "setup.exe" >nul
if errorlevel 1 goto DOWNLOAD_DONE

set /a index=(index+1) %% 4
<nul set /p "=Downloading Office files... !spinner:~%index%,1!`r"
timeout /t 1 >nul
goto SPINNER

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
