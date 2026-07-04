@echo off
setlocal
cd /d "%~dp0.."
".venv\Scripts\python.exe" manage.py check
endlocal
