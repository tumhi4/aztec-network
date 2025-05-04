#!/bin/bash

set -e

INSTALL_DIR="aztec-sequencer"
echo "📁 Creating project directory: $INSTALL_DIR"
mkdir -p $INSTALL_DIR && cd $INSTALL_DIR

read -p "🔗 Enter Ethereum RPC URL (e.g. https://sepolia.rpc.url): " ETHEREUM_HOSTS
read -p "🔗 Enter Beacon RPC URL (e.g. https://beacon.rpc.url): " L1_CONSENSUS_HOST_URLS
read -p "🔑 Enter your Ethereum Private Key (0x...): " VALIDATOR_PRIVATE_KEY
read -p "🏦 Enter your Ethereum Address (0x...): " VALIDATOR_ADDRESS

P2P_IP=$(curl -s ipv4.icanhazip.com)
echo "🌍 Detected Public IP: $P2P_IP"

# Step 0: Install Dependencies
echo "🔧 Installing system dependencies..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf \
  tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang \
  bsdmainutils ncdu unzip ca-certificates gnupg

# Step 1: Install Aztec CLI Tools
echo "🧰 Installing Aztec CLI tools..."
bash -i <(curl -s https://install.aztec.network)
echo 'export PATH="$PATH:/root/.aztec/bin"' >> ~/.bashrc && source ~/.bashrc

# Create .env file
echo "📄 Creating .env file..."
cat <<EOF > .env
ETHEREUM_HOSTS=$ETHEREUM_HOSTS
L1_CONSENSUS_HOST_URLS=$L1_CONSENSUS_HOST_URLS
VALIDATOR_PRIVATE_KEY=$VALIDATOR_PRIVATE_KEY
VALIDATOR_ADDRESS=$VALIDATOR_ADDRESS
P2P_IP=$P2P_IP
EOF

echo "✅ .env file created."

# Create systemd service using CLI (not Docker)
read -p "🛠️ Do you want to set this up as a systemd service using Aztec CLI? (y/n): " SETUP_SYSTEMD

if [[ "$SETUP_SYSTEMD" =~ ^[Yy]$ ]]; then
  echo "📦 Creating systemd service file..."
  sudo tee /etc/systemd/system/aztec-sequencer.service > /dev/null <<EOF
[Unit]
Description=Aztec Sequencer Node
After=network.target

[Service]
WorkingDirectory=/root/$INSTALL_DIR
EnvironmentFile=/root/$INSTALL_DIR/.env
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
  sudo systemctl daemon-reexec
  sudo systemctl daemon-reload
  sudo systemctl enable aztec-sequencer
  sudo systemctl start aztec-sequencer
  echo "✅ aztec-sequencer systemd service is now running using CLI."
else
  echo "🚀 You can manually run the node with Aztec CLI using the following command:"
  echo "aztec start --node --archiver --sequencer \"
  echo "  --network alpha-testnet \"
  echo "  --l1-rpc-urls=$ETHEREUM_HOSTS \"
  echo "  --l1-consensus-host-urls=$L1_CONSENSUS_HOST_URLS \"
  echo "  --sequencer.validatorPrivateKey=$VALIDATOR_PRIVATE_KEY \"
  echo "  --sequencer.coinbase=$VALIDATOR_ADDRESS \"
  echo "  --p2p.p2pIp=$P2P_IP \"
  echo "  --p2p.maxTxPoolSize=1000000000"
fi
