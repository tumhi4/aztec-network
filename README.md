# 🚀 Aztec Sequencer Node Setup – Comprehensive Guide

This guide walks you through setting up a **Sequencer Node** on the Aztec Network testnet and earning the `Apprentice` role.

---

## 🔍 Overview of Node Roles

* **Sequencer**: Plays a vital role in proposing blocks, validating them, and participating in upgrade governance.

---

## 📜 Role Requirements

To learn about different roles and responsibilities, check the official Aztec Discord:
👉 [Role Details Here](https://discord.com/channels/1144692727120937080/1367196595866828982/1367323893324582954)

---

## 💻 System Requirements

* **Recommended Specs**: 8-core CPU, 16GB RAM, SSD with 100GB+ space
* **Minimum for VPS**: 4-core CPU, 8GB RAM

---

## ⚙️ Step 1: System Dependencies

Start by installing the required tools and libraries:

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install curl iptables build-essential git wget lz4 jq make gcc nano automake autoconf tmux htop nvme-cli \
libgbm1 pkg-config libssl-dev libleveldb-dev tar clang bsdmainutils ncdu unzip -y
```

### Install Docker:

```bash
for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done
sudo apt install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo docker run hello-world
sudo systemctl enable docker && sudo systemctl restart docker
```

---

## 🪰 Step 2: Install Aztec CLI Tools

```bash
bash -i <(curl -s https://install.aztec.network)
```

If prompted:

```
The directory /root/.aztec/bin is not in your PATH.
Add it to /root/.bash_profile to make the aztec binaries accessible? (y/n)
```

Type `y`, or manually add it later:

```bash
echo 'export PATH="$PATH:/root/.aztec/bin"' >> ~/.bashrc && source ~/.bashrc
```

Test:

```bash
aztec
```

---

## 🔄 Step 3: Update to Latest Testnet

```bash
aztec-up alpha-testnet
```

---

## 🌐 Step 4: RPC Provider Setup

You’ll need both Execution and Consensus layer URLs:

* **Execution (L1)**: [Alchemy (Free)](https://dashboard.alchemy.com/)
* **Consensus (Beacon)**: [drpc (Free)](https://drpc.org/)
* **Optional (Premium)**: [Ankr](https://ankr.com/)

You may also self-host Geth + Prysm if needed.

---

## 🔑 Step 5: Prepare Ethereum Wallet

* Install a wallet like MetaMask
* Export and **securely store**:

  * `Private Key`
  * `Public Address`

---

## ⛽ Step 6: Get Sepolia ETH (Testnet)

Faucets to use:

* [Alchemy](https://sepoliafaucet.com/)
* [QuickNode](https://faucet.quicknode.com/ethereum/sepolia)
* [Infura](https://www.infura.io/faucet/sepolia)
* [Chainlink](https://faucets.chain.link/sepolia)

> ⚠️ Most faucets require authentication (GitHub, Twitter, or Google).

---

## 🌍 Step 7: Get Server Public IP

```bash
curl ipv4.icanhazip.com
```

---

## 🗰️ Step 8: Configure `.env`

Create a `.env` file in your project folder:

```env
ETHEREUM_HOSTS=https://sepolia.rpc.url
L1_CONSENSUS_HOST_URLS=https://beacon.rpc.url
VALIDATOR_PRIVATE_KEY=0xYourPrivateKey
VALIDATOR_ADDRESS=0xYourAddress
P2P_IP=YourServerPublicIP
```

---

## 💠 Step 9: Docker Compose Setup

Create `docker-compose.yml`:

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

Launch:

```bash
docker compose --env-file .env up -d
```

---

## ⏳ Step 10: Wait for Full Sync

This might take a few minutes depending on your node's performance.

---

## 🏁 Step 11: Apprentice Role Verification

1. Get current block:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getL2Tips","params":[],"id":67}' \
http://localhost:8080 | jq -r ".result.proven.number"
```

2. Generate proof:

```bash
curl -s -X POST -H 'Content-Type: application/json' \
-d '{"jsonrpc":"2.0","method":"node_getArchiveSiblingPath","params":["BLOCK","BLOCK"],"id":67}' \
http://localhost:8080 | jq -r ".result"
```

3. Join Discord and use the command:

```
/operator start
```

Enter:

* `address`: Your wallet address
* `block-number`: From step 1
* `proof`: From step 2

---

## 📝 Step 12: Register Your Validator

```bash
aztec add-l1-validator \
  --l1-rpc-urls RPC_URL \
  --private-key your-private-key \
  --attester your-validator-address \
  --proposer-eoa your-validator-address \
  --staking-asset-handler 0xF739D03e98e23A7B65940848aBA8921fF3bAc4b2 \
  --l1-chain-id 11155111
```

> Limited to 10 validators per day.

---

## 📊 Step 13: Validator Status

Check here:
👉 [https://aztecscan.xyz/validators](https://aztecscan.xyz/validators)

---

## 🔒 Step 14: (Optional) Firewall Rules

```bash
ufw allow 22
ufw allow ssh
ufw allow 40400
ufw allow 8080
ufw enable
```

---

🎉 **You're all set!** Your Sequencer node is live and syncing. Best of luck as you explore the Aztec ecosystem!
