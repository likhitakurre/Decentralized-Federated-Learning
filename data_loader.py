# ─────────────────────────────────────────────────────────────────────────────
# Decentralized FL — Edge Node
#
# Build:
#   docker build -t fl-node -f docker/Dockerfile .
#
# Run a single node (all config via env vars):
#   docker run -p 8000:8000 \
#     -e NODE_ID=node_0 \
#     -e PORT=8000 \
#     -e PEERS=http://node1:8000,http://node2:8000 \
#     -e DATA_PARTITION=0 \
#     fl-node
#
# ─────────────────────────────────────────────────────────────────────────────

# ── Stage 1: build deps ───────────────────────────────────────────────────────
FROM python:3.11-slim AS builder

WORKDIR /build

# Install build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc g++ && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# ── Stage 2: runtime image ────────────────────────────────────────────────────
FROM python:3.11-slim

# Non-root user for security
RUN useradd -m -u 1000 fl
WORKDIR /app

# Copy installed packages
COPY --from=builder /root/.local /home/fl/.local
ENV PATH=/home/fl/.local/bin:$PATH

# Copy node source
COPY node/ .

# MNIST data will be downloaded on first run and cached in a volume
RUN mkdir -p /data && chown fl /data
VOLUME ["/data"]

USER fl

# Default environment — override at runtime
ENV NODE_ID=node_0      \
    HOST=0.0.0.0        \
    PORT=8000           \
    PEERS=""            \
    DATA_PARTITION=0    \
    LOCAL_EPOCHS=1      \
    BATCH_SIZE=32       \
    LEARNING_RATE=0.01  \
    GOSSIP_INTERVAL=15  \
    TRAIN_INTERVAL=20   \
    GOSSIP_FANOUT=2     \
    NON_IID=true        \
    DATA_DIR=/data

EXPOSE 8000

HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')"

CMD ["python", "main.py"]
