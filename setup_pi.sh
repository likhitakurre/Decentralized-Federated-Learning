# Decentralized Federated Learning on Edge Devices

A fully-shippable system for training ML models collaboratively across real edge devices
(Raspberry Pi, Jetson Nano, any Linux SBC) using a gossip communication protocol — **no
central server, no raw data sharing**.

```
┌──────────┐    gossip     ┌──────────┐    gossip     ┌──────────┐
│  node_0  │◄─────────────►│  node_1  │◄─────────────►│  node_2  │
│  RPi 4   │               │  RPi 4   │               │  RPi 4   │
│ MNIST 0,1│               │ MNIST 2,3│               │ MNIST 4,5│
└──────────┘               └──────────┘               └──────────┘
      ▲                                                      ▲
      └──────────────────── gossip ─────────────────────────┘
```

---

## Table of Contents

1. [Architecture](#architecture)
2. [Quick Start (local, 5 nodes)](#quick-start-local)
3. [Quick Start (Docker)](#quick-start-docker)
4. [Deploy on Raspberry Pi](#deploy-on-raspberry-pi)
5. [Dashboard](#dashboard)
6. [API Reference](#api-reference)
7. [Configuration](#configuration)
8. [Running Tests](#running-tests)
9. [Project Structure](#project-structure)
10. [How It Works](#how-it-works)

---

## Architecture

```
decentralized-fl/
├── node/               # Edge node (runs on each device)
│   ├── main.py         # FastAPI application
│   ├── config.py       # All config via env vars
│   ├── model.py        # PyTorch MLP (MNIST)
│   ├── data_loader.py  # Non-IID / IID MNIST partition
│   ├── trainer.py      # Local SGD training loop
│   ├── aggregator.py   # FedAvg model aggregation
│   └── gossip.py       # Push-pull gossip protocol
├── dashboard/
│   └── index.html      # Real-time monitoring UI (pure HTML/JS)
├── scripts/
│   ├── start_network.py     # Launch N nodes locally
│   ├── simulate_failure.py  # Kill/restart nodes for fault-tolerance demo
│   └── evaluate.py          # Convergence report + centralized baseline
├── tests/
│   └── test_fl_node.py      # Unit + async tests
├── docker/
│   ├── Dockerfile
│   └── docker-compose.yml   # 5 nodes + dashboard
└── requirements.txt
```

### Key design decisions

| Concern | Choice | Reason |
|---|---|---|
| Communication | Push-pull gossip (HTTP) | No central broker; nodes exchange directly |
| Aggregation | FedAvg / Weighted FedAvg | Simple, converges well in practice |
| Model | 3-layer MLP | Fast to train on CPU; ~235k params |
| Data | MNIST (non-IID by digit class) | Realistic heterogeneity simulation |
| Transport | FastAPI + aiohttp | Async I/O; low overhead on Pi |

---

## Quick Start (Local)

**Requirements:** Python 3.10+, 4 GB RAM (for 5 nodes), ~200 MB disk (MNIST)

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Start 5 nodes on localhost:8000–8004
python scripts/start_network.py --nodes 5

# 3. Open the dashboard
open dashboard/index.html
# (or navigate to file:///path/to/dashboard/index.html)

# 4. Watch metrics in the terminal
python scripts/evaluate.py --watch
```

The nodes will automatically:
- Download MNIST on first run
- Start local training every 20 seconds
- Exchange model weights via gossip every 15 seconds
- Converge toward a shared global model

---

## Quick Start (Docker)

**Requirements:** Docker + Docker Compose

```bash
# Build and start 5 nodes + dashboard
docker compose -f docker/docker-compose.yml up --build

# Dashboard: http://localhost:3000
# Node APIs: http://localhost:8000 … http://localhost:8004
```

---

## Deploy on Raspberry Pi

### Prerequisites (each Pi)

```bash
sudo apt update && sudo apt install -y python3-pip git
pip3 install -r requirements.txt
```

### One-command start per device

```bash
# On Pi #0 (IP: 192.168.1.100)
NODE_ID=node_0 \
PORT=8000 \
PEERS=http://192.168.1.101:8000,http://192.168.1.102:8000,http://192.168.1.103:8000,http://192.168.1.104:8000 \
DATA_PARTITION=0 \
python node/main.py

# On Pi #1 (IP: 192.168.1.101)
NODE_ID=node_1 \
PORT=8000 \
PEERS=http://192.168.1.100:8000,http://192.168.1.102:8000,http://192.168.1.103:8000,http://192.168.1.104:8000 \
DATA_PARTITION=1 \
python node/main.py
```

### Systemd service (auto-start on boot)

```ini
# /etc/systemd/system/fl-node.service
[Unit]
Description=FL Edge Node
After=network.target

[Service]
User=pi
WorkingDirectory=/home/pi/decentralized-fl
EnvironmentFile=/home/pi/fl.env
ExecStart=/usr/bin/python3 node/main.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
```

```bash
# /home/pi/fl.env
NODE_ID=node_0
PORT=8000
PEERS=http://192.168.1.101:8000,http://192.168.1.102:8000
DATA_PARTITION=0
```

```bash
sudo systemctl enable fl-node
sudo systemctl start fl-node
```

---

## Dashboard

Open `dashboard/index.html` in any modern browser.

**Enter node URLs** in the input at the top, e.g.:

```
http://localhost:8000,http://localhost:8001,http://localhost:8002,http://localhost:8003,http://localhost:8004
```

For a real Pi cluster:

```
http://192.168.1.100:8000,http://192.168.1.101:8000,...
```

Features:
- **Network topology graph** — nodes, edges, gossip reachability
- **Loss convergence chart** — per-node training loss over rounds
- **Node cards** — test accuracy, loss, rounds trained, gossip count
- **Global stats bar** — average rounds, best accuracy, total gossip exchanges
- **Event log** — real-time gossip events and failures
- **Manual controls** — trigger training or gossip on all nodes at once

---

## API Reference

Each node exposes the same REST API:

| Method | Path | Description |
|--------|------|-------------|
| `GET`  | `/health` | Liveness probe |
| `GET`  | `/status` | Full status + metrics history |
| `GET`  | `/model` | Current model weights (JSON) |
| `POST` | `/model` | Receive weights pushed by a peer |
| `GET`  | `/peers` | Peer list and reachability |
| `POST` | `/peers` | Dynamically add a peer |
| `DELETE` | `/peers/{url}` | Remove a peer |
| `GET`  | `/metrics` | Full training history |
| `POST` | `/train/trigger` | Manually kick off a training round |
| `POST` | `/gossip/trigger` | Manually kick off a gossip round |

Interactive docs: `http://localhost:8000/docs`

---

## Configuration

All configuration is done via **environment variables** — no config files to edit.

| Variable | Default | Description |
|----------|---------|-------------|
| `NODE_ID` | `node_0` | Unique node identifier |
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8000` | Listening port |
| `PEERS` | `""` | Comma-separated peer URLs |
| `DATA_PARTITION` | `0` | Data shard index (0–4) |
| `LOCAL_EPOCHS` | `1` | SGD epochs per training round |
| `BATCH_SIZE` | `32` | Mini-batch size |
| `LEARNING_RATE` | `0.01` | SGD learning rate |
| `GOSSIP_INTERVAL` | `15` | Seconds between gossip rounds |
| `GOSSIP_FANOUT` | `2` | Peers contacted per gossip round |
| `TRAIN_INTERVAL` | `20` | Seconds between training rounds |
| `NON_IID` | `true` | Non-IID data split (realistic) |
| `DATA_DIR` | `./data` | MNIST download directory |

---

## Running Tests

```bash
pip install pytest pytest-asyncio
pytest tests/ -v
```

Expected output:

```
tests/test_fl_node.py::TestFLModel::test_forward_shape          PASSED
tests/test_fl_node.py::TestFLModel::test_weights_roundtrip      PASSED
tests/test_fl_node.py::TestFLModel::test_count_parameters       PASSED
tests/test_fl_node.py::TestAggregator::test_fedavg_two_peers    PASSED
tests/test_fl_node.py::TestAggregator::test_fedavg_no_peers     PASSED
tests/test_fl_node.py::TestAggregator::test_weighted_fedavg     PASSED
tests/test_fl_node.py::TestGossipEngine::test_add_remove_peer   PASSED
tests/test_fl_node.py::TestGossipEngine::test_gossip_round_...  PASSED
```

---

## How It Works

### Gossip Protocol

Each node runs two background loops:

1. **Training loop** (every `TRAIN_INTERVAL` seconds):
   - Runs `LOCAL_EPOCHS` of SGD on local data
   - Updates its own model in-place

2. **Gossip loop** (every `GOSSIP_INTERVAL` seconds):
   - Picks `GOSSIP_FANOUT` random peers
   - **Push**: `POST /model` → sends current weights to peer
   - **Pull**: `GET /model` → fetches peer's current weights
   - Aggregates received weights with local model via FedAvg
   - Peers that time out are marked offline and skipped

### FedAvg Aggregation

```
new_model = (local + peer_1 + peer_2 + …) / N
```

Element-wise average of all weight tensors. Provably converges to the same
optimum as centralized gradient descent under mild conditions (McMahan et al., 2017).

### Non-IID Data Splits

Each node receives primarily 2 digit classes (e.g., node_0 gets mostly 0s and 1s).
This simulates realistic edge data heterogeneity. Without gossip, nodes would only
learn to classify their home digits. After sufficient gossip rounds, all nodes
achieve near-uniform accuracy across all 10 classes.

### Fault Tolerance

- Nodes that fail are simply skipped during gossip
- No state is lost — the surviving nodes continue learning
- When a failed node restarts, it receives fresh weights from the next gossip round
- The system continues without any manual intervention

---

## Expected Results

After ~30 training rounds with gossip:

| Metric | Value |
|--------|-------|
| Test accuracy (non-IID, 5 nodes) | ~92–94% |
| Test accuracy (IID, 5 nodes) | ~95–96% |
| Centralized baseline | ~97% |
| Convergence gap vs centralized | ~2–3% |

The ~2–3% gap is expected and is a well-known property of FedAvg with non-IID data.
