@echo off
REM ========================================
REM Alpha AI Voice Assistant - Windows Installer (Batch)
REM ========================================
REM Simplified installation script for Windows 10/11
REM For advanced features, use install_alpha_ai.ps1

setlocal EnableDelayedExpansion

echo.
echo ========================================
echo   Alpha AI Voice Assistant Installer
echo ========================================
echo.

REM Find compatible Python version (3.10-3.13)
echo [1/6] Checking Python installation...
set PYTHON_CMD=python
set PYTHON_VERSION=
set PYTHON_MAJOR=
set PYTHON_MINOR=

REM Try py launcher with specific versions first (Windows Python Launcher)
for %%v in (3.13 3.12 3.11 3.10) do (
    py -%%v --version >nul 2>&1
    if not errorlevel 1 (
        set PYTHON_CMD=py -%%v
        for /f "tokens=2" %%i in ('py -%%v --version 2^>^&1') do set PYTHON_VERSION=%%i
        goto :python_found
    )
)

REM Try default python command
python --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%i in ('python --version 2^>^&1') do set PYTHON_VERSION=%%i
    for /f "tokens=1,2 delims=." %%a in ("!PYTHON_VERSION!") do (
        set PYTHON_MAJOR=%%a
        set PYTHON_MINOR=%%b
    )

    REM Check if default python is compatible
    if defined PYTHON_MINOR (
        if !PYTHON_MINOR! GEQ 10 (
            if !PYTHON_MINOR! LEQ 13 (
                set PYTHON_CMD=python
                goto :python_found
            )
        )
    )
)

REM Try python3 command
python3 --version >nul 2>&1
if not errorlevel 1 (
    for /f "tokens=2" %%i in ('python3 --version 2^>^&1') do set PYTHON_VERSION=%%i
    for /f "tokens=1,2 delims=." %%a in ("!PYTHON_VERSION!") do (
        set PYTHON_MAJOR=%%a
        set PYTHON_MINOR=%%b
    )

    REM Check if python3 is compatible
    if defined PYTHON_MINOR (
        if !PYTHON_MINOR! GEQ 10 (
            if !PYTHON_MINOR! LEQ 13 (
                set PYTHON_CMD=python3
                goto :python_found
            )
        )
    )
)

REM No compatible Python found
echo [ERROR] No compatible Python version (3.10-3.13) found!
echo.
echo Detected version: !PYTHON_VERSION!
echo.
echo Solutions:
echo 1. Install Python 3.13 from: https://www.python.org/downloads/release/python-3130/
echo 2. If already installed, make sure it's in PATH
echo 3. Or use: py -3.13 to run Python 3.13 specifically
echo.
pause
exit /b 1

:python_found
echo [OK] Python !PYTHON_VERSION! found and will be used (!PYTHON_CMD!)
echo.

REM Check if FFmpeg is installed
echo [2/6] Checking FFmpeg installation...
ffmpeg -version >nul 2>&1
if errorlevel 1 (
    echo [WARNING] FFmpeg not found in PATH
    echo.
    echo Alpha AI requires FFmpeg for audio processing.
    echo You can install it using:
    echo - Winget: winget install Gyan.FFmpeg
    echo - Chocolatey: choco install ffmpeg
    echo - Manual: https://www.ffmpeg.org/download.html
    echo.
    echo Continue without FFmpeg? (Y/N^)
    choice /C YN /N /M "Continue? (Y/N): "
    if errorlevel 2 exit /b 1
) else (
    echo [OK] FFmpeg found
)
echo.

REM Create virtual environment
echo [3/6] Creating virtual environment...
if exist ".venv" (
    echo [INFO] Virtual environment already exists
    choice /C YN /N /M "Recreate it? (Y/N): "
    if not errorlevel 2 (
        echo [INFO] Removing old virtual environment...
        rmdir /s /q .venv
    )
)

if not exist ".venv" (
    echo [INFO] Creating new virtual environment with !PYTHON_CMD!...
    !PYTHON_CMD! -m venv .venv
    if errorlevel 1 (
        echo [ERROR] Failed to create virtual environment
        pause
        exit /b 1
    )
    echo [OK] Virtual environment created
)
echo.

REM Activate virtual environment
echo [4/6] Activating virtual environment...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Failed to activate virtual environment
    pause
    exit /b 1
)
echo [OK] Virtual environment activated
echo.

REM Upgrade pip and install uv
echo [5/6] Installing dependencies...
echo [INFO] Upgrading pip...
python -m pip install --upgrade pip setuptools wheel --quiet

echo [INFO] Installing UV package manager...
pip install uv --quiet

REM Install requirements
if exist "requirements.txt" (
    echo [INFO] Installing Python packages...
    echo [WARNING] This may take 5-10 minutes depending on your internet connection
    echo.
    uv pip install -r requirements.txt
    if errorlevel 1 (
        echo [ERROR] Failed to install requirements
        pause
        exit /b 1
    )
    echo [OK] All packages installed successfully
) else (
    echo [ERROR] requirements.txt not found!
    pause
    exit /b 1
)
echo.

REM Create directories
echo [6/6] Setting up project structure...
if not exist "audio" mkdir audio
if not exist "character_files" mkdir character_files
echo [OK] Project directories created
echo.

REM Create config file if it doesn't exist
if not exist "character_config.yaml" (
    echo [INFO] Creating character_config.yaml template...
    (
        echo GROQ_API_KEY: gsk_YOUR_API_KEY_HERE
        echo history_file: chat_history.json
        echo model: "llama-3.3-70b-versatile"
        echo.
        echo presets:
        echo   default:
        echo     system_prompt: ^|
        echo       You are Alpha, an intelligent AI assistant.
        echo       You are helpful, knowledgeable, and conversational.
        echo       You provide clear and concise responses.
        echo.
        echo sovits_ping_config:
        echo   text_lang: en
        echo   prompt_lang: en
        echo   ref_audio_path: character_files/main_sample.wav
        echo   prompt_text: This is a sample voice for you to get started with.
    ) > character_config.yaml
    echo [OK] Configuration file created
)
echo.

REM Check for GPU support
echo ========================================
echo GPU Support (Optional^)
echo ========================================
echo.
echo Would you like to install PyTorch with CUDA GPU support?
echo This is only needed if you have an NVIDIA GPU.
echo.
choice /C YN /N /M "Install GPU support? (Y/N): "
if not errorlevel 2 (
    echo.
    echo [INFO] Installing PyTorch with CUDA 12.6 support...
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu126
    echo [OK] GPU support installed
)
echo.

REM Installation complete
echo ========================================
echo   Installation Complete!
echo ========================================
echo.
echo Next Steps:
echo.
echo 1. Edit character_config.yaml with your OpenAI API key:
echo    notepad character_config.yaml
echo.
echo 2. Download and start GPT-SoVITS server from:
echo    https://github.com/RVC-Boss/GPT-SoVITS
echo    (Server should run on port 9880^)
echo.
echo 3. Place your voice sample in:
echo    character_files\main_sample.wav
echo.
echo 4. Activate the virtual environment:
echo    .venv\Scripts\activate.bat
echo.
echo 5. Run Alpha AI:
echo    cd server
echo    python main_chat.py
echo.
echo ========================================
echo.
pause
