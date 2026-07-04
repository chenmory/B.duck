@echo off
setlocal
cd /d "%~dp0.."

if not exist ".venv\Scripts\python.exe" (
  python -m venv .venv
)

".venv\Scripts\python.exe" -m pip install --upgrade pip
".venv\Scripts\python.exe" -m pip install -r requirements.txt

if not exist ".env" (
  copy ".env.example" ".env" > nul
  echo Created .env from .env.example
)

echo.
echo Dependencies are ready. If MySQL password is not configured yet, edit backend\.env.
endlocal
