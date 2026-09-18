@echo off
setlocal

rem Run the CLI from this checkout instead of the globally installed package.
set "REPO_ROOT=%~dp0"
bun run --cwd "%REPO_ROOT%apps\cli" cli %*
exit /b %ERRORLEVEL%
