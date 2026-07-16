# ─── Core ML stack ────────────────────────────────────────────────────────
# CPU-only PyTorch — the right choice for Raspberry Pi
--extra-index-url https://download.pytorch.org/whl/cu118
torch==2.2.2+cpu
# Diabetes dataset (ships with sklearn — zero download required)
scikit-learn==1.4.2

# ─── Web framework ────────────────────────────────────────────────────────
fastapi==0.111.0
uvicorn[standard]==0.29.0
pydantic==2.7.1

# ─── Async HTTP (gossip engine) ────────────────────────────────────────────
aiohttp==3.9.5

# ─── Utilities ────────────────────────────────────────────────────────────
requests==2.31.0       # used in evaluate.py
numpy==1.26.4
