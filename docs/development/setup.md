# Development Setup Guide

## Overview
This guide provides detailed instructions for setting up the TuneFi development environment, including all required tools, dependencies, and configurations.

## Prerequisites

### 1. System Requirements
- Operating System: macOS, Linux, or Windows WSL2
- Memory: 8GB RAM minimum
- Storage: 20GB free space
- Node.js v16+
- Git

### 2. Development Tools
- Foundry
- Solidity compiler v0.8.20
- Node.js and npm
- VSCode (recommended)
- Git

### 3. Optional Tools
- IPFS daemon
- Neo4j database
- Docker
- Hardhat (for comparison testing)

## Installation Steps

### 1. Core Tools
```bash
# Install Node.js and npm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 16
nvm use 16

# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install Solidity compiler
solc-select install 0.8.20
solc-select use 0.8.20
```

### 2. Project Setup
```bash
# Clone repository
git clone https://github.com/your-username/tunefi.git
cd tunefi

# Install dependencies
forge install

# Build contracts
forge build

# Run tests
forge test
```

### 3. IDE Setup
```bash
# Install VSCode extensions
code --install-extension JuanBlanco.solidity
code --install-extension tintinweb.solidity-visual-auditor
code --install-extension ms-vscode.vscode-typescript-next
```

## Configuration

### 1. Environment Variables
```bash
# Create .env file
cp .env.example .env

# Required variables
PRIVATE_KEY=your_private_key
INFURA_API_KEY=your_infura_key
ETHERSCAN_API_KEY=your_etherscan_key
```

### 2. Foundry Configuration
```toml
# foundry.toml
[profile.default]
src = 'src'
out = 'out'
libs = ['lib']
solc = "0.8.20"
optimizer = true
optimizer_runs = 200

[profile.test]
verbosity = 3
gas_reports = ["*"]
```

### 3. Git Configuration
```bash
# Configure Git
git config user.name "Your Name"
git config user.email "your.email@example.com"

# Set up Git hooks
cp scripts/pre-commit .git/hooks/
chmod +x .git/hooks/pre-commit
```

## Optional Components

### 1. IPFS Setup
```bash
# Install IPFS
wget https://dist.ipfs.io/go-ipfs/v0.12.0/go-ipfs_v0.12.0_linux-amd64.tar.gz
tar -xvzf go-ipfs_v0.12.0_linux-amd64.tar.gz
cd go-ipfs
sudo bash install.sh

# Initialize IPFS
ipfs init
ipfs daemon
```

### 2. Neo4j Setup
```bash
# Using Docker
docker run \
    --name neo4j \
    -p 7474:7474 -p 7687:7687 \
    -d \
    -v $HOME/neo4j/data:/data \
    -v $HOME/neo4j/logs:/logs \
    neo4j:latest
```

### 3. Docker Setup
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker
```

## Verification

### 1. Environment Check
```bash
# Check installations
node --version
npm --version
forge --version
solc --version
git --version

# Check project setup
forge build
forge test
```

### 2. Network Check
```bash
# Test network connection
cast block --rpc-url $RPC_URL latest
```

### 3. Tool Check
```bash
# Test IPFS if installed
ipfs --version
ipfs swarm peers

# Test Neo4j if installed
curl http://localhost:7474
```

## Troubleshooting

### 1. Common Issues
- Node version conflicts
- Dependency installation failures
- Network connectivity issues
- Permission problems

### 2. Solutions
- Use nvm for Node.js version management
- Clear cache and reinstall dependencies
- Check firewall settings
- Use sudo when required

### 3. Support Resources
- GitHub Issues
- Discord community
- Stack Exchange
- Documentation

## Best Practices

### 1. Development Environment
- Use version control
- Maintain clean workspace
- Regular updates
- Backup configuration

### 2. Code Management
- Follow style guide
- Use linting tools
- Regular commits
- Clear documentation

### 3. Security
- Secure private keys
- Use .env for secrets
- Regular backups
- Access control 