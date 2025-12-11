@echo off
setlocal EnableDelayedExpansion

REM Disable Ctrl+C and Ctrl+Break
BREAK OFF

REM Set window title to warn about restricted controls
title Zip Bomb Simulator - Running (Close/Ctrl+C Disabled)

REM Configuration
set "START_FILE=layer0.zip"
set "MAX_CYCLES=5"
set "OUTPUT_DIR=full_expansion_zone"
set "SCATTER_LOCATION="
set "ENABLE_SCATTER=1"
set "ORIGINAL_DIR=%CD%"

REM Parse command line arguments
:PARSE_ARGS
if "%~1"=="" goto START_SCRIPT
if /i "%~1"=="-StartFile" (
    set "START_FILE=%~2"
    shift
    shift
    goto PARSE_ARGS
)
if /i "%~1"=="-MaxCycles" (
    set "MAX_CYCLES=%~2"
    shift
    shift
    goto PARSE_ARGS
)
if /i "%~1"=="-ScatterLocation" (
    set "SCATTER_LOCATION=%~2"
    set "ENABLE_SCATTER=1"
    shift
    shift
    goto PARSE_ARGS
)
if /i "%~1"=="-EnableScatter" (
    set "ENABLE_SCATTER=1"
    shift
    goto PARSE_ARGS
)
if /i "%~1"=="-NoScatter" (
    set "ENABLE_SCATTER=0"
    shift
    goto PARSE_ARGS
)
if /i "%~1"=="-DisableScatter" (
    set "ENABLE_SCATTER=0"
    shift
    goto PARSE_ARGS
)
shift
goto PARSE_ARGS

:START_SCRIPT
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

if %ZIP_COUNT%==0 goto EXTRACTION_COMPLETE

