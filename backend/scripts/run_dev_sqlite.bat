@echo off
setlocal
cd /d "%~dp0.."

set DATABASE_ENGINE=sqlite
".venv\Scripts\python.exe" manage.py migrate
if errorlevel 1 exit /b 1
".venv\Scripts\python.exe" manage.py seed_demo
if errorlevel 1 exit /b 1
".venv\Scripts\python.exe" manage.py runserver 127.0.0.1:8000
endlocal
