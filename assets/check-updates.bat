@echo off
setlocal EnableDelayedExpansion

:: Check for dependencies
where curl >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo curl is not installed. Please install curl and try again.
    pause
    exit /b
)

where jq >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo jq is not installed. Please install jq and try again.
    pause
    exit /b
)

where powershell >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo PowerShell is not installed. Please install PowerShell and try again.
    pause
    exit /b
)

where 7z >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo 7-Zip is not installed. Please install 7-Zip and try again.
    pause
    exit /b
)

:: Variables
set "GITHUB_API=https://api.github.com/repos/SagerNet/sing-box/releases"
set "VERSION_FILE=version.txt"
set "TEMP_DIR=.\temp"

:: Check if version.txt exists
if not exist %VERSION_FILE% (
    echo 0.0.0 > %VERSION_FILE%
)

:: Get current version from version.txt
set /p CURRENT_VERSION=<%VERSION_FILE%

:: Create temp directory
if exist "%TEMP_DIR%" (
    rmdir /s /q "%TEMP_DIR%"
)
mkdir "%TEMP_DIR%"

:: Get all releases info from GitHub (including pre-releases)
curl -s %GITHUB_API% > %TEMP_DIR%\releases.json

:: Find the latest release (including pre-releases)
for /f "delims=" %%i in ('jq -r ".[0].tag_name" %TEMP_DIR%\releases.json') do (
    set "TAG=%%i"
)

:: Remove the leading "v" from the version tag
set "LATEST_VERSION=%TAG%"
if "!LATEST_VERSION:~0,1!"=="v" set "LATEST_VERSION=!LATEST_VERSION:~1!"

:: Compare versions
if %CURRENT_VERSION% == %TAG% (
    echo Your version is up-to-date.
    goto cleanup
)

:: Construct download URL
set "DOWNLOAD_URL=https://github.com/SagerNet/sing-box/releases/download/%TAG%/sing-box-%LATEST_VERSION%-windows-amd64.zip"
set "ZIP_FILE=%TEMP_DIR%\sing-box-%LATEST_VERSION%-windows-amd64.zip"

:: Download the latest version
echo New version found: %LATEST_VERSION%
echo Downloading %DOWNLOAD_URL% ...
curl -L %DOWNLOAD_URL% -o "%ZIP_FILE%"

:: Extract the downloaded zip file
echo Extracting %ZIP_FILE% ...
7z x "%ZIP_FILE%" -o"%TEMP_DIR%" >nul

:: Move contents from the nested folder to the working directory
echo Moving files...
xcopy /y "%TEMP_DIR%\sing-box-%LATEST_VERSION%-windows-amd64" .

:: Update version.txt
echo %TAG% > %VERSION_FILE%

echo Update complete.

:cleanup
echo Cleaning up...
rd /s /q "%TEMP_DIR%"
endlocal
start /b qsing-box.exe /autorun
