.PHONY: help install build start stop restart logs shell clean test lint format docker-build docker-push

# Default target
.DEFAULT_GOAL := help

# Colors
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m # No Color

help: ## Show this help message
	@echo "$(BLUE)Alpha AI - Available Commands$(NC)"
	@echo "=============================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'

# Installation
install: ## Install dependencies locally (non-Docker)
	@echo "$(BLUE)Installing dependencies...$(NC)"
	pip install -r requirements-alpha-ai.txt
	@echo "$(GREEN)✓ Installation complete$(NC)"

install-dev: ## Install development dependencies
	@echo "$(BLUE)Installing development dependencies...$(NC)"
	pip install -r requirements-alpha-ai.txt
	pip install pytest pytest-cov black flake8 isort mypy
	@echo "$(GREEN)✓ Development environment ready$(NC)"

# Docker Commands
docker-build: ## Build Docker images
	@echo "$(BLUE)Building Docker images...$(NC)"
	docker-compose build
	@echo "$(GREEN)✓ Build complete$(NC)"

start: ## Start Alpha AI services (Docker)
	@echo "$(BLUE)Starting services...$(NC)"
	@./docker-run.sh

stop: ## Stop Alpha AI services
	@echo "$(BLUE)Stopping services...$(NC)"
	docker-compose down
	@echo "$(GREEN)✓ Services stopped$(NC)"

restart: stop start ## Restart Alpha AI services

logs: ## View Alpha AI logs
	@docker-compose logs -f alpha-ai

logs-all: ## View all service logs
	@docker-compose logs -f

shell: ## Enter Alpha AI container shell
	@docker-compose exec alpha-ai /bin/bash

# Development
test: ## Run tests
	@echo "$(BLUE)Running tests...$(NC)"
	@if [ -d "tests" ]; then \
		pytest tests/ -v --cov=server --cov-report=html --cov-report=term; \
	else \
		echo "$(YELLOW)⚠️  No tests directory found$(NC)"; \
	fi

lint: ## Run linters
	@echo "$(BLUE)Running linters...$(NC)"
	@flake8 server/ --max-line-length=100 --ignore=E203,W503,E501 || true
	@mypy server/ --ignore-missing-imports || true
	@echo "$(GREEN)✓ Linting complete$(NC)"

format: ## Format code with Black and isort
	@echo "$(BLUE)Formatting code...$(NC)"
	@black server/ --line-length=100
	@isort server/ --profile black
	@echo "$(GREEN)✓ Code formatted$(NC)"

# Cleanup
clean: ## Clean temporary files
	@echo "$(BLUE)Cleaning temporary files...$(NC)"
	@find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.pyc" -delete 2>/dev/null || true
	@find . -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
	@rm -rf .pytest_cache .coverage htmlcov 2>/dev/null || true
	@rm -rf audio/*.wav 2>/dev/null || true
	@echo "$(GREEN)✓ Cleanup complete$(NC)"

clean-all: clean ## Deep clean including Docker volumes
	@echo "$(BLUE)Deep cleaning...$(NC)"
	@docker-compose down -v
	@docker system prune -f
	@echo "$(GREEN)✓ Deep cleanup complete$(NC)"

# Status
status: ## Show service status
	@docker-compose ps

ps: status ## Alias for status

# Health check
health: ## Check service health
	@echo "$(BLUE)Checking service health...$(NC)"
	@docker-compose ps
	@echo ""
	@echo "$(BLUE)Alpha AI:$(NC)"
	@curl -f http://localhost:8000/ 2>/dev/null && echo "$(GREEN)✓ Reachable$(NC)" || echo "$(YELLOW)⚠️  Not reachable$(NC)"
	@echo ""
	@echo "$(BLUE)GPT-SoVITS:$(NC)"
	@curl -f http://localhost:9880/ 2>/dev/null && echo "$(GREEN)✓ Reachable$(NC)" || echo "$(YELLOW)⚠️  Not reachable$(NC)"

# Configuration
config: ## Show current configuration
	@echo "$(BLUE)Current Configuration:$(NC)"
	@if [ -f "character_config.yaml" ]; then \
		cat character_config.yaml; \
	else \
		echo "$(YELLOW)⚠️  No configuration file found$(NC)"; \
	fi

# Quick setup
setup: ## Quick setup (create config from example)
	@echo "$(BLUE)Setting up Alpha AI...$(NC)"
	@if [ ! -f "character_config.yaml" ]; then \
		cp character_config.yaml.example character_config.yaml; \
		echo "$(GREEN)✓ Created character_config.yaml$(NC)"; \
		echo "$(YELLOW)⚠️  Please edit character_config.yaml and add your OpenAI API key$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  character_config.yaml already exists$(NC)"; \
	fi
	@mkdir -p audio character_files logs
	@echo "$(GREEN)✓ Setup complete$(NC)"

# Version info
version: ## Show version information
	@echo "$(BLUE)Alpha AI Version Information$(NC)"
	@echo "=============================="
	@git describe --tags --always 2>/dev/null || echo "Development version"
	@echo ""
	@echo "Python: $(shell python --version 2>&1)"
	@echo "Docker: $(shell docker --version 2>&1)"
