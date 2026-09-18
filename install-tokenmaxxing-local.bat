@echo off
setlocal EnableExtensions

rem Download the current fork, build it, and install it globally.
set "SOURCE_DIR=%~dp0"
if exist "%SOURCE_DIR%apps\cli\package.json" goto :check_tools

set "WORK_DIR=%TEMP%\tokenmaxxing-local-install-%RANDOM%"
set "ARCHIVE=%WORK_DIR%\tokenmaxxing-main.zip"
set "SOURCE_DIR=%WORK_DIR%\tokenmaxxing-main"
set "REPO_ARCHIVE=https://github.com/HappyGamblingAddict/tokenmaxxing/archive/refs/heads/main.zip"

mkdir "%WORK_DIR%" >nul 2>&1
if errorlevel 1 (
  echo Could not create temporary directory: %WORK_DIR%
  exit /b 1
)

:check_tools
where npm >nul 2>&1
if errorlevel 1 (
  echo npm is required. Install Node.js, then run this installer again.
  goto :failed
)

where bun >nul 2>&1
if errorlevel 1 (
  echo Bun was not found. Installing Bun...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "irm bun.sh/install.ps1 | iex"
  if errorlevel 1 (
    echo Bun installation failed.
    goto :failed
  )
  set "PATH=%USERPROFILE%\.bun\bin;%PATH%"
)

where bun >nul 2>&1
if errorlevel 1 (
  echo Bun is required to build the local CLI.
  goto :failed
)

echo Downloading tokenmaxxing from GitHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri '%REPO_ARCHIVE%' -OutFile '%ARCHIVE%'; Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%WORK_DIR%' -Force"
if errorlevel 1 (
  echo Could not download or extract the repository.
  goto :failed
)

echo Installing dependencies...
call bun install --cwd "%SOURCE_DIR%" --frozen-lockfile
if errorlevel 1 goto :failed

echo Building the local CLI...
call bun run --cwd "%SOURCE_DIR%\apps\cli" build
if errorlevel 1 goto :failed

echo Installing tokenmaxxing globally...
npm install --global "%SOURCE_DIR%\apps\cli" --force --ignore-scripts
if errorlevel 1 goto :failed

echo.
echo tokenmaxxing was installed globally from the GitHub main branch.
if defined WORK_DIR rmdir /s /q "%WORK_DIR%" >nul 2>&1
exit /b 0

:failed
echo.
echo Installation failed. Temporary files were left at:
echo %WORK_DIR%
exit /b 1
