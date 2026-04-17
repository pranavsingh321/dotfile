@echo off
setlocal

echo Checking GlazeWM...

:: ----------------------------
:: START GLAZEWM IF NOT RUNNING
:: ----------------------------
tasklist | find /i "glazewm" >nul
if errorlevel 1 (
    echo Starting GlazeWM...
    start "" "glazewm"
    timeout /t 3 >nul
)

echo Waiting for GlazeWM to stabilize...
timeout /t 5 >nul

:: ----------------------------
:: DO NOT FORCE WORKSPACE FOCUS (reduces flicker)
:: Let GlazeWM rules handle placement
:: ----------------------------

echo Launching apps...

:: =====================================================
:: WORKSPACE 1 - TERMINAL
:: =====================================================
glazewm command focus --workspace 1
timeout /t 1 >nul
start "" wt
timeout /t 2 >nul


:: =====================================================
:: WORKSPACE 2 - BRAVE
:: =====================================================
glazewm command focus --workspace 2
timeout /t 1 >nul
start "" brave
timeout /t 5 >nul


:: =====================================================
:: WORKSPACE 3 - EXPLORER
:: =====================================================
glazewm command focus --workspace 3
timeout /t 1 >nul
start "" explorer
timeout /t 5 >nul


:: =====================================================
:: WORKSPACE 4 - OUTLOOK
:: =====================================================
glazewm command focus --workspace 4
timeout /t 1 >nul
start "" outlook
timeout /t 15 >nul


:: =====================================================
:: WORKSPACE 5 - TEAMS
:: =====================================================
glazewm command focus --workspace 5
timeout /t 1 >nul
start "" ms-teams
timeout /t 10 >nul


:: =====================================================
:: WORKSPACE 8 - CHROME
:: =====================================================
glazewm command focus --workspace 8
timeout /t 1 >nul
start "" chrome
timeout /t 5 >nul


echo Done.
exit
