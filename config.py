# ─────────────────────────────────────────────────────────────────────────────
# docker-compose.yml
# Runs 5 FL nodes + a static dashboard server.
#
# Usage:
#   docker compose -f docker/docker-compose.yml up --build
#
# Dashboard: http://localhost:3000
# Node APIs: http://localhost:8000 … http://localhost:8004
# ─────────────────────────────────────────────────────────────────────────────

version: "3.9"

# ── Shared data volume so MNIST is only downloaded once ───────────────────
volumes:
  mnist-data:

# ── Internal FL mesh network ─────────────────────────────────────────────
networks:
  fl-mesh:
    driver: bridge

# ── Reusable node config template ─────────────────────────────────────────
x-node-common: &node-common
  build:
    context: ..
    dockerfile: docker/Dockerfile
  volumes:
    - mnist-data:/data
  networks:
    - fl-mesh
  restart: unless-stopped

services:

  # ── Node 0 ────────────────────────────────────────────────────────────────
  node0:
    <<: *node-common
    container_name: fl_node0
    ports:
      - "8000:8000"
    environment:
      NODE_ID:         node_0
      PORT:            8000
      PEERS:           "http://node1:8000,http://node2:8000,http://node3:8000,http://node4:8000"
      DATA_PARTITION:  0
      GOSSIP_INTERVAL: 15
      TRAIN_INTERVAL:  20
      GOSSIP_FANOUT:   2

  # ── Node 1 ────────────────────────────────────────────────────────────────
  node1:
    <<: *node-common
    container_name: fl_node1
    ports:
      - "8001:8000"
    environment:
      NODE_ID:         node_1
      PORT:            8000
      PEERS:           "http://node0:8000,http://node2:8000,http://node3:8000,http://node4:8000"
      DATA_PARTITION:  1
      GOSSIP_INTERVAL: 15
      TRAIN_INTERVAL:  20
      GOSSIP_FANOUT:   2

  # ── Node 2 ────────────────────────────────────────────────────────────────
  node2:
    <<: *node-common
    container_name: fl_node2
    ports:
      - "8002:8000"
    environment:
      NODE_ID:         node_2
      PORT:            8000
      PEERS:           "http://node0:8000,http://node1:8000,http://node3:8000,http://node4:8000"
      DATA_PARTITION:  2
      GOSSIP_INTERVAL: 15
      TRAIN_INTERVAL:  20
      GOSSIP_FANOUT:   2

  # ── Node 3 ────────────────────────────────────────────────────────────────
  node3:
    <<: *node-common
    container_name: fl_node3
    ports:
      - "8003:8000"
    environment:
      NODE_ID:         node_3
      PORT:            8000
      PEERS:           "http://node0:8000,http://node1:8000,http://node2:8000,http://node4:8000"
      DATA_PARTITION:  3
      GOSSIP_INTERVAL: 15
      TRAIN_INTERVAL:  20
      GOSSIP_FANOUT:   2

  # ── Node 4 ────────────────────────────────────────────────────────────────
  node4:
    <<: *node-common
    container_name: fl_node4
    ports:
      - "8004:8000"
    environment:
      NODE_ID:         node_4
      PORT:            8000
      PEERS:           "http://node0:8000,http://node1:8000,http://node2:8000,http://node3:8000"
      DATA_PARTITION:  4
      GOSSIP_INTERVAL: 15
      TRAIN_INTERVAL:  20
      GOSSIP_FANOUT:   2

  # ── Dashboard (nginx serving the static HTML) ─────────────────────────────
  dashboard:
    image: nginx:alpine
    container_name: fl_dashboard
    ports:
      - "3000:80"
    volumes:
      - ../dashboard:/usr/share/nginx/html:ro
    networks:
      - fl-mesh
    restart: unless-stopped
