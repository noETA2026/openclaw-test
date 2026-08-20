@echo off
setlocal

set "FILE=%~1"
set "TOKEN=%~2"
set "CHANNEL=%~3"

if "%FILE%"=="" goto :usage
if "%TOKEN%"=="" goto :usage
if "%CHANNEL%"=="" goto :usage

echo Bad Apple ASCII → Discord (NO rate limit)
echo File: %FILE%
echo Channel: %CHANNEL%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0badapple-play.ps1" "%FILE%" "%TOKEN%" "%CHANNEL%"
goto :eof

:usage
echo Usage: badapple-play.bat frames.txt bot_token channel_id
echo.
echo   frames.txt   - SPLIT-separated ASCII art frames
echo   bot_token    - Discord bot token
echo   channel_id   - Discord channel ID
