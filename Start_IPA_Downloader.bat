@echo off
Powershell.exe -ExecutionPolicy Bypass -Command ".\IPA_Downloader.ps1"
if exist ".updating" (
    del /f ".updating" >nul 2>&1
) else (
    pause
)
