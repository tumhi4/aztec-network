#!/bin/bash

set -e

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root or with sudo."
  exit 1
fi

INSTALL_DIR="aztec-sequencer"
echo "📁 Creating project directory: $INSTALL_DIR"
mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

ENV_FILE="/root/$INSTALL_DIR/.env"

if [ -f "$ENV_FILE" ]; then
  echo "🔍 Validating existing .env file..."
  source_env_ok=true
  while IFS='=' read -r key value; do
    if [[ -z "$value" ]]; then
      source_env_ok=false
      break
    fi
  done < <(grep -v '^#' "$ENV_FILE")

  if [ "$source_env_ok" = true ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
    if [ -n "$ETHEREUM_HOSTS" ] && [ -n "$L1_CONSENSUS_HOST_URLS" ] && [ -n "$VALIDATOR_PRIVATE_KEY" ] && [ -n "$VALIDATOR_ADDRESS" ] && [ -n "$P2P_IP" ]; then
      read -p "🔁 Found existing .env file with valid values. Do you want to reuse it? (y/n): " REUSE_ENV
      if [[ "$REUSE_ENV" =~ ^[Yy]$ ]]; then
        echo "✅ Reusing existing .env file."
      else
        unset ETHEREUM_HOSTS L1_CONSENSUS_HOST_URLS VALIDATOR_PRIVATE_KEY VALIDATOR_ADDRESS P2P_IP
      fi
    fi
  else
    echo "⚠️ .env file contains invalid or empty values. Please re-enter."
    unset ETHEREUM_HOSTS L1_CONSENSUS_HOST_URLS VALIDATOR_PRIVATE_KEY VALIDATOR_ADDRESS P2P_IP
  fi
fi

if [ -z "$ETHEREUM_HOSTS" ]; then read -p "🔗 Enter Ethereum RPC URL (e.g. https://sepolia.rpc.url): " ETHEREUM_HOSTS; fi
if [ -z "$L1_CONSENSUS_HOST_URLS" ]; then read -p "🔗 Enter Beacon RPC URL (e.g. https://beacon.rpc.url): " L1_CONSENSUS_HOST_URLS; fi
if [ -z "$VALIDATOR_PRIVATE_KEY" ]; then read -p "🔑 Enter your Ethereum Private Key (0x...): " VALIDATOR_PRIVATE_KEY; fi
if [ -z "$VALIDATOR_ADDRESS" ]; then read -p "🏦 Enter your Ethereum Address (0x...): " VALIDATOR_ADDRESS; fi
if [ -z "$P2P_IP" ]; then P2P_IP=$(curl -s ipv4.icanhazip.com); fi

echo "🌍 Using Public IP: $P2P_IP"

# Step 0: Install Dependencies
echo "🔧 Installing system dependencies..."
apt update && apt upgrade -y
apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf \
  tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang \
  bsdmainutils ncdu unzip ca-certificates gnupg

# Step 1: Install Docker (Required for Aztec CLI)
echo "🐳 Installing Docker..."
if ! command -v docker &> /dev/null; then
  for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do apt-get remove -y $pkg; done
  install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo \"$VERSION_CODENAME\") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update
  apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  docker run hello-world
  systemctl enable docker && systemctl restart docker
else
  echo "✅ Docker is already installed. Skipping installation."
fi

# Step 2: Install or Update Aztec CLI Tools
if ! command -v aztec &> /dev/null; then
  echo "🧰 Installing Aztec CLI tools..."
  bash -i <(curl -s https://install.aztec.network)
else
  echo "🔄 Aztec CLI already installed. Updating to latest testnet version..."
  /root/.aztec/bin/aztec-up alpha-testnet || aztec-up alpha-testnet
fi
echo 'export PATH="$PATH:/root/.aztec/bin"' >> ~/.bashrc && source ~/.bashrc

# Create .env file
echo "📄 Creating .env file..."
cat <<EOF > "$ENV_FILE"
ETHEREUM_HOSTS=$ETHEREUM_HOSTS
L1_CONSENSUS_HOST_URLS=$L1_CONSENSUS_HOST_URLS
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS
P2P_IP=$P2P_IP
EOF

echo "✅ .env file saved."

# Create systemd service using CLI (not Docker)
read -p "🛠️ Do you want to set this up as a systemd service using Aztec CLI? (y/n): " SETUP_SYSTEMD

if [[ "$SETUP_SYSTEMD" =~ ^[Yy]$ ]]; then
  echo "📦 Creating systemd service file..."
  tee /etc/systemd/system/aztec-sequencer.service > /dev/null <<EOF
[Unit]
Description=Aztec Sequencer Node
After=network.target

[Service]
WorkingDirectory=/root/$INSTALL_DIR
EnvironmentFile=/root/$INSTALL_DIR/.env
Environment=HOME=/root
ExecStart=/root/.aztec/bin/aztec \
  start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls=\${ETHEREUM_HOSTS} \
  --l1-consensus-host-urls=\${L1_CONSENSUS_HOST_URLS} \
  --sequencer.validatorPrivateKey=\${VALIDATOR_PRIVATE_KEY} \
  --sequencer.coinbase=\${VALIDATOR_ADDRESS} \
  --p2p.p2pIp=\${P2P_IP} \
  --p2p.maxTxPoolSize=1000000000
Restart=always
RestartSec=5s
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  echo "🔁 Reloading systemd daemon and enabling service..."
  systemctl daemon-reexec
  systemctl daemon-reload
  systemctl enable aztec-sequencer
  systemctl start aztec-sequencer
  echo "✅ aztec-sequencer systemd service is now running using CLI."
else
  echo "🚀 You can manually run the node with Aztec CLI using the following command:"
  echo "aztec start --node --archiver --sequencer \
  --network alpha-testnet \
  --l1-rpc-urls=$ETHEREUM_HOSTS \
  --l1-consensus-host-urls=$L1_CONSENSUS_HOST_URLS \
  --sequencer.validatorPrivateKey=$VALIDATOR_PRIVATE_KEY \
  --sequencer.coinbase=$VALIDATOR_ADDRESS \
  --p2p.p2pIp=$P2P_IP \
  --p2p.maxTxPoolSize=1000000000"
fi
