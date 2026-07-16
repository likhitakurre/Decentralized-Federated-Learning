"""
Data loading for federated learning — regression on the sklearn Diabetes dataset.

Dataset facts:
  - 442 samples, 10 normalised features, 1 continuous target
  - No download required — ships with sklearn
  - Entire dataset fits in RAM (<50 KB)
  - First training round completes in < 2 seconds on a Raspberry Pi

Each node gets a distinct slice of the data (IID split by default).
Non-IID split sorts by target value so each node sees a different
range of the output — simulating nodes deployed in different environments.

──────────────────────────────────────────────────────────────────────────
Swapping in real sensor data
──────────────────────────────────────────────────────────────────────────
Replace the block marked "── REAL SENSOR HOOK ──" below with code that
reads your CSV / SQLite / GPIO buffer, e.g.:

    import pandas as pd
    df = pd.read_csv("/home/pi/sensor_log.csv")
    X = df[["temperature","humidity","pressure","light","motion"]].values
    y = df["target"].values          # whatever you're predicting

Keep the rest of the function identical.
"""

import numpy as np
import torch
from torch.utils.data import DataLoader, TensorDataset
from typing import Tuple

from config import NodeConfig

N_PARTITIONS = 5   # matches the default 5-node setup


def get_data_loaders(config: NodeConfig) -> Tuple[DataLoader, DataLoader]:
    X, y = _load_dataset(config)

    # ── Split train / test (80 / 20) before partitioning ──────────────────
    rng   = np.random.default_rng(seed=42)
    idx   = rng.permutation(len(X))
    split = int(len(X) * 0.8)
    train_idx, test_idx = idx[:split], idx[split:]

    X_train_full, y_train_full = X[train_idx], y[train_idx]
    X_test,       y_test       = X[test_idx],  y[test_idx]

    # ── Give this node its slice of the training data ─────────────────────
    if config.non_iid:
        X_train, y_train = _non_iid_partition(
            X_train_full, y_train_full, config.data_partition
        )
    else:
        X_train, y_train = _iid_partition(
            X_train_full, y_train_full, config.data_partition
        )

    train_loader = _make_loader(X_train, y_train, config.batch_size, shuffle=True)
    test_loader  = _make_loader(X_test,  y_test,  batch_size=128,    shuffle=False)

    return train_loader, test_loader


# ── Dataset loader ─────────────────────────────────────────────────────────

def _load_dataset(config: NodeConfig) -> Tuple[np.ndarray, np.ndarray]:
    """
    ── REAL SENSOR HOOK ──
    Replace this function body to load your own data, e.g.:

        import pandas as pd
        df = pd.read_csv("/home/pi/sensor_log.csv")
        X  = df[["temp","humidity","pressure","light","motion"]].values.astype(np.float32)
        y  = df["target"].values.astype(np.float32)
        X  = _normalise(X)
        return X, y

    The rest of the pipeline (partitioning, DataLoader) is unchanged.
    """
    from sklearn.datasets import load_diabetes
    from sklearn.preprocessing import StandardScaler

    data = load_diabetes()
    X    = data.data.astype(np.float32)     # (442, 10) — already normalised by sklearn
    y    = data.target.astype(np.float32)   # continuous 0–346

    # Normalise target to [0, 1] — makes loss values comparable across nodes
    y = (y - y.min()) / (y.max() - y.min())

    return X, y


def _normalise(X: np.ndarray) -> np.ndarray:
    """Z-score normalise features — use for raw sensor data."""
    mean = X.mean(axis=0)
    std  = X.std(axis=0) + 1e-8
    return (X - mean) / std


# ── Partitioning ───────────────────────────────────────────────────────────

def _iid_partition(
    X: np.ndarray, y: np.ndarray, partition_idx: int
) -> Tuple[np.ndarray, np.ndarray]:
    """Uniform random 1/N slice."""
    rng   = np.random.default_rng(seed=7)
    idx   = rng.permutation(len(X))
    chunk = max(1, len(X) // N_PARTITIONS)
    start = (partition_idx % N_PARTITIONS) * chunk
    end   = start + chunk
    sel   = idx[start:end]
    return X[sel], y[sel]


def _non_iid_partition(
    X: np.ndarray, y: np.ndarray, partition_idx: int
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Sort by target value and give each node a contiguous range.
    Simulates nodes operating in different environments
    (e.g. one Pi always in a cool room, another always warm).
    """
    order  = np.argsort(y)
    chunk  = max(1, len(y) // N_PARTITIONS)
    start  = (partition_idx % N_PARTITIONS) * chunk
    end    = min(start + chunk, len(y))
    sel    = order[start:end]
    return X[sel], y[sel]


# ── DataLoader factory ─────────────────────────────────────────────────────

def _make_loader(
    X: np.ndarray, y: np.ndarray, batch_size: int, shuffle: bool
) -> DataLoader:
    dataset = TensorDataset(
        torch.from_numpy(X),
        torch.from_numpy(y),
    )
    return DataLoader(
        dataset,
        batch_size=min(batch_size, len(dataset)),
        shuffle=shuffle,
        num_workers=0,
        drop_last=False,
    )
