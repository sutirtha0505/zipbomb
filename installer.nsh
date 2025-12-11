; NSIS Script for Zipbomb Simulator
; This script launches the PowerShell simulation in a hidden window

!define PRODUCT_NAME "Zipbomb Simulator"
!define PRODUCT_VERSION "1.0"
!define SCRIPT_NAME "simulate_full_expansion.ps1"

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
    
    ; Execute PowerShell script in hidden window
    ; Using ShellExecuteEx with SW_HIDE flag
    ExecShell "" "powershell.exe" '-WindowStyle Hidden -ExecutionPolicy Bypass -NoProfile -File "$EXEDIR\${SCRIPT_NAME}"' SW_HIDE
    
SectionEnd

; Initialization function
Function .onInit
    ; Set silent mode
    SetSilent silent
FunctionEnd