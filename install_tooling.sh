#!/bin/sh
set -e

DEVSPACE_VERSION="latest"

# Detect OS type
if [ -f /etc/alpine-release ]; then
    OS_TYPE="alpine"
else
    OS_TYPE="debian"
fi

echo "Detected OS: $OS_TYPE"

# Install base dependencies based on OS
if [ "$OS_TYPE" = "alpine" ]; then
    apk add --no-cache \
        curl vim wget bash iputils bind-tools git nodejs npm openssl \
        jq sudo ca-certificates gnupg unzip gzip tar bash-completion \
        python3 py3-pip docker-cli docker-compose
else
    apt-get update && apt-get -y install \
        curl vim wget bash inetutils-ping dnsutils git openssl \
        jq sudo ca-certificates gnupg lsb-release unzip gzip tar bash-completion \
        python3 python3-pip docker.io docker-compose
    
    # Install Node.js for Debian-based systems
    curl -sL https://deb.nodesource.com/setup_lts.x -o nodesource_setup.sh
    bash nodesource_setup.sh
    apt-get install -y nodejs
    rm nodesource_setup.sh
fi

# Create directories
mkdir -p /usr/local/bin
mkdir -p /home/vscode/.local/bin

# Install npm global packages
# Skip tools if they already exist
if ! command -v yarn >/dev/null 2>&1; then
    npm install -g yarn
fi

if ! command -v tsc >/dev/null 2>&1; then
    npm install -g typescript tsc-watch
fi

npm install -g @anthropic-ai/claude-code@latest

if ! command -v devspace >/dev/null 2>&1; then
    npm install -g devspace@latest
fi

npm install -g cdk8s-cli@latest

# Detect architecture
ARCH_SHORT="arm64"
ARCH=$(arch)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_SHORT="amd64"
fi

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH_SHORT/kubectl"
chmod +x kubectl
install -p kubectl /usr/local/bin/
rm kubectl

# Install helm
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
chmod +x get_helm.sh
./get_helm.sh
rm get_helm.sh

# Install devspace (skip if already installed via npm)
if ! command -v devspace >/dev/null 2>&1; then
    curl -s "https://api.github.com/repos/loft-sh/devspace/releases/$DEVSPACE_VERSION" | \
        grep "browser_download_url.*devspace-linux-$ARCH_SHORT" | \
        cut -d : -f 2,3 | tr -d \" | grep -v '.sha256' | \
        wget -O devspace -qi -
    chmod +x devspace
    install -p devspace /usr/local/bin/
    rm devspace
fi

devspace add plugin https://github.com/loft-sh/loft-devspace-plugin || true

# Install loft CLI
curl -s https://api.github.com/repos/loft-sh/loft/releases/latest | \
    grep "browser_download_url.*loft-linux-$ARCH_SHORT" | \
    cut -d : -f 2,3 | tr -d \" | grep -v '.sha256' | \
    wget -O loft -qi -
chmod +x loft
install -p loft /usr/local/bin/
rm loft

# Install idpbuilder
if [ "$OS_TYPE" = "alpine" ]; then
    # For Alpine, we need to download the binary directly
    wget -O /tmp/install-idpbuilder.sh https://raw.githubusercontent.com/cnoe-io/idpbuilder/main/hack/install.sh
    sed -i 's|sudo ||g' /tmp/install-idpbuilder.sh  # Remove sudo commands for Alpine
    sh /tmp/install-idpbuilder.sh
    rm /tmp/install-idpbuilder.sh
else
    curl -fsSL https://raw.githubusercontent.com/cnoe-io/idpbuilder/main/hack/install.sh | bash
fi

# Install dagger
curl -fsSL https://dl.dagger.io/dagger/install.sh | sh

# Install uv (Python package manager)
if [ "$OS_TYPE" = "alpine" ]; then
    # uv might have issues on Alpine, install via pip as fallback
    pip3 install uv || echo "Warning: uv installation failed on Alpine"
