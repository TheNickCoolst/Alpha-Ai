# Multi-stage Dockerfile for Alpha AI Voice Assistant
# Supports both GPU and CPU configurations

# GPU Version (NVIDIA CUDA)
FROM nvidia/cuda:12.6.0-runtime-ubuntu22.04 AS gpu-base

# Metadata
LABEL maintainer="Alpha AI Team"
LABEL description="Alpha AI Voice Assistant with GPU support"
LABEL version="1.0.0"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3-pip \
    python3.11-venv \
    ffmpeg \
    portaudio19-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/bin/python3.11 /usr/bin/python

# Working directory
WORKDIR /app

# Python dependencies (cached layer)
COPY requirements-alpha-ai.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements-alpha-ai.txt

# GPU-optimized PyTorch
RUN pip install --no-cache-dir \
    torch torchaudio \
    --index-url https://download.pytorch.org/whl/cu126

# Application code
COPY server/ ./server/
COPY character_config.yaml.example ./character_config.yaml

# Create necessary directories
RUN mkdir -p audio character_files logs

# Environment variables
ENV PYTHONUNBUFFERED=1
ENV CUDA_VISIBLE_DEVICES=0

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import torch; print('CUDA available:', torch.cuda.is_available())"

# Default command
CMD ["python", "server/main_chat.py"]


# ===================================
# CPU-Only Version (Smaller, Portable)
# ===================================
FROM python:3.11-slim AS cpu-base

LABEL maintainer="Alpha AI Team"
LABEL description="Alpha AI Voice Assistant (CPU-only)"
LABEL version="1.0.0"

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies
RUN apt-get update && apt-get install -y \
    ffmpeg \
    portaudio19-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Python dependencies
COPY requirements-alpha-ai.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel && \
    pip install --no-cache-dir -r requirements-alpha-ai.txt

# Application code
COPY server/ ./server/
COPY character_config.yaml.example ./character_config.yaml

# Create directories
RUN mkdir -p audio character_files logs

ENV PYTHONUNBUFFERED=1

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import sys; sys.exit(0)"

CMD ["python", "server/main_chat.py"]


# ===================================
# Development Version (with tools)
# ===================================
FROM gpu-base AS dev

RUN pip install --no-cache-dir \
    pytest \
    pytest-cov \
    pytest-asyncio \
    black \
    flake8 \
    isort \
    mypy \
    ipython

# Install development tools
RUN apt-get update && apt-get install -y \
    vim \
    nano \
    htop \
    && rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
