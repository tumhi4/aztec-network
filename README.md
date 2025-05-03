# Aztec Network Sequencer Node Guide

A step-by-step guide for setting up a **Sequencer Node** on the Aztec Network testnet and earning the `Apprentice` role.

---

## 🧠 Node Types in Aztec Testnet

* **Sequencer**: Proposes and validates blocks, participates in voting on upgrades.

---

## 🔰 Roles Info

See the full roles information here: [Start Here (Discord)](https://discord.com/channels/1144692727120937080/1367196595866828982/1367323893324582954)

---

## 💻 Hardware Requirements

* **Sequencer Node**: 8 cores CPU, 16GB RAM, 100GB+ SSD

---

## ☁️ For VPS Users

You can use a VPS with 4-core CPU & 8GB RAM.

---

## 🔧 Step 1: Install Dependencies

```bash
sudo apt-get update && sudo apt-get upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip libleveldb-dev -y
```

### Install Docker:

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \ 
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \ 
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world
sudo systemctl enable docker && sudo systemctl restart docker
```

---

## 🧰 Step 2: Install Aztec Tools

```bash
bash -i <(curl -s https://install.aztec.network)
```

Restart your terminal, then verify:

```bash
aztec
```

---

## ♻️ Step 3: Update Aztec

```bash
aztec-up alpha-testnet
```

---

## 🔗 Step 4: Obtain RPC URLs

* **RPC URL**: [Alchemy (Free)](https://dashboard.alchemy.com/)
* **BEACON URL**: [drpc (Free)](https://drpc.org/)
* **Paid Option**: [Ankr](https://www.ankr.com/)

You may also run your own Geth & Prysm nodes if preferred.

---

## 🔐 Step 5: Generate Ethereum Keys

* Get an EVM wallet (Metamask or similar)
* Save both **Private Key** and **Public Address**

---

## ⛽ Step 6: Get Sepolia ETH

Here are a few recommended Sepolia faucets you can use to fund your wallet:

* [Alchemy Sepolia Faucet](https://sepoliafaucet.com/)
* [QuickNode Sepolia Faucet](https://faucet.quicknode.com/ethereum/sepolia)
* [Infura Sepolia Faucet](https://www.infura.io/faucet/sepolia)
* [Chainlink Sepolia Faucet](https://faucets.chain.link/sepolia)

## Make sure to have your EVM wallet address ready (e.g., from MetaMask). Most faucets require a GitHub, X (Twitter), or Google login.

## 🌍 Step 7: Get Public IP

```bash
curl ipv4.icanhazip.com
```

Save the result.

---

---

## 🚀 Step 9: Start Sequencer Node with Docker Compose

### Create a `.env` file:

```env
ETHEREUM_HOSTS=https://sepolia.rpc.url
L1_CONSENSUS_HOST_URLS=https://beacon.rpc.url
VALIDATOR_PRIVATE_KEY=0xYourPrivateKey
VALIDATOR_ADDRESS=0xYourAddress
P2P_IP=YourServerIP
```

### Create `docker-compose.yml`:

```yaml
services:
  aztec-node:
    container_name: aztec-sequencer
    image: aztecprotocol/aztec:alpha-testnet
    restart: unless-stopped
    environment:
      ETHEREUM_HOSTS: ${ETHEREUM_HOSTS}
      L1_CONSENSUS_HOST_URLS: ${L1_CONSENSUS_HOST_URLS}
      VALIDATOR_PRIVATE_KEY: ${VALIDATOR_PRIVATE_KEY}
      P2P_IP: ${P2P_IP}
      LOG_LEVEL: debug
    entrypoint: >
      sh -c 'node --no-warnings /usr/src/yarn-project/aztec/dest/bin/index.js start --network alpha-testnet --node --archiver --sequencer'
    ports:
      - 40400:40400/tcp
      - 40400:40400/udp
      - 8080:8080
    volumes:
      - ./data:/data
    network_mode: host

volumes:
  data:
```

### Start your node:

```bash
docker compose --env-file .env up -d
```

---

## 🔄 Step 10: Sync Node

Takes a few minutes. Wait until fully synced.

---

## 🏅 Step 11: Get Apprentice Role

1. Get the latest block:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
http://localhost:8080 | jq -r ".result.proven.number"
```

2. Generate sync proof:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK","BLOCK"],"id":67}' \
http://localhost:8080 | jq -r ".result"
```

3. On Discord, type:

```
/operator start
```

Fill in:

* `address`: Your wallet address
* `block-number`: From Step 1
* `proof`: From Step 2 (base64 string)

---

## 📝 Step 12: Register Validator

```bash
aztec add-l1-validator \
  --l1-rpc-urls RPC_URL \
  --private-key your-private-key \
  --attester your-validator-address \
  --proposer-eoa your-validator-address \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```

Only 10 registrations are allowed per day.

---

## 🔍 Step 13: Validator Status

Check your validator here: [aztecscan.xyz/validators](https://aztecscan.xyz/validators)

---

## 🔒 (Optional) Step 14: Configure Firewall

```bash
ufw allow 22
ufw allow ssh
ufw allow 40400
ufw allow 8080
ufw enable
```

---

Happy Sequencing! 🎯