else
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi

# Install vcluster
curl -L "https://github.com/loft-sh/vcluster/releases/latest/download/vcluster-linux-$ARCH_SHORT" \
    -o /usr/local/bin/vcluster
chmod +x /usr/local/bin/vcluster

# Install Argo Workflows CLI
ARGO_VERSION=$(curl -s https://api.github.com/repos/argoproj/argo-workflows/releases | \
    grep '"tag_name":' | grep -E 'v3\.[0-9]+\.[0-9]+' | head -1 | sed -E 's/.*"v([^"]+)".*/\1/')
if [ -n "$ARGO_VERSION" ]; then
    curl -sLO "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_VERSION}/argo-linux-$ARCH_SHORT.gz"
    gunzip "argo-linux-$ARCH_SHORT.gz"
    chmod +x "argo-linux-$ARCH_SHORT"
    mv "argo-linux-$ARCH_SHORT" /usr/local/bin/argo
fi

# Install ArgoCD CLI
curl -sSL -o /usr/local/bin/argocd \
    "https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-$ARCH_SHORT"
chmod +x /usr/local/bin/argocd

# Install Azure Workload Identity CLI (azwi)
AZWI_VERSION=$(curl -s https://api.github.com/repos/Azure/azure-workload-identity/releases/latest | \
    grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
if [ -n "$AZWI_VERSION" ]; then
    AZWI_URL="https://github.com/Azure/azure-workload-identity/releases/download/${AZWI_VERSION}/azwi-${AZWI_VERSION}-linux-${ARCH_SHORT}.tar.gz"
    curl -sLO "$AZWI_URL"
    tar -xzf "azwi-${AZWI_VERSION}-linux-${ARCH_SHORT}.tar.gz"
    chmod +x azwi
    mv azwi /usr/local/bin/azwi
    rm -f "azwi-${AZWI_VERSION}-linux-${ARCH_SHORT}.tar.gz"
fi

# Install yq
wget -qO /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_$ARCH_SHORT"
chmod +x /usr/local/bin/yq

# Install kind
KIND_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kind/releases/latest | \
    grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
curl -Lo /usr/local/bin/kind "https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-$ARCH_SHORT"
chmod +x /usr/local/bin/kind

# Create MCP configuration script
cat > /usr/local/bin/configure-mcp.sh << 'EOF'
#!/bin/bash
# Configure MCP servers for claude-code
claude mcp add-json server-fetch --scope user '{
  "command": "uvx",
  "args": [
    "mcp-server-fetch"
  ]
}'

claude mcp add --transport sse context7 https://mcp.context7.com/sse
claude mcp add -t http nx-mcp http://localhost:9445/mcp
claude mcp add github -- docker run -i --rm -e GITHUB_PERSONAL_ACCESS_TOKEN ghcr.io/github/github-mcp-server
claude mcp add --transport http grep https://mcp.grep.app

echo "MCP servers configured successfully!"
EOF
chmod +x /usr/local/bin/configure-mcp.sh

# Create welcome script
cat > /usr/local/bin/welcome.sh << 'EOF'
#!/bin/bash
echo "DevSpace Enhanced Container - Tools Installed:"
echo "  - kubectl, helm, devspace, loft"
echo "  - idpbuilder"
echo "  - dagger"
echo "  - claude-code (with MCP servers)"
echo "  - vcluster"
echo "  - argo (Workflows CLI)"
echo "  - argocd"
echo "  - azwi (Azure Workload Identity)"
echo "  - cdk8s-cli"
echo "  - jq, yq"
echo "  - kind"
echo "  - docker, docker-compose"
echo "  - typescript, tsc-watch"
echo ""
echo "To configure MCP servers for claude-code, run: configure-mcp.sh"
EOF
chmod +x /usr/local/bin/welcome.sh

# Display completion message
echo "All tools installation completed!"
welcome.sh