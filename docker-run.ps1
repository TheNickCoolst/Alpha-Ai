# Alpha AI Docker Deployment Script (PowerShell)
# Automatically detects GPU and deploys appropriate configuration

$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

Write-ColorOutput "╔════════════════════════════════════════╗" Cyan
Write-ColorOutput "║   Alpha AI Docker Deployment          ║" Cyan
Write-ColorOutput "╚════════════════════════════════════════╝" Cyan
Write-Host ""

# Check for GPU
Write-ColorOutput "🔍 Detecting hardware..." Blue
$hasGPU = $false
try {
    $gpuInfo = nvidia-smi --query-gpu=name --format=csv,noheader 2>$null
    if ($LASTEXITCODE -eq 0) {
        $hasGPU = $true
        Write-ColorOutput "✓ NVIDIA GPU detected: $($gpuInfo[0])" Green
        $composeFile = "docker-compose.yml"
    }
} catch {
    Write-ColorOutput "ℹ️  No GPU detected, using CPU mode" Yellow
    $composeFile = "docker-compose.cpu.yml"
}

if (-not $hasGPU) {
    $composeFile = "docker-compose.cpu.yml"
}

# Check for Docker
Write-ColorOutput "🔍 Checking Docker..." Blue
try {
    docker --version | Out-Null
    Write-ColorOutput "✓ Docker found" Green
} catch {
    Write-ColorOutput "❌ Docker not found. Please install Docker Desktop." Red
    exit 1
}

# Check for Docker Compose
$dockerCompose = "docker-compose"
try {
    docker compose version 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $dockerCompose = "docker compose"
    }
} catch {
    # Try old docker-compose command
    try {
        docker-compose --version | Out-Null
    } catch {
        Write-ColorOutput "❌ Docker Compose not found." Red
        exit 1
    }
}

# Check for .env file
Write-ColorOutput "🔍 Checking configuration..." Blue
if (-not (Test-Path .env)) {
    Write-ColorOutput "⚠️  No .env file found. Creating template..." Yellow
    @"
# Groq Configuration
GROQ_API_KEY=gsk_your-api-key-here

# Optional: Local LLM Configuration
# LOCAL_LLM_ENABLED=false
"@ | Out-File -FilePath .env -Encoding UTF8

    Write-ColorOutput "❗ Please edit .env and add your Groq API key" Red
    Write-ColorOutput "   Then run this script again." Yellow
    exit 1
}

# Load and check API key
$envContent = Get-Content .env -Raw
if ($envContent -match 'GROQ_API_KEY=(.+)') {
    $apiKey = $matches[1].Trim()
    if ($apiKey -eq "gsk_your-api-key-here" -or [string]::IsNullOrEmpty($apiKey)) {
        Write-ColorOutput "❌ Please set a valid GROQ_API_KEY in .env file" Red
        exit 1
    }
    Write-ColorOutput "✓ API key configured" Green
}

# Check for character config
if (-not (Test-Path character_config.yaml)) {
    Write-ColorOutput "📝 Creating character_config.yaml from template..." Yellow
    Copy-Item character_config.yaml.example character_config.yaml

    # Replace API key in config
    $config = Get-Content character_config.yaml -Raw
    $config = $config -replace 'sk-YOURAPIKEY', $apiKey
    $config | Out-File -FilePath character_config.yaml -Encoding UTF8

    Write-ColorOutput "✓ Configuration created" Green
}

# Create necessary directories
$directories = @("audio", "character_files", "logs", "sovits_models")
foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir | Out-Null
    }
}

# Check if containers are running
Write-ColorOutput "" White
$runningContainers = & $dockerCompose -f $composeFile ps -q
if ($runningContainers) {
    Write-ColorOutput "⚠️  Containers are already running" Yellow
    $response = Read-Host "Stop and restart? (y/n)"
    if ($response -eq "y" -or $response -eq "Y") {
        Write-ColorOutput "🛑 Stopping services..." Blue
        & $dockerCompose -f $composeFile down
    } else {
        Write-ColorOutput "Exiting..." Yellow
        exit 0
    }
}

# Build images
Write-Host ""
Write-ColorOutput "🔨 Building Docker images..." Blue
& $dockerCompose -f $composeFile build --pull

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Build failed" Red
    exit 1
}

# Start services
Write-Host ""
Write-ColorOutput "🚀 Starting services..." Blue
& $dockerCompose -f $composeFile up -d

if ($LASTEXITCODE -ne 0) {
    Write-ColorOutput "❌ Failed to start services" Red
    exit 1
}

# Wait for services
Write-Host ""
Write-ColorOutput "⏳ Waiting for services to start..." Blue
Start-Sleep -Seconds 5

# Display status
Write-Host ""
Write-ColorOutput "═══════════════════════════════════════" Cyan
Write-ColorOutput "✓ Alpha AI is running!" Green
Write-ColorOutput "═══════════════════════════════════════" Cyan
Write-Host ""

Write-ColorOutput "📊 Service Status:" Blue
& $dockerCompose -f $composeFile ps

Write-Host ""
Write-ColorOutput "📋 Useful Commands:" Blue
Write-ColorOutput "  View logs:       $dockerCompose -f $composeFile logs -f alpha-ai" Cyan
Write-ColorOutput "  Stop services:   $dockerCompose -f $composeFile down" Cyan
Write-ColorOutput "  Restart:         $dockerCompose -f $composeFile restart" Cyan
Write-ColorOutput "  Shell access:    $dockerCompose -f $composeFile exec alpha-ai /bin/bash" Cyan
Write-Host ""

if ($hasGPU) {
    Write-ColorOutput "🎮 GPU acceleration enabled" Green
}

Write-ColorOutput "⚠️  Note: Make sure GPT-SoVITS server is running on port 9880" Yellow
Write-Host ""
Write-ColorOutput "For help: https://github.com/TheNickCoolst/Alpha-Ai/issues" Blue
