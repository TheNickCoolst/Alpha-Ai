@echo off
REM ========================================
REM Alpha AI - One-Click Launcher
REM ========================================
REM Manages installation and startup automatically
REM Just double-click this file to run Alpha AI!

setlocal EnableDelayedExpansion
cls

echo.
echo ========================================
echo   Alpha AI - One-Click Launcher
echo ========================================
echo.

REM Find compatible Python version (3.10-3.13)
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
echo [ERROR] Keine kompatible Python-Version (3.10-3.13) gefunden!
echo.
echo Gefundene Version: !PYTHON_VERSION!
echo.
echo Loesungsvorschlaege:
echo 1. Installiere Python 3.13 von: https://www.python.org/downloads/release/python-3130/
echo 2. Falls bereits installiert, verwende: py -3.13 anstelle von python
echo 3. Passe deinen PATH an, damit Python 3.13 zuerst kommt
echo.
pause
exit /b 1

:python_found
echo [OK] Python !PYTHON_VERSION! wird verwendet (!PYTHON_CMD!)

REM Check if virtual environment exists
if not exist ".venv\Scripts\activate.bat" (
    echo [INFO] Virtuelle Umgebung nicht gefunden.
    echo [INFO] Starte automatische Installation...
    echo.

    REM Run installer
    call install_alpha_ai.bat
    if errorlevel 1 (
        echo.
        echo [ERROR] Installation fehlgeschlagen!
        pause
        exit /b 1
    )

    echo.
    echo [OK] Installation erfolgreich abgeschlossen!
    echo.
)

REM Check if character_config.yaml exists
if not exist "character_config.yaml" (
    echo [WARNING] character_config.yaml nicht gefunden!
    echo.
    echo [INFO] Erstelle Beispiel-Konfiguration...

    if exist "character_config.yaml.example" (
        copy character_config.yaml.example character_config.yaml >nul
        echo [OK] Konfigurationsdatei erstellt.
    ) else (
        REM Create minimal config
        (
            echo GROQ_API_KEY: gsk_YOUR_API_KEY_HERE
            echo history_file: chat_history.json
            echo model: "llama-3.3-70b-versatile"
            echo max_history_messages: 50
            echo.
            echo presets:
            echo   default:
            echo     system_prompt: ^|
            echo       Du bist Alpha, ein intelligenter KI-Assistent.
            echo       Du bist hilfsbereit, wissend und gespraechig.
            echo       Du gibst klare und praezise Antworten.
            echo.
            echo sovits_ping_config:
            echo   text_lang: de
            echo   prompt_lang: de
            echo   ref_audio_path: character_files/main_sample.wav
            echo   prompt_text: Das ist eine Beispielstimme fuer dich.
        ) > character_config.yaml
        echo [OK] Standard-Konfiguration erstellt.
    )

    echo.
    echo WICHTIG: Bitte bearbeite character_config.yaml und fuege deinen OpenAI API-Schluessel ein!
    echo.
    echo Datei wird geoeffnet...
    timeout /t 2 >nul
    notepad character_config.yaml

    echo.
    echo Hast du den API-Schluessel eingetragen? (J/N)
    choice /C JN /N /M "Fortfahren? (J/N): "
    if errorlevel 2 (
        echo.
        echo [INFO] Bitte bearbeite die Konfiguration und starte main.bat erneut.
        pause
        exit /b 0
    )
)

REM Activate virtual environment
echo [INFO] Aktiviere virtuelle Umgebung...
call .venv\Scripts\activate.bat
if errorlevel 1 (
    echo [ERROR] Fehler beim Aktivieren der virtuellen Umgebung
    pause
    exit /b 1
)

REM Check if GPT-SoVITS server is running
echo [INFO] Pruefe GPT-SoVITS Server...
curl -s http://127.0.0.1:9880 >nul 2>&1
if errorlevel 1 (
    echo.
    echo [WARNING] GPT-SoVITS Server laeuft nicht auf Port 9880!
    echo.
    echo Alpha AI benoetigt GPT-SoVITS fuer Text-to-Speech.
    echo Bitte starte den GPT-SoVITS Server von:
    echo https://github.com/RVC-Boss/GPT-SoVITS
    echo.
    echo Moechtest du trotzdem fortfahren? (J/N)
    choice /C JN /N /M "Fortfahren ohne TTS? (J/N): "
    if errorlevel 2 (
        echo.
        echo [INFO] Bitte starte GPT-SoVITS Server und fuehre main.bat erneut aus.
        pause
        exit /b 0
    )
    echo.
    echo [WARNING] Starte ohne TTS-Unterstuetzung...
)

REM Create necessary directories
if not exist "audio" mkdir audio
if not exist "character_files" mkdir character_files

REM Clear screen for clean startup
cls
echo.
echo ========================================
echo   Alpha AI wird gestartet...
echo ========================================
echo.
echo Druecke Ctrl+C zum Beenden
echo.

REM Change to server directory and run
cd server
python main_chat.py

REM Return to root directory
cd ..

echo.
echo ========================================
echo   Alpha AI wurde beendet
echo ========================================
echo.
pause
