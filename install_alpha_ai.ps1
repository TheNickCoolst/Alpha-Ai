# ========================================
# Alpha AI Voice Assistant - Windows 11 Installer
# ========================================
# This script automates the installation of Alpha AI on Windows 11
# Requires: Administrator privileges for some operations

param(
    [switch]$SkipGPU = $false,
    [switch]$UseWinget = $true
)

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

# Color functions for better output
function Write-ColorOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput "✓ $Message" "Green" }
function Write-Info { param([string]$Message) Write-ColorOutput "→ $Message" "Cyan" }
function Write-Warning { param([string]$Message) Write-ColorOutput "⚠ $Message" "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput "✗ $Message" "Red" }
function Write-Header { param([string]$Message) Write-ColorOutput "`n========== $Message ==========`n" "Magenta" }

# Check if running on Windows 11
function Test-Windows11 {
    $version = [System.Environment]::OSVersion.Version
    $build = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild

    if ([int]$build -ge 22000) {
        Write-Success "Windows 11 detected (Build: $build)"
        return $true
    } else {
        Write-Warning "This script is optimized for Windows 11, but detected Windows 10 or older (Build: $build)"
        $continue = Read-Host "Continue anyway? (y/n)"
        return $continue -eq 'y'
    }
}

# Check Python installation
function Test-PythonInstallation {
    Write-Info "Checking Python installation..."

    try {
        $pythonVersion = python --version 2>&1
        if ($pythonVersion -match "Python (\d+\.\d+\.\d+)") {
            $fullVersion = $matches[1]
            $version = [version]$fullVersion

            if ($version -ge [version]"3.10" -and $version -lt [version]"3.14") {
                Write-Success "Python $fullVersion found"
                return $true
            } elseif ($version -ge [version]"3.14") {
                Write-Error "Python $fullVersion detected - Python 3.14+ is not yet supported!"
                Write-Warning "The onnxruntime-gpu package currently only supports Python 3.10-3.13"
                Write-Info "Please install Python 3.13 from: https://www.python.org/downloads/release/python-3130/"
                return $false
            } else {
                Write-Warning "Python $fullVersion found, but version 3.10-3.13 is required"
                return $false
            }
        }
    } catch {
        Write-Warning "Python not found in PATH"
        return $false
    }
    return $false
}

# Install Python using winget
function Install-Python {
    Write-Header "Installing Python 3.13"

    if ($UseWinget) {
        Write-Info "Attempting to install Python via winget..."
        try {
            winget install Python.Python.3.13 --silent --accept-package-agreements --accept-source-agreements
            Write-Success "Python installed successfully"
            Write-Info "Please restart your terminal and run this script again"
            exit 0
        } catch {
            Write-Error "Failed to install Python via winget"
        }
    }

    Write-Info "Please install Python 3.10-3.13 manually from: https://www.python.org/downloads/"
    Write-Info "Important: Python 3.14+ is not yet supported due to onnxruntime-gpu compatibility"
    Write-Info "Make sure to check 'Add Python to PATH' during installation!"
    exit 1
}

# Check FFmpeg installation
function Test-FFmpegInstallation {
    Write-Info "Checking FFmpeg installation..."

    try {
        $ffmpegVersion = ffmpeg -version 2>&1
        if ($ffmpegVersion) {
            Write-Success "FFmpeg found"
            return $true
        }
    } catch {
        Write-Warning "FFmpeg not found"
        return $false
    }
    return $false
}

# Install FFmpeg using winget
function Install-FFmpeg {
    Write-Header "Installing FFmpeg"

    if ($UseWinget) {
        Write-Info "Attempting to install FFmpeg via winget..."
        try {
            winget install Gyan.FFmpeg --silent --accept-package-agreements --accept-source-agreements
            Write-Success "FFmpeg installed successfully"
            Write-Warning "You may need to restart your terminal for FFmpeg to be available"
            return $true
        } catch {
            Write-Warning "Failed to install FFmpeg via winget"
        }
    }

    Write-Info "Please install FFmpeg manually from: https://www.ffmpeg.org/download.html"
    Write-Info "Or use Chocolatey: choco install ffmpeg"
    return $false
}

# Check for CUDA installation (for GPU support)
function Test-CUDAInstallation {
    Write-Info "Checking for NVIDIA CUDA..."

    try {
        $nvcc = nvcc --version 2>&1
        if ($nvcc -match "release (\d+\.\d+)") {
            Write-Success "CUDA $($matches[1]) detected"
            return $true
        }
    } catch {
        Write-Info "CUDA not found (CPU-only mode will be used)"
    }
    return $false
}

# Create virtual environment
function New-VirtualEnvironment {
    Write-Header "Creating Python Virtual Environment"

    $venvPath = ".venv"

    if (Test-Path $venvPath) {
        Write-Warning "Virtual environment already exists"
        $recreate = Read-Host "Recreate it? (y/n)"
        if ($recreate -eq 'y') {
            Write-Info "Removing old virtual environment..."
            Remove-Item -Recurse -Force $venvPath
        } else {
            return $true
        }
    }

    Write-Info "Creating virtual environment..."
    python -m venv $venvPath

    if (Test-Path "$venvPath\Scripts\Activate.ps1") {
        Write-Success "Virtual environment created successfully"
        return $true
    } else {
        Write-Error "Failed to create virtual environment"
        return $false
    }
}

# Activate virtual environment
function Enable-VirtualEnvironment {
    Write-Info "Activating virtual environment..."

    $activateScript = ".venv\Scripts\Activate.ps1"

    if (Test-Path $activateScript) {
        & $activateScript
        Write-Success "Virtual environment activated"
        return $true
    } else {
        Write-Error "Cannot find activation script"
        return $false
    }
}

# Install Python packages
function Install-PythonPackages {
    Write-Header "Installing Python Dependencies"

    Write-Info "Upgrading pip, setuptools, and wheel..."
    python -m pip install --upgrade pip setuptools wheel

    Write-Info "Installing UV package manager..."
    pip install uv
    Write-Success "UV installed"

    if (Test-Path "requirements.txt") {
        Write-Info "Installing packages from requirements.txt..."
        Write-Info "This may take several minutes..."

        uv pip install -r requirements.txt

        Write-Success "Python packages installed successfully"
        return $true
    } else {
        Write-Error "requirements.txt not found!"
        return $false
    }
}

# Install PyTorch with CUDA support
function Install-PyTorchGPU {
    Write-Header "Installing PyTorch with GPU Support"

    Write-Info "Installing PyTorch with CUDA 12.6 support..."
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu126

    Write-Success "PyTorch GPU version installed"
}

# Create necessary directories
function Initialize-ProjectStructure {
    Write-Header "Initializing Project Structure"

    $directories = @(
        "audio",
        "character_files"
    )

    foreach ($dir in $directories) {
        if (-not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir | Out-Null
            Write-Success "Created directory: $dir"
        } else {
            Write-Info "Directory already exists: $dir"
        }
    }
}

# Create character_config.yaml template if it doesn't exist
function Initialize-ConfigFile {
    $configPath = "character_config.yaml"

    if (-not (Test-Path $configPath)) {
        Write-Info "Creating character_config.yaml template..."

        $configTemplate = @"
GROQ_API_KEY: gsk_YOUR_API_KEY_HERE
history_file: chat_history.json
model: "llama-3.3-70b-versatile"

presets:
  default:
    system_prompt: |
      You are Alpha, an intelligent AI assistant.
      You are helpful, knowledgeable, and conversational.
      You provide clear and concise responses.

sovits_ping_config:
  text_lang: en
  prompt_lang: en
  ref_audio_path: character_files/main_sample.wav
  prompt_text: This is a sample voice for you to get started with.
"@

        Set-Content -Path $configPath -Value $configTemplate
        Write-Success "Created $configPath - Please edit it with your API key!"
    } else {
        Write-Info "character_config.yaml already exists"
    }
}

# Display next steps
function Show-NextSteps {
    Write-Header "Installation Complete!"

    Write-ColorOutput @"

🎉 Alpha AI has been successfully installed!

📝 Next Steps:

1. Edit character_config.yaml with your OpenAI API key:
   notepad character_config.yaml

2. Download and start GPT-SoVITS server:
   https://github.com/RVC-Boss/GPT-SoVITS
   (The TTS server should run on port 9880)

3. Place your voice sample in:
   character_files/main_sample.wav

4. Activate the virtual environment (if not already active):
   .venv\Scripts\Activate.ps1

5. Run the Alpha AI assistant:
   cd server
   python main_chat.py

📚 Documentation: https://github.com/YourRepo/Alpha-Ai

"@ "Cyan"
}

# Main installation process
function Start-Installation {
    Clear-Host
    Write-ColorOutput @"
╔═══════════════════════════════════════════════╗
║  Alpha AI Voice Assistant - Windows Installer ║
║           Optimized for Windows 11            ║
╚═══════════════════════════════════════════════╝
"@ "Cyan"

    # Check Windows version
    if (-not (Test-Windows11)) {
        exit 1
    }

    # Check and install Python
    if (-not (Test-PythonInstallation)) {
        Install-Python
    }

    # Check and install FFmpeg
    if (-not (Test-FFmpegInstallation)) {
        $result = Install-FFmpeg
        if (-not $result) {
            Write-Warning "Continuing without FFmpeg - you'll need to install it manually"
        }
    }

    # Check for CUDA (optional GPU support)
    $hasGPU = Test-CUDAInstallation

    # Create virtual environment
    if (-not (New-VirtualEnvironment)) {
        Write-Error "Failed to create virtual environment"
        exit 1
    }

    # Activate virtual environment
    if (-not (Enable-VirtualEnvironment)) {
        Write-Error "Failed to activate virtual environment"
        exit 1
    }

    # Install Python packages
    if (-not (Install-PythonPackages)) {
        Write-Error "Failed to install Python packages"
        exit 1
    }

    # Install PyTorch with GPU support if available and not skipped
    if ($hasGPU -and -not $SkipGPU) {
        $installGPU = Read-Host "Install PyTorch with GPU support? (y/n)"
        if ($installGPU -eq 'y') {
            Install-PyTorchGPU
        }
    }

    # Initialize project structure
    Initialize-ProjectStructure
    Initialize-ConfigFile

    # Show next steps
    Show-NextSteps
}

# Run the installation
try {
    Start-Installation
} catch {
    Write-Error "Installation failed: $_"
    Write-Info "Please check the error message above and try again"
    exit 1
}
