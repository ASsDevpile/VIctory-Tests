@echo off
setlocal enabledelayedexpansion
title XENITH VI
cd /d "%~dp0"

rem Every setting lives in xenith.ini as key=value lines; menu item 6 edits
rem them. An empty setting means the runtime's default: cache and saves then
rem go to %LOCALAPPDATA%\victory, and the log becomes a timestamped file in
rem %TEMP%.
set "GAME="
set "CACHE="
set "DATA="
set "FIDELITYFX="
set "CONSOLE=series-x"
set "UNIMPLEMENTED=trap"
set "STRICT=off"
set "LOG="
set "LOOP_LIMIT="
set "SKIP="
if exist "xenith.ini" for /f "usebackq tokens=1,* delims==" %%a in ("xenith.ini") do set "%%a=%%b"

if not defined GAME (
    echo No title configured yet.
    set /p "GAME=Path to the title's game_*.exe (no quotes): "
    call :save
)

:menu
set "MODE="
if not defined GAME (
    echo A title path is needed: pick 6 Settings, then 1.
    pause
    goto settings
)
if not exist "%GAME%" echo Warning: "%GAME%" does not exist.

set "EXE=target\diag\victory.exe"
if not exist "%EXE%" set "EXE=target\release\victory.exe"
if not exist "%EXE%" (
    echo No victory.exe here. Build first:
    echo     cargo build --profile diag -p victory --features diagnostics
    pause
    exit /b 1
)
echo.
echo XENITH VI   %EXE%
echo title       %GAME%
if defined CACHE echo cache       %CACHE%
if defined DATA echo saves       %DATA%
if defined FIDELITYFX echo fidelityfx  %FIDELITYFX%
echo console     %CONSOLE%   unimplemented (%UNIMPLEMENTED%)   strict (%STRICT%)
echo.
echo   1  Play                          (no diagnostics)
echo   2  Debug layer                   (validation only)
echo   3  Debug layer + DRED + GPU timing
echo   4  The crash hunt, loops capped  (loop limit 4096)
echo   5  The crash hunt, skip pipelines (%SKIP%)
echo   6  Settings
echo   0  Exit
echo.
set "CHOICE="
set /p "CHOICE=Choose [3]: "
if not defined CHOICE set "CHOICE=3"
if "%CHOICE%"=="0" exit /b 0
if "%CHOICE%"=="1" set "MODE=play"
if "%CHOICE%"=="2" set "MODE=debug"
if "%CHOICE%"=="3" set "MODE=crash-hunt"
if "%CHOICE%"=="4" set "MODE=capped"
if "%CHOICE%"=="5" set "MODE=skip"
if "%CHOICE%"=="6" goto settings
if not defined MODE (
    echo No such mode: %CHOICE%
    goto menu
)

rem The launcher's settings decide the run's paths: the runtime reads its
rem environment before its config file, so these are set (or cleared) here,
rem every run, and a global shell variable cannot override them.
set "VICTORY_GAME_DIR="
set "VICTORY_CACHE_DIR="
set "VICTORY_DATA_DIR="
set "VICTORY_FIDELITYFX_DIR="
if defined CACHE set "VICTORY_CACHE_DIR=%CACHE%"
if defined DATA set "VICTORY_DATA_DIR=%DATA%"
if defined FIDELITYFX set "VICTORY_FIDELITYFX_DIR=%FIDELITYFX%"

set "FLAGS=--console %CONSOLE% --unimplemented %UNIMPLEMENTED%"
if /i "%STRICT%"=="on" set "FLAGS=%FLAGS% --strict"
set "LOGARGS=--log"
if defined LOG set "LOGARGS=--log "%LOG%""
if not "%MODE%"=="play" set "FLAGS=%FLAGS% --debug-layer --dred --gpu-timing"
if "%MODE%"=="play" if exist "target\release\victory.exe" set "EXE=target\release\victory.exe"
if "%MODE%"=="capped" if not defined LOOP_LIMIT set "LOOP_LIMIT=4096"
if defined LOOP_LIMIT set "FLAGS=%FLAGS% --loop-limit %LOOP_LIMIT%"
if "%MODE%"=="skip" (
    echo Pipelines skipped now: %SKIP%
    set "NEW="
    set /p "NEW=New list of 16-digit hashes, comma-separated (empty keeps it): "
    if defined NEW set "SKIP=!NEW!"
    call :save
)
if defined SKIP set "FLAGS=%FLAGS% --skip-pipelines %SKIP%"

echo.
"%EXE%" run "%GAME%" %FLAGS% %LOGARGS%
echo.
pause
goto menu

:settings
echo.
echo Settings (empty values mean the runtime's defaults)
echo.
echo    1  Game path        %GAME%
echo    2  Cache location   %CACHE%  (default %%LOCALAPPDATA%%\victory\cache)
echo    3  Saves location   %DATA%  (default %%LOCALAPPDATA%%\victory\data)
echo    4  FidelityFX       %FIDELITYFX%
echo    5  Console model    %CONSOLE%
echo    6  Unimplemented    %UNIMPLEMENTED%
echo    7  Strict           %STRICT%
echo    8  Log file         %LOG%  (default: a timestamped one in %%TEMP%%)
echo    9  Loop limit       %LOOP_LIMIT%  (default: 2^^20)
echo   10  Skip pipelines   %SKIP%
echo    0  Back
echo.
set "WHICH="
set /p "WHICH=Edit [0]: "
if not defined WHICH set "WHICH=0"
if "%WHICH%"=="0" goto menu
if "%WHICH%"=="1" call :ask GAME "1 Path to the title's game_*.exe"
if "%WHICH%"=="2" call :ask CACHE "2 Cache location (shader and image caches)"
if "%WHICH%"=="3" call :ask DATA "3 Saves location (persistent title storage)"
if "%WHICH%"=="4" call :ask FIDELITYFX "4 FidelityFX folder (the host upscaler's DLLs)"
if "%WHICH%"=="5" call :ask CONSOLE "5 Console model (series-x or series-s)"
if "%WHICH%"=="6" call :ask UNIMPLEMENTED "6 Unimplemented imports (trap or zero)"
if "%WHICH%"=="7" call :ask STRICT "7 Strict (on: no host pass-through; off: the default)"
if "%WHICH%"=="8" call :ask LOG "8 Log file (folder and name; empty: a timestamped one)"
if "%WHICH%"=="9" call :ask LOOP_LIMIT "9 Loop limit (empty: the default 2^20)"
if "%WHICH%"=="10" call :ask SKIP "10 Pipelines to skip, comma-separated hashes"
goto settings

:ask
set "CURRENT="
for %%v in (%1) do set "CURRENT=!%%v!"
echo Current: [!CURRENT!]
set "VALUE="
set /p "VALUE=%~2 (empty keeps the current one): "
if defined VALUE set "%~1=%VALUE%"
goto :eof

:save
(for %%k in (GAME CACHE DATA FIDELITYFX CONSOLE UNIMPLEMENTED STRICT LOG LOOP_LIMIT SKIP) do echo %%k=!%%k!)>xenith.ini
goto :eof
