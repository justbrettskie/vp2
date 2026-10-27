@echo off
title VitalPulse for Windows
cd /d "%~dp0"
echo Starting VitalPulse...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Start-VitalPulse.ps1"
