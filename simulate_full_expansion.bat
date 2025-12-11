@echo off
setlocal EnableDelayedExpansion

REM Configuration
set "START_FILE=layer0.zip"
set "MAX_CYCLES=5"
set "OUTPUT_DIR=full_expansion_zone"

REM Parse command line arguments
if not "%~1"=="" set "START_FILE=%~1"
if not "%~2"=="" set "MAX_CYCLES=%~2"

echo.
echo 💣 Starting FULL Expansion Simulation (keeping all files)...
echo ---------------------------------------------

REM Check if start file exists
if not exist "%START_FILE%" (
    echo Error: %START_FILE% not found. Run the C generator first.
    exit /b 1
)

REM Create output directory
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

REM Copy start file
copy /Y "%START_FILE%" "%OUTPUT_DIR%\" >nul
cd /d "%OUTPUT_DIR%"

set "CURRENT_CYCLE=0"

:EXTRACT_LOOP

REM Count unprocessed zip files
set "ZIP_COUNT=0"
for /r %%F in (*.zip) do (
    set "FILENAME=%%~nxF"
    echo !FILENAME! | findstr /i "\.extracted$" >nul
    if errorlevel 1 (
        set /a ZIP_COUNT+=1
    )
)

if %ZIP_COUNT%==0 goto COMPLETE

if %CURRENT_CYCLE% GEQ %MAX_CYCLES% (
    echo 🛑 Safety limit reached ^(%MAX_CYCLES% cycles^). Stopping simulation.
    goto COMPLETE
)

echo [Cycle %CURRENT_CYCLE%] Found %ZIP_COUNT% archives. Extracting...

REM Extract all unprocessed zip files
for /r %%F in (*.zip) do (
    set "ZIPFILE=%%F"
    set "FILENAME=%%~nxF"
    set "BASENAME=%%~nF"
    set "DIRNAME=%%~dpF"
    
    echo !FILENAME! | findstr /i "\.extracted$" >nul
    if errorlevel 1 (
        set "EXTRACT_DIR=!DIRNAME!!BASENAME!_contents"
        
        if not exist "!EXTRACT_DIR!" mkdir "!EXTRACT_DIR!"
        
        echo    Extracting !FILENAME! into !BASENAME!_contents...
        
        REM Use tar (built into Windows 10+) for extraction
        tar -xf "!ZIPFILE!" -C "!EXTRACT_DIR!" 2>nul
        
        if !errorlevel! equ 0 (
            ren "!ZIPFILE!" "!FILENAME!.extracted"
        ) else (
            echo     Warning: Failed to extract !FILENAME!
        )
    )
)

REM Calculate statistics
set "TXT_COUNT=0"
set "ZIP_REMAINING=0"
set "TOTAL_FILES=0"

for /r %%F in (*.*) do set /a TOTAL_FILES+=1
for /r %%F in (*.txt) do set /a TXT_COUNT+=1
for /r %%F in (*.zip) do (
    set "FILENAME=%%~nxF"
    echo !FILENAME! | findstr /i "\.extracted$" >nul
    if errorlevel 1 set /a ZIP_REMAINING+=1
)

REM Get folder size (approximate)
set "FOLDER_SIZE=Calculating..."
for /f "tokens=3" %%A in ('dir /s /-c ^| findstr /c:"bytes"') do set "FOLDER_SIZE=%%A"

echo     Status: Total files: %TOTAL_FILES%
echo     Files: %TXT_COUNT% text files, %ZIP_REMAINING% zips remaining

set /a CURRENT_CYCLE+=1
echo ---------------------------------------------

REM Small delay
timeout /t 1 /nobreak >nul

goto EXTRACT_LOOP

:COMPLETE

REM Final statistics
echo.
echo ✅ Simulation complete.
echo.
echo 📊 Final Statistics:

set "TOTAL_FILES=0"
set "TXT_COUNT=0"
set "EXTRACTED_COUNT=0"

for /r %%F in (*.*) do set /a TOTAL_FILES+=1
for /r %%F in (*.txt) do set /a TXT_COUNT+=1
for /r %%F in (*.extracted) do set /a EXTRACTED_COUNT+=1

echo    Total files: %TOTAL_FILES%
echo    Text files: %TXT_COUNT%
echo    Processed zips: %EXTRACTED_COUNT%
echo.
echo    Location: %CD%

endlocal
