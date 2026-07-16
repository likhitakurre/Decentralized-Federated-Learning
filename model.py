"""
Node configuration — driven entirely by environment variables
so the same image can be deployed on any Raspberry Pi.
"""
import os
from dataclasses import dataclass, field
from typing import List


@dataclass
class NodeConfig:
    # ── Identity ───────────────────────────────────────────────────────────
    node_id: str = os.environ.get("NODE_ID", "node_0")
    host: str = os.environ.get("HOST", "0.0.0.0")
    port: int = int(os.environ.get("PORT", "8000"))

    # ── Peer discovery ─────────────────────────────────────────────────────
    # Comma-separated list: http://192.168.1.101:8000,http://192.168.1.102:8000
    peers: List[str] = field(
        default_factory=lambda: [
            p.strip() for p in os.environ.get("PEERS", "").split(",") if p.strip()
        ]
    )

    # ── Local training ──────────────────────────────────────────────────────
    local_epochs: int = int(os.environ.get("LOCAL_EPOCHS", "1"))
    batch_size: int = int(os.environ.get("BATCH_SIZE", "32"))
    learning_rate: float = float(os.environ.get("LEARNING_RATE", "0.01"))

    # 0–4 selects which data shard this node receives (5 total shards)
    data_partition: int = int(os.environ.get("DATA_PARTITION", "0"))

    # ── Gossip protocol ─────────────────────────────────────────────────────
    gossip_interval: int = int(os.environ.get("GOSSIP_INTERVAL", "15"))   # seconds
    gossip_fanout: int = int(os.environ.get("GOSSIP_FANOUT", "2"))        # peers/round
    train_interval: int = int(os.environ.get("TRAIN_INTERVAL", "20"))     # seconds

    # ── Data ────────────────────────────────────────────────────────────────
    data_dir: str = os.environ.get("DATA_DIR", "./data")
    non_iid: bool = os.environ.get("NON_IID", "true").lower() == "true"

    # ── Dashboard / CORS ────────────────────────────────────────────────────
    dashboard_origin: str = os.environ.get("DASHBOARD_ORIGIN", "*")
