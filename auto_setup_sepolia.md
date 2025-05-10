# 📘 Guide: Auto Setup Sepolia RPC + Beacon Node for Sequencer

This guide walks you through setting up a Sepolia Ethereum node (Geth + Lighthouse) using an automated script. Ideal for running a sequencer backend that requires both RPC and Beacon API access.

---

## ⚙️ System Requirements

- **Disk:** 1TB+ SSD
- **RAM:** 16GB+
- **OS:** Ubuntu 20.04+ (or compatible Linux distro)
- **Tools:** Docker, Docker Compose, `curl`, `openssl`

---

## 🚀 Setup Instructions

### 1. Download the setup script

Save the following script to a file named `auto-setup-sepolia.sh`:

```bash
# Paste the full script from above here
```

Or clone from GitHub (if you push it there):
```bash
git clone https://github.com/your-repo/sepolia-node-setup.git
cd sepolia-node-setup
chmod +x auto-setup-sepolia.sh
```

### 2. Run the script

```bash
bash auto-setup-sepolia.sh
```

This will:
- Create folder structure at `~/sepolia-node`
- Generate a valid `jwt.hex`
- Write a production-ready `docker-compose.yml`
- Launch Geth + Lighthouse for Sepolia

---

## ✅ Verify

### Check sync progress:
```bash
curl -s -X POST http://localhost:8545 \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_syncing","params":[],"id":1}'
```

### Check Beacon API health:
```bash
curl http://localhost:5052/eth/v1/node/health
```

---

## 🧠 Notes

- The sync process may take several hours to complete.
- Ensure enough disk space (500GB+) is available.
- Once `eth_syncing` returns `false`, your RPC is fully operational.
- You can now connect your L2 sequencer to `localhost:8551` (Engine API).

---

## 🔄 Restart / Monitor

```bash
cd ~/sepolia-node

docker compose logs -f geth

docker compose logs -f lighthouse
```

To restart:
```bash
docker compose restart
```

To stop:
```bash
docker compose down
```

---

Built with ❤️ for L2 sequencers.
