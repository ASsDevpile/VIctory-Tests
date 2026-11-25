@echo off
rem The graphical XENITH VI launcher: Windows PowerShell with WPF, nothing
rem to install. The command-line one stays xenith.cmd.
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0xenith-ui.ps1"
