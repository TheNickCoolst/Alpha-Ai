#!/bin/bash
# Alpha AI Docker Deployment Script
# Automatically detects GPU and deploys appropriate configuration

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${CYAN}"
echo "╔════════════════════════════════════════╗"
echo "║   Alpha AI Docker Deployment          ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"

# Check for GPU
echo -e "${BLUE}🔍 Detecting hardware...${NC}"
if command -v nvidia-smi &> /dev/null; then
    GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n1)
    echo -e "${GREEN}✓ NVIDIA GPU detected: ${GPU_INFO}${NC}"
    COMPOSE_FILE="docker-compose.yml"
    USE_GPU=true
else
    echo -e "${YELLOW}ℹ️  No GPU detected, using CPU mode${NC}"
    COMPOSE_FILE="docker-compose.cpu.yml"
    USE_GPU=false
fi

# Check for Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker not found. Please install Docker first.${NC}"
    exit 1
fi

# Check for Docker Compose
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo -e "${RED}❌ Docker Compose not found. Please install Docker Compose.${NC}"
    exit 1
fi

# Use modern docker compose command if available
if docker compose version &> /dev/null 2>&1; then
    DOCKER_COMPOSE="docker compose"
else
    DOCKER_COMPOSE="docker-compose"
fi

# Check for .env file
echo -e "${BLUE}🔍 Checking configuration...${NC}"
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  No .env file found. Creating template...${NC}"
    cat > .env << 'EOF'
# Groq Configuration
GROQ_API_KEY=gsk_your-api-key-here

# Optional: Local LLM Configuration
# LOCAL_LLM_ENABLED=false
EOF
    echo -e "${RED}❗ Please edit .env and add your Groq API key${NC}"
    echo -e "${YELLOW}   Then run this script again.${NC}"
    exit 1
fi

# Source .env to check API key
source .env
if [ "$GROQ_API_KEY" == "gsk_your-api-key-here" ] || [ -z "$GROQ_API_KEY" ]; then
    echo -e "${RED}❌ Please set a valid GROQ_API_KEY in .env file${NC}"
    exit 1
fi

echo -e "${GREEN}✓ API key configured${NC}"

# Check for character config
if [ ! -f character_config.yaml ]; then
    echo -e "${YELLOW}📝 Creating character_config.yaml from template...${NC}"
    cp character_config.yaml.example character_config.yaml

    # Replace API key in config
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s/gsk_YOURAPIKEY/$GROQ_API_KEY/" character_config.yaml
    else
        # Linux
        sed -i "s/gsk_YOURAPIKEY/$GROQ_API_KEY/" character_config.yaml
    fi
    echo -e "${GREEN}✓ Configuration created${NC}"
fi

# Create necessary directories
mkdir -p audio character_files logs sovits_models

# Check if containers are already running
if [ "$($DOCKER_COMPOSE -f $COMPOSE_FILE ps -q)" ]; then
    echo -e "${YELLOW}⚠️  Containers are already running${NC}"
    read -p "Stop and restart? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}🛑 Stopping services...${NC}"
        $DOCKER_COMPOSE -f $COMPOSE_FILE down
    else
        echo -e "${YELLOW}Exiting...${NC}"
        exit 0
    fi
fi

# Build images
echo ""
echo -e "${BLUE}🔨 Building Docker images...${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE build --pull

# Start services
echo ""
echo -e "${BLUE}🚀 Starting services...${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE up -d

# Wait for services to be healthy
echo ""
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 5

# Check service status
echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}✓ Alpha AI is running!${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# Display service info
echo -e "${BLUE}📊 Service Status:${NC}"
$DOCKER_COMPOSE -f $COMPOSE_FILE ps

echo ""
echo -e "${BLUE}📋 Useful Commands:${NC}"
echo -e "  ${CYAN}View logs:${NC}       $DOCKER_COMPOSE -f $COMPOSE_FILE logs -f alpha-ai"
echo -e "  ${CYAN}Stop services:${NC}   $DOCKER_COMPOSE -f $COMPOSE_FILE down"
echo -e "  ${CYAN}Restart:${NC}         $DOCKER_COMPOSE -f $COMPOSE_FILE restart"
echo -e "  ${CYAN}Shell access:${NC}    $DOCKER_COMPOSE -f $COMPOSE_FILE exec alpha-ai /bin/bash"
echo ""

if [ "$USE_GPU" = true ]; then
    echo -e "${GREEN}🎮 GPU acceleration enabled${NC}"
fi

echo -e "${YELLOW}⚠️  Note: Make sure GPT-SoVITS server is running on port 9880${NC}"
echo ""
echo -e "${BLUE}For help: https://github.com/TheNickCoolst/Alpha-Ai/issues${NC}"
