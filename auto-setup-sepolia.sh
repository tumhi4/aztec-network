#!/bin/bash

# 🚀 Auto Setup Sepolia Geth + Lighthouse for Sequencer
# Assumes system has at least 1TB SSD, 16GB RAM

set -e

# === DEPENDENCY CHECK & INSTALL IF MISSING ===
echo ">>> Checking system dependencies..."
REQUIRED_CMDS=(docker "docker compose" openssl curl)
APT_PACKAGES=(docker.io docker-compose openssl curl)
MISSING=()

for i in "${!REQUIRED_CMDS[@]}"; do
  CMD_NAME=$(echo ${REQUIRED_CMDS[$i]} | awk '{print $1}')
  if ! command -v $CMD_NAME &> /dev/null; then
    MISSING+=(${APT_PACKAGES[$i]})
  fi
done

if [ ${#MISSING[@]} -ne 0 ]; then
  echo "⛔ Missing dependencies: ${MISSING[@]}"
  echo "⚙️  Installing missing dependencies..."
  sudo apt-get update
  sudo apt-get install -y ${MISSING[@]}
fi

# === CONFIG ===
DATA_DIR="$HOME/sepolia-node"
GETH_DIR="$DATA_DIR/geth"
LIGHTHOUSE_DIR="$DATA_DIR/lighthouse"
JWT_FILE="$DATA_DIR/jwt.hex"
COMPOSE_FILE="$DATA_DIR/docker-compose.yml"

# === STEP 1: PREPARE FOLDERS ===
echo ">>> Creating data directories..."
mkdir -p "$GETH_DIR" "$LIGHTHOUSE_DIR"

# === STEP 2: GENERATE JWT SECRET ===
echo ">>> Generating JWT secret..."
openssl rand -hex 32 > "$JWT_FILE"

# === STEP 3: WRITE docker-compose.yml ===
echo ">>> Writing docker-compose.yml..."
cat > "$COMPOSE_FILE" <<EOF
version: '3.8'
services:
  geth:
    image: ethereum/client-go:stable
    container_name: geth
    restart: unless-stopped
    volumes:
      - $GETH_DIR:/root/.ethereum
      - $JWT_FILE:/root/jwt.hex
    ports:
      - "8545:8545"
      - "30303:30303"
      - "8551:8551"
    command: >
      --sepolia
      --http --http.addr 0.0.0.0 --http.api eth,web3,net,engine
      --authrpc.addr 0.0.0.0 --authrpc.port 8551
      --authrpc.jwtsecret /root/jwt.hex
      --authrpc.vhosts=*
      --http.corsdomain="*"

  lighthouse:
    image: sigp/lighthouse:latest
    container_name: lighthouse
    restart: unless-stopped
    volumes:
      - $LIGHTHOUSE_DIR:/root/.lighthouse
      - $JWT_FILE:/root/jwt.hex
    ports:
      - "5052:5052"
    depends_on:
      - geth
    command: >
      lighthouse bn
      --network sepolia
      --execution-endpoint http://geth:8551
      --execution-jwt /root/jwt.hex
      --checkpoint-sync-url https://sepolia.checkpoint-sync.ethpandaops.io
      --http
      --http-address 0.0.0.0
EOF

# === STEP 4: START SERVICES ===
echo ">>> Freeing port 8545 if occupied..."
if lsof -i :8545 >/dev/null 2>&1; then
  echo ">>> Port 8545 is in use. Attempting to free it..."
  sudo fuser -k 8545/tcp || true
fi

echo ">>> Starting Sepolia node with Docker Compose..."
cd "$DATA_DIR"
docker compose up -d

echo ">>> ✅ Setup complete. Use the following commands to check status:"
echo "  docker logs -f geth"
echo "  docker logs -f lighthouse"
echo "  curl -s -X POST http://localhost:8545 -H 'Content-Type: application/json' -d '{\"jsonrpc\":\"2.0\",\"method\":\"eth_syncing\",\"params\":[],\"id\":1}'"
echo "  curl http://localhost:5052/eth/v1/node/health"
