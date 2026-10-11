@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion
cd /d "%~dp0"
set "PYTHONIOENCODING=utf-8"
set "PY="
for /d %%D in ("%USERPROFILE%\.dsh\dsh-runtimes\*") do (
  if exist "%%D\dependencies\python\python.exe" set "PY=%%D\dependencies\python\python.exe"
)
if not defined PY ( where python >nul 2>nul && set "PY=python" )
if not defined PY (
  echo [ERROR] Python 3 not found. Please install Python 3 or run from DSH runtime.
  pause
  exit /b 1
)
"%PY%" "%~dp0uninstall.py"
echo.
pause
