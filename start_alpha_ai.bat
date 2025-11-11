@echo off
REM ========================================
REM Alpha AI Voice Assistant - Launcher
REM ========================================
REM Quick start script for Alpha AI

echo.
echo ========================================
echo   Starting Alpha AI Voice Assistant
echo ========================================
echo.

REM Check if virtual environment exists
if not exist ".venv\Scripts\activate.bat" (
    echo [ERROR] Virtual environment not found!
    echo.
    echo Please run the installer first:
    echo   install_alpha_ai.bat
    echo.
    echo Or create a virtual environment manually:
    echo   python -m venv .venv
    echo   .venv\Scripts\activate.bat
    echo   pip install -r requirements.txt
    echo.
    pause
    exit /b 1
)

REM Activate virtual environment
echo [INFO] Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)
echo [OK] Virtual environment activated
echo.

REM Check if main_chat.py exists
if not exist "server\main_chat.py" (
    echo [ERROR] main_chat.py not found in server directory!
    echo.
    echo Make sure you are running this script from the Alpha-Ai root directory.
    echo.
    pause
    exit /b 1
)

REM Check if character_config.yaml exists
if not exist "character_config.yaml" (
    echo [WARNING] character_config.yaml not found!
    echo.
    echo Please create a configuration file before starting Alpha AI.
    echo You can copy the example:
    echo   copy character_config.yaml.example character_config.yaml
    echo.
    pause
    exit /b 1
)

echo [INFO] Starting Alpha AI...
echo.
echo ========================================
echo   Alpha AI is now running
echo ========================================
echo.
echo Press Ctrl+C to stop Alpha AI
echo.

REM Change to server directory and run the main script
cd server
python main_chat.py

REM Return to root directory
cd ..

echo.
echo ========================================
echo   Alpha AI has stopped
echo ========================================
echo.
pause