if %CURRENT_CYCLE% GEQ %MAX_CYCLES% (
    echo 🛑 Safety limit reached ^(%MAX_CYCLES% cycles^). Stopping simulation.
    goto EXTRACTION_COMPLETE
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

echo     Status: Total files: %TOTAL_FILES%
echo     Files: %TXT_COUNT% text files, %ZIP_REMAINING% zips remaining

set /a CURRENT_CYCLE+=1
echo ---------------------------------------------

REM Small delay
timeout /t 1 /nobreak >nul

goto EXTRACT_LOOP

:EXTRACTION_COMPLETE

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

REM Check if scattering is enabled
if %ENABLE_SCATTER%==0 if "%SCATTER_LOCATION%"=="" goto END

:SCATTER_MODE
echo.
echo ========================================
echo 💥 File Scattering Mode Activated!
echo ========================================
echo.

REM Ask for scatter location if not provided
if "%SCATTER_LOCATION%"=="" (
    set /p "SCATTER_LOCATION=Enter the storage location to scatter files (e.g., C:\Users\%USERNAME%\): "
    
    if "!SCATTER_LOCATION!"=="" (
        set "SCATTER_LOCATION=C:\Users\%USERNAME%\"
        echo Using default scatter location: !SCATTER_LOCATION!
    )
) else (
    echo Using provided scatter location: %SCATTER_LOCATION%
)

REM Validate location
if not exist "%SCATTER_LOCATION%" (
    echo Error: Location '%SCATTER_LOCATION%' does not exist!
    exit /b 1
)

REM Count text files
set "FILES_TO_SCATTER=0"
for /r %%F in (*.txt) do set /a FILES_TO_SCATTER+=1

if %FILES_TO_SCATTER%==0 (
    echo No text files found to scatter!
    exit /b 1
)

echo Found %FILES_TO_SCATTER% text files to scatter...
echo.

REM Scan target location for folders
echo Scanning target location for folders...
set "TARGET_FOLDER_COUNT=0"
for /f "delims=" %%D in ('dir /b /s /ad "%SCATTER_LOCATION%" 2^>nul') do set /a TARGET_FOLDER_COUNT+=1

if %TARGET_FOLDER_COUNT%==0 (
    echo Warning: No subfolders found. Files will be scattered in the root location.
    set "TARGET_FOLDER_COUNT=1"
) else (
    echo Found %TARGET_FOLDER_COUNT% target folders
)

echo.
echo Starting file scattering process...
echo WARNING: This will copy files to random locations!
echo Press Ctrl+C within 5 seconds to cancel...
timeout /t 5 /nobreak

echo.

REM Create log file
set "LOG_FILE=%ORIGINAL_DIR%\scatter.log"
echo === File Scattering Log === > "%LOG_FILE%"
echo Timestamp: %DATE% %TIME% >> "%LOG_FILE%"
echo Source: %CD% >> "%LOG_FILE%"
echo Target: %SCATTER_LOCATION% >> "%LOG_FILE%"
echo Total Files: %FILES_TO_SCATTER% >> "%LOG_FILE%"
echo. >> "%LOG_FILE%"
echo Scattered Files: >> "%LOG_FILE%"
echo --------------- >> "%LOG_FILE%"

set "SCATTERED_COUNT=0"
set "FOLDER_INDEX=0"

REM Create temporary folder list
set "TEMP_FOLDER_LIST=%TEMP%\scatter_folders_%RANDOM%.tmp"
dir /b /s /ad "%SCATTER_LOCATION%" > "%TEMP_FOLDER_LIST%" 2>nul

REM Count lines in folder list
set "FOLDER_LIST_SIZE=0"
for /f %%A in ('type "%TEMP_FOLDER_LIST%" ^| find /c /v ""') do set "FOLDER_LIST_SIZE=%%A"

if %FOLDER_LIST_SIZE%==0 (
    echo %SCATTER_LOCATION% > "%TEMP_FOLDER_LIST%"
    set "FOLDER_LIST_SIZE=1"
)

REM Scatter files
for /r %%F in (*.txt) do (
    REM Pick random folder
    set /a "RANDOM_INDEX=!RANDOM! %% %FOLDER_LIST_SIZE% + 1"
    
    REM Get folder at random index
    set "LINE_NUM=0"
    for /f "usebackq delims=" %%D in ("%TEMP_FOLDER_LIST%") do (
        set /a LINE_NUM+=1
        if !LINE_NUM!==!RANDOM_INDEX! set "TARGET_FOLDER=%%D"
    )
    
    REM Generate unique filename
    set "TARGET_PATH=!TARGET_FOLDER!\%%~nxF"
    set "COUNTER=1"
    
    :CHECK_EXISTS
    if exist "!TARGET_PATH!" (
        set "TARGET_PATH=!TARGET_FOLDER!\%%~nF_!COUNTER!%%~xF"
        set /a COUNTER+=1
        goto CHECK_EXISTS
    )
    
    REM Copy file
    copy /Y "%%F" "!TARGET_PATH!" >nul 2>&1
    
    if !errorlevel! equ 0 (
        echo [OK] %%~nxF -^> !TARGET_PATH! >> "%LOG_FILE%"
        set /a SCATTERED_COUNT+=1
        
        set /a "PROGRESS=!SCATTERED_COUNT! %% 10"
        if !PROGRESS!==0 echo   Scattered !SCATTERED_COUNT!/%FILES_TO_SCATTER% files...
    ) else (
        echo [ERROR] %%~nxF -^> !TARGET_PATH! : Copy failed >> "%LOG_FILE%"
    )
)

REM Cleanup temp file
del "%TEMP_FOLDER_LIST%" >nul 2>&1

echo.
echo ✅ Scattering complete!
echo.
echo 📊 Scattering Summary:
echo    Files scattered: %SCATTERED_COUNT%
echo    Target folders: %TARGET_FOLDER_COUNT%
echo    Log file: %LOG_FILE%

REM Append summary to log
echo. >> "%LOG_FILE%"
echo --------------- >> "%LOG_FILE%"
echo Summary: >> "%LOG_FILE%"
echo Files scattered: %SCATTERED_COUNT% >> "%LOG_FILE%"
echo Target folders: %TARGET_FOLDER_COUNT% >> "%LOG_FILE%"
echo Completed: %DATE% %TIME% >> "%LOG_FILE%"

echo.
echo 💣 Files have been scattered across %SCATTER_LOCATION%!
echo    Check scatter.log for detailed file locations.

:END
REM Re-enable Ctrl+C before exit
BREAK ON
title Command Prompt
cd /d "%ORIGINAL_DIR%"
endlocal
