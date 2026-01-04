#!/bin/bash
set -e

# Detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)
        GO_ARCH="amd64"
        AWS_ARCH="x86_64"
        KUBECTL_ARCH="amd64"
        ;;
    aarch64|arm64)
        GO_ARCH="arm64"
        AWS_ARCH="aarch64"
        KUBECTL_ARCH="arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

echo "Installing packages for Ubuntu/Debian..."
echo "Detected architecture: $ARCH (Go: $GO_ARCH, AWS: $AWS_ARCH, kubectl: $KUBECTL_ARCH)"

# Update package list
sudo apt update

# Essential tools
sudo apt install -y \
    build-essential \
    curl \
    fd-find \
    git \
    jq \
    neovim \
    postgresql-client \
    ripgrep \
    tmux \
    tree \
    unzip \
    wget \
    zsh

# Prompt is built into zshrc - no external dependencies needed

# NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

# Go (latest stable)
GO_VERSION="1.23.4"
wget "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
rm "go${GO_VERSION}.linux-${GO_ARCH}.tar.gz"
export PATH=$PATH:/usr/local/go/bin

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install -y terraform

# AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${KUBECTL_ARCH}/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# .NET SDK (optional - uncomment if needed)
# wget https://dot.net/v1/dotnet-install.sh -O dotnet-install.sh
# chmod +x dotnet-install.sh
# ./dotnet-install.sh --channel 8.0

echo "Linux package installation complete!"
