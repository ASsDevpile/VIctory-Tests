@echo off
setlocal enabledelayedexpansion
title XENITH VI
cd /d "%~dp0"

rem The title to run; kept in xenith.ini once chosen (key=value lines).
set GAME=D:\GTA6.Xbox.v1.0.2.1-CYBERLEEK\game_scarlett_master.exe
if exist "xenith.ini" for /f "usebackq tokens=1,* delims==" %%a in ("xenith.ini") do set "%%a=%%b"

if not exist "%GAME%" (
    echo Title executable not found: %GAME%
    set /p "GAME=Path to the title's game_*.exe: "
    echo GAME=!GAME!>"xenith.ini"
)

echo.
set EXE=target\diag\victory.exe
if not exist "%EXE%" set EXE=target\release\victory.exe
if not exist "%EXE%" (
    echo No victory.exe here. Build first:
    echo     cargo build --profile diag -p victory --features diagnostics
    pause
    exit /b 1
)
echo XENITH VI   %EXE%
echo title       %GAME%
echo.
echo   1  Play                          (no diagnostics)
echo   2  Debug layer                   (validation only)
echo   3  Debug layer + DRED + GPU timing
echo   4  The crash hunt, loops capped  (loop limit 4096)
echo   5  The crash hunt, skip pipelines
echo.
set "CHOICE="
set /p "CHOICE=Choose [3]: "
if not defined CHOICE set "CHOICE=3"

set "MODE="
if "%CHOICE%"=="1" set "MODE=play"
if "%CHOICE%"=="2" set "MODE=debug"
if "%CHOICE%"=="3" set "MODE=crash-hunt"
if "%CHOICE%"=="4" set "MODE=capped"
if "%CHOICE%"=="5" set "MODE=skip"
if not defined MODE (
    echo No such mode: %CHOICE%
    exit /b 1
)

set "FLAGS=--execute --log"
if "%MODE%"=="play" if exist "target\release\victory.exe" set "EXE=target\release\victory.exe"
if not "%MODE%"=="play" set "FLAGS=%FLAGS% --debug-layer --dred --gpu-timing"
if "%MODE%"=="capped" set "FLAGS=%FLAGS% --loop-limit 4096"
if "%MODE%"=="skip" (
    set /p "SKIP=16-digit shader hashes, comma-separated: "
    set "FLAGS=!FLAGS! --skip-pipelines !SKIP!"
)

echo.
"%EXE%" run "%GAME%" %FLAGS%
echo.
pause
