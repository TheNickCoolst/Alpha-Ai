#!/bin/bash
# Alpha AI Installation Script

echo "======================================="
echo "Alpha AI Voice Assistant Installation"
echo "======================================="

# Check Python version
python_version=$(python3 --version 2>&1 | awk '{print $2}')
python_major_minor=$(echo "$python_version" | cut -d. -f1,2)
echo "Python version: $python_version"

# Check if Python version is between 3.10 and 3.13
if command -v bc &> /dev/null; then
    if [ "$(echo "$python_major_minor < 3.10" | bc)" -eq 1 ]; then
        echo "Error: Python 3.10 or higher is required"
        echo "Current version: $python_version"
        exit 1
    fi

    if [ "$(echo "$python_major_minor >= 3.14" | bc)" -eq 1 ]; then
        echo "Error: Python 3.14+ is not yet supported!"
        echo ""
        echo "The onnxruntime-gpu package currently only supports Python 3.10-3.13"
        echo "Current version: $python_version"
        echo ""
        echo "Please install Python 3.13 from: https://www.python.org/downloads/release/python-3130/"
        exit 1
    fi
else
    # Fallback if bc is not available
    major=$(echo "$python_major_minor" | cut -d. -f1)
    minor=$(echo "$python_major_minor" | cut -d. -f2)

    if [ "$major" -lt 3 ] || ([ "$major" -eq 3 ] && [ "$minor" -lt 10 ]); then
        echo "Error: Python 3.10 or higher is required"
        echo "Current version: $python_version"
        exit 1
    fi

    if [ "$major" -eq 3 ] && [ "$minor" -ge 14 ]; then
        echo "Error: Python 3.14+ is not yet supported!"
        echo ""
        echo "The onnxruntime-gpu package currently only supports Python 3.10-3.13"
        echo "Current version: $python_version"
        echo ""
        echo "Please install Python 3.13 from: https://www.python.org/downloads/release/python-3130/"
        exit 1
    fi
fi

echo "✓ Python version is compatible"

# Install uv package manager
echo ""
echo "Installing uv package manager..."
pip install uv

# Install Alpha AI dependencies
echo ""
echo "Installing Alpha AI dependencies..."
uv pip install -r requirements-alpha-ai.txt

# Optional: Install PyTorch with CUDA support
read -p "Do you want to install PyTorch with CUDA support? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Checking NVIDIA CUDA version..."
    nvidia-smi
    echo ""
    echo "Installing PyTorch with CUDA 12.6 support..."
    echo "If you have a different CUDA version, modify this command accordingly"
    pip install torch torchaudio --index-url https://download.pytorch.org/whl/cu126
fi

# Setup configuration file
echo ""
if [ ! -f "character_config.yaml" ]; then
    echo "Creating character_config.yaml from template..."
    cp character_config.yaml.example character_config.yaml
    echo "✓ Config file created. Please edit character_config.yaml with your OpenAI API key"
else
    echo "character_config.yaml already exists, skipping..."
fi

echo ""
echo "======================================="
echo "✓ Alpha AI installation complete!"
echo "======================================="
echo ""
echo "Next steps:"
echo "1. Edit character_config.yaml with your OpenAI API key"
echo "2. Start GPT-SoVITS server on port 9880"
echo "3. Run: cd server && python main_chat.py"
