; NSIS Script for Zipbomb Simulator
; This script launches the PowerShell simulation in a hidden window
; and performs cleanup after completion

!define PRODUCT_NAME "Zipbomb Simulator"
!define PRODUCT_VERSION "1.0"
!define SCRIPT_NAME "simulate_full_expansion.ps1"

; Include LogicLib for conditional statements
!include "LogicLib.nsh"

; General Settings
Name "${PRODUCT_NAME}"
OutFile "ZipbombSimulator.exe"
ShowInstDetails hide
SilentInstall silent
RequestExecutionLevel user

; Main Section
Section "MainSection" SEC01
    ; Set working directory to where the exe is located
    InitPluginsDir
    SetOutPath "$EXEDIR"
    
    ; Execute PowerShell script in hidden window and WAIT for completion
    ; Using nsExec::ExecToLog to wait for the process to finish
    DetailPrint "Starting zip bomb simulation..."
    nsExec::ExecToLog 'powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "$EXEDIR\${SCRIPT_NAME}"'
    Pop $0 ; Get return code
    
    ; Check if execution was successful
    ${If} $0 == 0
        DetailPrint "Simulation completed successfully. Starting cleanup..."
    ${Else}
        DetailPrint "Simulation completed with code $0. Starting cleanup anyway..."
    ${EndIf}
    
    ; Cleanup Phase
    DetailPrint "Deleting nssm folder..."
    RMDir /r "$EXEDIR\nssm"
    
    DetailPrint "Deleting layer0.zip..."
    Delete "$EXEDIR\layer0.zip"
    
    DetailPrint "Deleting full_expansion_zone folder..."
    RMDir /r "$EXEDIR\full_expansion_zone"
    
    DetailPrint "Deleting simulate_full_expansion file..."
    Delete "$EXEDIR\simulate_full_expansion.ps1"

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
    
    ; Execute the cleanup batch in hidden mode
    Exec '"$TEMP\cleanup_zipbomb.bat"'
    
    DetailPrint "Self-destruct initiated. Exiting..."
    
SectionEnd

; Initialization function
Function .onInit
    ; Set silent mode
    SetSilent silent
FunctionEnd