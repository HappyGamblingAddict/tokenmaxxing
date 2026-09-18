@echo off
setlocal

rem Build this checkout and install it as the global tokenmaxxing command.
set "REPO_ROOT=%~dp0"
bun run --cwd "%REPO_ROOT%apps\cli" build
if errorlevel 1 exit /b %ERRORLEVEL%

npm install --global "%REPO_ROOT%apps\cli" --force --ignore-scripts
exit /b %ERRORLEVEL%
