@echo off
setlocal EnableDelayedExpansion

set url=https://endoflife.date/api/python.json
echo Administrative permissions required. Detecting permissions...
net session >nul 2>&1
if %errorLevel% == 0 (
    echo Success: Administrative permissions confirmed!
) else (
    echo Failure: Try relaunching the script with administrator permissions!
PAUSE
)



echo Checking prerequisites. This might take few minutes...
echo Checking python...

set "response="
for /f "usebackq delims=" %%i in (`powershell -command "& {(Invoke-WebRequest -Uri '%url%').Content}"`) do set "response=!response!%%i"

set "latest_py_version="
for /f "tokens=1,2 delims=}" %%a in ("%response%") do (
    set "object=%%a}"
    for %%x in (!object!) do (
        for /f "tokens=1,* delims=:" %%y in ("%%x") do (
            if "%%~y" == "latest" (
                set "latest_py_version=%%~z"
            )
        )
    )
)

:: echo %latest_py_version%

REM Set the minimum required Python version
set python_version=%latest_py_version%

REM Check if Python is already installed and if the version is less than python_version
:: echo Checking if Python %python_version% or greater is already installed...
set "current_version="
where python >nul 2>nul && (
    for /f "tokens=2" %%v in ('python --version 2^>^&1') do set "current_version=%%v"
)

if "%current_version%"=="" (
    :: ---- DOWNLOADING PYTHON ----
    REM Define the URL and file name of the Python installer
    set "url=https://www.python.org/ftp/python/%python_version%/python-%python_version%-amd64.exe"
    set "installer=%TEMP%\python-%python_version%-amd64.exe"

    REM Define the installation directory
    set "targetdir=C:\Python%python_version%"

    REM Download the Python installer
    :: echo Downloading Python installer...
    powershell -Command "(New-Object Net.WebClient).DownloadFile('%url%', '%installer%')"

    REM Install Python with a spinner animation
    :: echo Installing Python...
    start /wait %installer% /quiet TargetDir=%targetdir% Include_test=0
    REM && (echo Done.) || (echo Failed!)
    REM echo.
    
    setx PATH "%targetdir%;%PATH%"

    REM Cleanup
    :: TEMPORARY del %installer%
    :: --------
    
) else (
    if "%current_version%" geq "%python_version%" (
        echo Python %python_version% or greater is already installed.
    )
)

echo Success: Python %python_version% is present!
echo Checking libraries...
python -m pip install -r requirements.txt --quiet > nul 2>&1
echo Success: All libraries found!
echo Launching the program...
python main.py
pause










