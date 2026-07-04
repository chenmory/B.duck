@echo off
setlocal
cd /d "%~dp0.."
".venv\Scripts\python.exe" manage.py migrate
if errorlevel 1 (
  echo.
  echo Migration failed. Check whether MySQL is running and .env has the right password.
  exit /b 1
)
".venv\Scripts\python.exe" manage.py seed_demo
endlocal
