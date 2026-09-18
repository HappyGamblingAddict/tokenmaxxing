@echo off
setlocal EnableExtensions

rem Download the current fork, build it, and install it globally.
set "WORK_DIR=%TEMP%\tokenmaxxing-local-install-%RANDOM%"
for %%I in ("%~dp0.") do set "SOURCE_DIR=%%~fI"
set "LOCAL_SOURCE=1"
mkdir "%WORK_DIR%" >nul 2>&1
if errorlevel 1 (
  echo Could not create temporary directory: %WORK_DIR%
  exit /b 1
)
if exist "%SOURCE_DIR%\apps\cli\package.json" goto :check_tools

set "LOCAL_SOURCE="
set "ARCHIVE=%WORK_DIR%\tokenmaxxing-main.zip"
set "SOURCE_DIR=%WORK_DIR%\tokenmaxxing-main"
set "REPO_ARCHIVE=https://github.com/HappyGamblingAddict/tokenmaxxing/archive/refs/heads/main.zip"

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

if defined LOCAL_SOURCE goto :install_dependencies

echo Downloading tokenmaxxing from GitHub...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference = 'Stop'; Invoke-WebRequest -Uri '%REPO_ARCHIVE%' -OutFile '%ARCHIVE%'; Expand-Archive -LiteralPath '%ARCHIVE%' -DestinationPath '%WORK_DIR%' -Force"
if errorlevel 1 (
  echo Could not download or extract the repository.
  goto :failed
)

:install_dependencies
echo Installing dependencies...
call bun install --cwd "%SOURCE_DIR%" --frozen-lockfile
if errorlevel 1 goto :failed

echo Building the local CLI...
call bun run --cwd "%SOURCE_DIR%\apps\cli" build
if errorlevel 1 goto :failed

echo Installing tokenmaxxing globally...
call npm pack --ignore-scripts --pack-destination "%WORK_DIR%" "%SOURCE_DIR%\apps\cli"
if errorlevel 1 goto :failed
for /f "delims=" %%P in ('dir /b /o-d "%WORK_DIR%\*.tgz" 2^>nul') do if not defined PACKAGE_FILE set "PACKAGE_FILE=%WORK_DIR%\%%P"
if not defined PACKAGE_FILE (
  echo npm did not create a package archive.
  goto :failed
)
cmd.exe /d /c npm install --global "%PACKAGE_FILE%" --force --ignore-scripts
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
