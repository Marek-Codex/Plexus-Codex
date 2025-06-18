@echo off
title Plexus Codex Manager
echo.
echo  ██████╗ ██╗     ███████╗██╗  ██╗██╗   ██╗███████╗
echo  ██╔══██╗██║     ██╔════╝╚██╗██╔╝██║   ██║██╔════╝
echo  ██████╔╝██║     █████╗   ╚███╔╝ ██║   ██║███████╗
echo  ██╔═══╝ ██║     ██╔══╝   ██╔██╗ ██║   ██║╚════██║
echo  ██║     ███████╗███████╗██╔╝ ██╗╚██████╔╝███████║
echo  ╚═╝     ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝
echo.
echo                     CODEX MANAGER
echo        Advanced Windows Context Menu System
echo.
echo This will download and run the Codex Manager from GitHub.
echo.
echo What would you like to do?
echo   1) Install Codex
echo   2) Uninstall Codex  
echo   3) Interactive Manager (Install/Uninstall/Reinstall)
echo   4) Exit
echo.
set /p choice="Select option (1-4): "

if "%choice%"=="1" goto install
if "%choice%"=="2" goto uninstall
if "%choice%"=="3" goto interactive
if "%choice%"=="4" goto exit
echo Invalid choice. Please try again.
pause
goto start

:install
echo.
echo Installing Codex...
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex" -Install
goto end

:uninstall
echo.
echo Uninstalling Codex...
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex" -Uninstall
goto end

:interactive
echo.
echo Starting Interactive Manager...
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/Marek-Codex/Plexus-Codex/main/Codex-Manager.ps1 | iex"
goto end

:exit
echo.
echo Goodbye!
exit /b 0

:end
echo.
echo Press any key to exit...
pause >nul
