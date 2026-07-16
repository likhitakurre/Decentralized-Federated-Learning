<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>FL Monitor — Decentralized Federated Learning</title>
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<style>
  /* ─── FONTS ─────────────────────────────────────────────────────────── */
  @import url('https://fonts.googleapis.com/css2?family=Space+Mono:ital,wght@0,400;0,700;1,400&family=Syne:wght@400;600;800&display=swap');

  /* ─── CSS TOKENS ────────────────────────────────────────────────────── */
  :root {
    --bg0: #060a10;
    --bg1: #0c1220;
    --bg2: #111927;
    --bg3: #1a2535;
    --border: #1e2e44;
    --border-bright: #2a4060;

    --cyan: #00d4ff;
    --cyan-dim: #0099bb;
    --green: #00e87a;
    --green-dim: #009950;
    --amber: #ffb700;
    --red: #ff4757;
    --purple: #b07aff;

    --text-bright: #e8f0ff;
    --text-mid: #7a93b4;
    --text-dim: #3d5570;

    --mono: 'Space Mono', monospace;
    --sans: 'Syne', sans-serif;

    --glow-cyan: 0 0 12px rgba(0,212,255,0.35);
    --glow-green: 0 0 12px rgba(0,232,122,0.35);
    --radius: 6px;
  }

  *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

  html, body {
    height: 100%;
    background: var(--bg0);
    color: var(--text-bright);
    font-family: var(--mono);
    font-size: 13px;
    overflow: hidden;
  }

  /* ─── SCANLINE OVERLAY ──────────────────────────────────────────────── */
  body::before {
    content: '';
    position: fixed;
    inset: 0;
    background: repeating-linear-gradient(
      0deg,
      transparent,
      transparent 2px,
      rgba(0,0,0,0.12) 2px,
      rgba(0,0,0,0.12) 4px
    );
    pointer-events: none;
    z-index: 9999;
  }

  /* ─── LAYOUT ────────────────────────────────────────────────────────── */
  #app {
    display: grid;
    grid-template-rows: 56px 1fr;
    grid-template-columns: 1fr;
    height: 100vh;
  }

  #header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 24px;
    background: var(--bg1);
    border-bottom: 1px solid var(--border);
    position: relative;
    overflow: hidden;
  }

  #header::after {
    content: '';
    position: absolute;
    bottom: 0; left: 0; right: 0;
    height: 1px;
    background: linear-gradient(90deg, transparent, var(--cyan), transparent);
    animation: scan-h 4s linear infinite;
  }

  @keyframes scan-h {
    0%   { transform: translateX(-100%); }
    100% { transform: translateX(100%); }
  }

  .header-left { display: flex; align-items: center; gap: 16px; }
  .logo-mark {
    width: 32px; height: 32px;
    border: 1.5px solid var(--cyan);
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    font-family: var(--sans); font-weight: 800; font-size: 14px;
    color: var(--cyan);
    box-shadow: var(--glow-cyan);
    animation: pulse 3s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { box-shadow: 0 0 8px rgba(0,212,255,0.3); }
    50%       { box-shadow: 0 0 20px rgba(0,212,255,0.7); }
  }

  .title-group { line-height: 1.2; }
  .title-group h1 {
    font-family: var(--sans);
    font-weight: 800;
    font-size: 15px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
    color: var(--text-bright);
  }
  .title-group .sub {
    font-size: 10px;
    color: var(--text-mid);
    letter-spacing: 0.12em;
    text-transform: uppercase;
  }

  .header-right {
    display: flex; align-items: center; gap: 24px;
  }

  .status-pill {
    display: flex; align-items: center; gap: 6px;
    font-size: 10px; color: var(--text-mid);
    letter-spacing: 0.1em; text-transform: uppercase;
  }
  .dot {
    width: 7px; height: 7px; border-radius: 50%;
    background: var(--green);
    box-shadow: var(--glow-green);
    animation: blink 2s ease-in-out infinite;
  }
  @keyframes blink {
    0%,100% { opacity: 1; } 50% { opacity: 0.3; }
  }

  #clock {
    font-size: 11px;
    color: var(--cyan);
    letter-spacing: 0.08em;
  }

  /* ─── MAIN GRID ─────────────────────────────────────────────────────── */
  #main {
    display: grid;
    grid-template-columns: 320px 1fr 300px;
    grid-template-rows: 1fr 220px;
    gap: 1px;
    background: var(--border);
    overflow: hidden;
  }

  .panel {
    background: var(--bg1);
    overflow: hidden;
    display: flex;
    flex-direction: column;
  }

  .panel-header {
    display: flex; align-items: center; justify-content: space-between;
    padding: 10px 14px;
    border-bottom: 1px solid var(--border);
    background: var(--bg2);
    flex-shrink: 0;
  }

  .panel-title {
    font-size: 9px;
    letter-spacing: 0.18em;
    text-transform: uppercase;
    color: var(--text-mid);
    font-family: var(--mono);
  }

  .panel-badge {
    font-size: 9px;
    padding: 2px 7px;
    border-radius: 2px;
    background: var(--bg3);
    border: 1px solid var(--border);
    color: var(--text-mid);
    font-family: var(--mono);
  }

  .panel-body {
    flex: 1;
    overflow-y: auto;
    overflow-x: hidden;
    padding: 12px;
  }

  .panel-body::-webkit-scrollbar { width: 3px; }
  .panel-body::-webkit-scrollbar-track { background: transparent; }
  .panel-body::-webkit-scrollbar-thumb { background: var(--border-bright); border-radius: 2px; }

  /* ─── TOPOLOGY CANVAS ───────────────────────────────────────────────── */
  #topology-panel {
    grid-row: 1 / 2;
    grid-column: 1 / 2;
  }

  #topo-canvas {
    width: 100%;
    flex: 1;
    display: block;
  }

  /* ─── CHART AREA ────────────────────────────────────────────────────── */
  #chart-panel {
    grid-row: 1 / 2;
    grid-column: 2 / 3;
  }

  #chart-wrap {
    flex: 1;
    padding: 16px 20px;
    position: relative;
  }

  #chart-wrap canvas { width: 100% !important; height: 100% !important; }

  /* ─── NODES LIST ─────────────────────────────────────────────────────── */
  #nodes-panel {
    grid-row: 1 / 2;
    grid-column: 3 / 4;
  }

  /* ─── LOG + STATS BAR ────────────────────────────────────────────────── */
  #log-panel {
    grid-row: 2 / 3;
    grid-column: 1 / 2;
  }

  #stats-panel {
    grid-row: 2 / 3;
    grid-column: 2 / 4;
    display: grid;
    grid-template-columns: repeat(4, 1fr) 1fr;
    gap: 1px;
    background: var(--border);
  }

  /* ─── NODE CARDS ─────────────────────────────────────────────────────── */
  .node-card {
    border: 1px solid var(--border);
    border-radius: var(--radius);
    margin-bottom: 8px;
    background: var(--bg2);
    overflow: hidden;
    transition: border-color 0.3s;
  }

  .node-card.online  { border-color: var(--border-bright); }
  .node-card.offline { border-color: var(--red); opacity: 0.6; }

  .node-card-head {
    display: flex; align-items: center; justify-content: space-between;
    padding: 8px 10px;
    background: var(--bg3);
  }

  .node-name {
    font-family: var(--sans); font-weight: 600;
    font-size: 12px; color: var(--text-bright);
  }

  .node-status-dot {
    width: 8px; height: 8px; border-radius: 50%;
    transition: background 0.3s;
  }
  .online  .node-status-dot { background: var(--green); box-shadow: var(--glow-green); }
  .offline .node-status-dot { background: var(--red); }

  .node-stats {
    padding: 8px 10px;
    display: grid; grid-template-columns: 1fr 1fr;
    gap: 4px 8px;
  }

  .node-stat {
    display: flex; flex-direction: column; gap: 1px;
  }

  .stat-label {
    font-size: 8px; color: var(--text-dim); letter-spacing: 0.1em; text-transform: uppercase;
  }

  .stat-value {
    font-size: 13px; font-weight: 700; color: var(--cyan);
    font-family: var(--mono);
  }

  .stat-value.acc  { color: var(--green); }
  .stat-value.loss { color: var(--amber); }
  .stat-value.off  { color: var(--red); }

  .node-bar-wrap {
    padding: 0 10px 8px;
  }

  .node-bar-label {
    font-size: 8px; color: var(--text-dim); letter-spacing: 0.08em; text-transform: uppercase;
    margin-bottom: 3px;
  }

  .node-bar {
    height: 3px; background: var(--bg0); border-radius: 2px; overflow: hidden;
  }
  .node-bar-fill {
    height: 100%; background: var(--green); border-radius: 2px;
    transition: width 0.8s ease;
  }

  /* ─── STAT TILES ─────────────────────────────────────────────────────── */
  .stat-tile {
    background: var(--bg1);
    display: flex; flex-direction: column; justify-content: center;
    padding: 16px 18px;
  }

  .tile-label {
    font-size: 9px; color: var(--text-dim); letter-spacing: 0.16em; text-transform: uppercase;
    margin-bottom: 6px;
  }

  .tile-value {
    font-family: var(--sans); font-weight: 800; font-size: 28px;
    line-height: 1; color: var(--cyan);
  }

  .tile-value.green  { color: var(--green); }
  .tile-value.amber  { color: var(--amber); }
  .tile-value.purple { color: var(--purple); }

  .tile-sub {
    font-size: 9px; color: var(--text-dim); margin-top: 4px;
  }

  /* ─── ACTION PANEL ───────────────────────────────────────────────────── */
  .action-tile {
    background: var(--bg1);
    display: flex; flex-direction: column;
    justify-content: center; align-items: flex-start;
    gap: 8px;
    padding: 14px 16px;
  }

  .btn {
    display: inline-flex; align-items: center; gap: 5px;
    font-family: var(--mono); font-size: 10px; letter-spacing: 0.08em;
    text-transform: uppercase;
    padding: 5px 12px; border-radius: 3px; cursor: pointer;
    border: 1px solid; background: transparent;
    transition: all 0.2s;
  }

  .btn-cyan  { color: var(--cyan); border-color: var(--cyan-dim); }
  .btn-cyan:hover { background: rgba(0,212,255,0.12); box-shadow: var(--glow-cyan); }

  .btn-green { color: var(--green); border-color: var(--green-dim); }
  .btn-green:hover { background: rgba(0,232,122,0.12); box-shadow: var(--glow-green); }

  .btn-amber { color: var(--amber); border-color: rgba(255,183,0,0.4); }
  .btn-amber:hover { background: rgba(255,183,0,0.1); }

  .btn:disabled { opacity: 0.35; cursor: not-allowed; }

  /* ─── LOG ────────────────────────────────────────────────────────────── */
  #log-body {
    font-size: 10px; line-height: 1.7;
    color: var(--text-mid);
  }

  .log-line { display: flex; gap: 8px; }
  .log-ts { color: var(--text-dim); flex-shrink: 0; }
  .log-msg { color: var(--text-mid); }
  .log-msg.ok   { color: var(--green); }
  .log-msg.warn { color: var(--amber); }
  .log-msg.err  { color: var(--red); }
  .log-msg.info { color: var(--cyan); }

  /* ─── LOADING OVERLAY ────────────────────────────────────────────────── */
  #loading {
    position: fixed; inset: 0;
    background: var(--bg0);
    display: flex; flex-direction: column;
    align-items: center; justify-content: center;
    gap: 16px;
    z-index: 100;
    transition: opacity 0.5s;
  }
  #loading.hidden { opacity: 0; pointer-events: none; }

  .loading-ring {
    width: 48px; height: 48px;
    border: 2px solid var(--bg3);
    border-top-color: var(--cyan);
    border-radius: 50%;
    animation: spin 0.8s linear infinite;
  }
  @keyframes spin { to { transform: rotate(360deg); } }

  .loading-text {
    font-size: 10px; color: var(--text-mid); letter-spacing: 0.2em; text-transform: uppercase;
  }

  /* ─── NODE CONFIG INPUT ──────────────────────────────────────────────── */
  #config-bar {
    display: flex; align-items: center; gap: 8px; flex-wrap: wrap;
    padding: 8px 12px;
    background: var(--bg0);
    border-bottom: 1px solid var(--border);
    font-size: 10px;
  }

  #config-bar label { color: var(--text-dim); letter-spacing: 0.08em; text-transform: uppercase; }

  #node-urls-input {
    flex: 1;
    min-width: 240px;
    background: var(--bg2);
    border: 1px solid var(--border);
    border-radius: 3px;
    color: var(--text-bright);
    font-family: var(--mono); font-size: 10px;
    padding: 4px 8px;
    outline: none;
  }
  #node-urls-input:focus { border-color: var(--cyan); }
</style>
</head>
<body>

<div id="loading">
  <div class="loading-ring"></div>
  <div class="loading-text">Connecting to nodes…</div>
</div>

<div id="app">

  <!-- ── HEADER ───────────────────────────────────────────────────────── -->
  <header id="header">
    <div class="header-left">
      <div class="logo-mark">FL</div>
      <div class="title-group">
        <h1>Federated Learning Monitor</h1>
        <div class="sub">Decentralized · Gossip Protocol · Edge Devices</div>
      </div>
    </div>
    <div class="header-right">
      <div id="config-bar" style="background:transparent;border:none;padding:0;">
        <label>Nodes:</label>
        <input id="node-urls-input"
               value="http://172.29.4.59:8001,http://172.29.22.44:8001,http://172.29.14.172:8001"
               placeholder="http://node1:8000,http://node2:8001,…"
               title="Comma-separated node URLs">
        <button class="btn btn-cyan" onclick="reloadConfig()">Apply</button>
      </div>
      <div class="status-pill"><div class="dot"></div><span id="net-status">LIVE</span></div>
      <div id="clock">--:--:--</div>
    </div>
  </header>

  <!-- ── MAIN GRID ─────────────────────────────────────────────────────── -->
  <div id="main">

    <!-- ── TOPOLOGY ─────────────────────────────────────────────────────── -->
    <div class="panel" id="topology-panel">
      <div class="panel-header">
        <span class="panel-title">Network Topology</span>
        <span class="panel-badge" id="topo-badge">—</span>
      </div>
      <canvas id="topo-canvas"></canvas>
    </div>

    <!-- ── LOSS CHART ────────────────────────────────────────────────────── -->
    <div class="panel" id="chart-panel">
      <div class="panel-header">
        <span class="panel-title">Training Loss — All Nodes</span>
        <div style="display:flex;gap:8px;">
          <span class="panel-badge" id="rounds-badge">Round 0</span>
          <select id="metric-select" style="background:var(--bg3);border:1px solid var(--border);color:var(--text-mid);font-family:var(--mono);font-size:9px;padding:2px 6px;border-radius:2px;outline:none;">
            <option value="loss">Loss</option>
            <option value="accuracy">Accuracy</option>
            <option value="test_loss">Test Loss</option>
            <option value="test_accuracy">Test Acc</option>
          </select>
        </div>
      </div>
      <div id="chart-wrap">
        <canvas id="loss-chart"></canvas>
      </div>
    </div>

    <!-- ── NODE CARDS ────────────────────────────────────────────────────── -->
    <div class="panel" id="nodes-panel">
      <div class="panel-header">
        <span class="panel-title">Node Status</span>
        <span class="panel-badge" id="online-badge">0 / 0</span>
      </div>
      <div class="panel-body" id="nodes-body">
        <div style="color:var(--text-dim);font-size:10px;padding:8px 0;">Waiting for data…</div>
      </div>
    </div>

    <!-- ── EVENT LOG ─────────────────────────────────────────────────────── -->
    <div class="panel" id="log-panel">
      <div class="panel-header">
        <span class="panel-title">Event Log</span>
        <button class="btn btn-amber" onclick="clearLog()" style="font-size:8px;padding:2px 8px;">Clear</button>
      </div>
      <div class="panel-body" id="log-body"></div>
    </div>

    <!-- ── STATS BAR ──────────────────────────────────────────────────────── -->
    <div id="stats-panel">

      <div class="stat-tile">
        <div class="tile-label">Global Rounds</div>
        <div class="tile-value" id="stat-rounds">—</div>
        <div class="tile-sub">avg across nodes</div>
      </div>

      <div class="stat-tile">
        <div class="tile-label">Best Test Acc</div>
        <div class="tile-value green" id="stat-acc">—</div>
        <div class="tile-sub">any single node</div>
      </div>

      <div class="stat-tile">
        <div class="tile-label">Gossip Exchanges</div>
        <div class="tile-value purple" id="stat-gossip">—</div>
        <div class="tile-sub">total successful</div>
      </div>

      <div class="stat-tile">
        <div class="tile-label">Nodes Online</div>
        <div class="tile-value amber" id="stat-online">—</div>
        <div class="tile-sub">of <span id="stat-total">—</span> configured</div>
      </div>

      <div class="action-tile">
        <button class="btn btn-cyan" onclick="triggerAllTrain()">▶ Train All</button>
        <button class="btn btn-green" onclick="triggerAllGossip()">↔ Gossip All</button>
      </div>

    </div>

  </div><!-- /#main -->

</div><!-- /#app -->

<script>
// ═══════════════════════════════════════════════════════════════════════════
// CONFIG
// ═══════════════════════════════════════════════════════════════════════════

let NODE_URLS = [];
const POLL_INTERVAL = 8000;  // ms

const NODE_COLORS = [
  '#00d4ff', '#00e87a', '#ffb700', '#b07aff', '#ff6b6b',
  '#38efff', '#ff9f43', '#48dbfb', '#ff6b9d', '#a29bfe',
];

let nodeData = {};   // url -> status JSON
let chart = null;
let pollTimer = null;

// ═══════════════════════════════════════════════════════════════════════════
// INIT
// ═══════════════════════════════════════════════════════════════════════════

function parseNodeUrls() {
  return document.getElementById('node-urls-input').value
    .split(',')
    .map(s => s.trim().replace(/\/$/, ''))
    .filter(Boolean);
}

function reloadConfig() {
  NODE_URLS = parseNodeUrls();
  nodeData  = {};
  if (pollTimer) clearInterval(pollTimer);
  initChart();
  poll();
  pollTimer = setInterval(poll, POLL_INTERVAL);
  log('Config reloaded — watching ' + NODE_URLS.length + ' nodes', 'info');
}

window.addEventListener('DOMContentLoaded', () => {
  // Always hide loading after 10s max
  setTimeout(() => { document.getElementById('loading').classList.add('hidden'); }, 10000);
  NODE_URLS = parseNodeUrls();
  // If URLs are pre-filled, hide loading sooner
  if (NODE_URLS.length > 0) {
    setTimeout(() => { document.getElementById('loading').classList.add('hidden'); }, 3000);
  }
  initChart();
  initTopology();
  startClock();

  poll();
  pollTimer = setInterval(poll, POLL_INTERVAL);

  document.getElementById('metric-select').addEventListener('change', () => {
    updateChart();
  });
});

// ═══════════════════════════════════════════════════════════════════════════
// POLLING
// ═══════════════════════════════════════════════════════════════════════════

async function fetchNodeStatus(url) {
  try {
    const r = await fetch(`${url}/status`, { signal: AbortSignal.timeout(8000) });
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    return await r.json();
  } catch (e) {
    return null;
  }
}

async function poll() {
  const results = await Promise.allSettled(
    NODE_URLS.map(u => fetchNodeStatus(u))
  );

  let anyOnline = false;

  results.forEach((res, i) => {
    const url = NODE_URLS[i];
    const prev = nodeData[url];
    if (res.status === 'fulfilled' && res.value) {
      const data = res.value;
      data._url    = url;
      data._online = true;
      data._color  = NODE_COLORS[i % NODE_COLORS.length];
      anyOnline = true;
      if (!prev || !prev._online) {
        log(`${data.node_id} came online`, 'ok');
      }
      // Log gossip exchanges delta
      const prevEx = prev?._online ? (prev.gossip?.successful_exchanges || 0) : 0;
      const curEx  = data.gossip?.successful_exchanges || 0;
      if (curEx > prevEx) {
        log(`${data.node_id} completed gossip exchange (total: ${curEx})`, 'ok');
      }
      nodeData[url] = data;
    } else {
      if (prev && prev._online) {
        log(`${prev.node_id || url} went OFFLINE`, 'err');
      }
      nodeData[url] = {
        _url: url, _online: false, _color: NODE_COLORS[i % NODE_COLORS.length],
        node_id: `node_${i}`,
      };
    }
  });

  if (anyOnline) {
    document.getElementById('loading').classList.add('hidden');
  }

  renderNodes();
  updateChart();
  renderTopology();
  updateStats();
}

// ═══════════════════════════════════════════════════════════════════════════
// NODE CARDS
// ═══════════════════════════════════════════════════════════════════════════

function renderNodes() {
  const container = document.getElementById('nodes-body');
  const online = Object.values(nodeData).filter(d => d._online).length;
  const total  = NODE_URLS.length;
  document.getElementById('online-badge').textContent = `${online} / ${total}`;

  container.innerHTML = NODE_URLS.map((url, i) => {
    const d = nodeData[url];
    if (!d) return '';
    const cls = d._online ? 'online' : 'offline';
    const acc  = d._online ? (d.eval_metrics?.test_accuracy != null ? (d.eval_metrics.test_accuracy * 100).toFixed(1) + '%' : '—') : '—';
    const loss = d._online ? (d.eval_metrics?.test_loss != null ? d.eval_metrics.test_loss.toFixed(4) : '—') : '—';
    const rounds = d._online ? (d.rounds_trained ?? '—') : '—';
    const gossips = d._online ? (d.gossip?.successful_exchanges ?? 0) : '—';
    const accNum = d._online && d.eval_metrics?.test_accuracy ? d.eval_metrics.test_accuracy : 0;
    const accentColor = d._color || 'var(--cyan)';

    return `
      <div class="node-card ${cls}" style="border-color:${d._online ? accentColor + '55' : 'var(--red)'}">
        <div class="node-card-head" style="border-bottom:1px solid ${d._online ? accentColor + '30' : 'var(--red)44'}">
          <div class="node-name" style="color:${accentColor}">${d.node_id || 'node_' + i}</div>
          <div class="node-status-dot" style="background:${d._online ? accentColor : 'var(--red)'};box-shadow:0 0 8px ${d._online ? accentColor + '88' : 'transparent'}"></div>
        </div>
        <div class="node-stats">
          <div class="node-stat"><div class="stat-label">Test Acc</div><div class="stat-value acc">${acc}</div></div>
          <div class="node-stat"><div class="stat-label">Test Loss</div><div class="stat-value loss">${loss}</div></div>
          <div class="node-stat"><div class="stat-label">Rounds</div><div class="stat-value" style="color:${accentColor}">${rounds}</div></div>
          <div class="node-stat"><div class="stat-label">Gossips</div><div class="stat-value" style="color:var(--purple)">${gossips}</div></div>
        </div>
        <div class="node-bar-wrap">
          <div class="node-bar-label">Test Accuracy</div>
          <div class="node-bar"><div class="node-bar-fill" style="width:${(accNum*100).toFixed(1)}%;background:${accentColor}"></div></div>
        </div>
      </div>`;
  }).join('');
}

// ═══════════════════════════════════════════════════════════════════════════
// CHART
// ═══════════════════════════════════════════════════════════════════════════

function initChart() {
  const ctx = document.getElementById('loss-chart').getContext('2d');
  if (chart) { chart.destroy(); chart = null; }

  chart = new Chart(ctx, {
    type: 'line',
    data: { labels: [], datasets: [] },
    options: {
      responsive: true,
      maintainAspectRatio: false,
      animation: { duration: 300 },
      interaction: { mode: 'index', intersect: false },
      plugins: {
        legend: {
          display: true,
          position: 'top',
          labels: {
            color: '#7a93b4',
            font: { family: "'Space Mono', monospace", size: 9 },
            boxWidth: 12, padding: 12,
          },
        },
        tooltip: {
          backgroundColor: '#111927ee',
          borderColor: '#1e2e44',
          borderWidth: 1,
          titleColor: '#e8f0ff',
          bodyColor: '#7a93b4',
          titleFont: { family: "'Space Mono', monospace", size: 10 },
          bodyFont:  { family: "'Space Mono', monospace", size: 10 },
        },
      },
      scales: {
        x: {
          grid: { color: '#1e2e4488' },
          ticks: { color: '#3d5570', font: { family: "'Space Mono', monospace", size: 9 }, maxTicksLimit: 8 },
          title: { display: true, text: 'Round', color: '#3d5570', font: { size: 9 } },
        },
        y: {
          grid: { color: '#1e2e4488' },
          ticks: { color: '#3d5570', font: { family: "'Space Mono', monospace", size: 9 } },
          title: { display: true, text: 'Loss', color: '#3d5570', font: { size: 9 } },
        },
      },
    },
  });
}

function updateChart() {
  if (!chart) return;
  const metric = document.getElementById('metric-select').value;
  const isAcc  = metric.includes('accuracy');

  // Build per-node datasets
  const datasets = [];
  let maxRounds = 0;

  NODE_URLS.forEach((url, i) => {
    const d = nodeData[url];
    if (!d || !d._online) return;
    const history = d.metrics_history || [];
    if (!history.length) return;

    let values;
    if (metric === 'test_loss' || metric === 'test_accuracy') {
      // These only appear in eval_metrics (single point)
      const val = d.eval_metrics?.[metric];
      if (val != null) {
        values = history.map((_, idx) => (idx === history.length - 1 ? val : null));
      } else return;
    } else {
      values = history.map(h => h[metric] ?? null);
    }

    maxRounds = Math.max(maxRounds, history.length);
    const color = d._color || NODE_COLORS[i];

    datasets.push({
      label: d.node_id || `node_${i}`,
      data: values,
      borderColor: color,
      backgroundColor: color + '18',
      borderWidth: 1.5,
      pointRadius: 2,
      pointHoverRadius: 4,
      tension: 0.3,
      fill: false,
    });
  });

  const labels = Array.from({ length: maxRounds }, (_, i) => i + 1);
  chart.data.labels   = labels;
  chart.data.datasets = datasets;
  chart.options.scales.y.title.text = isAcc ? 'Accuracy' : 'Loss';
  chart.update('none');

  document.getElementById('rounds-badge').textContent = `Round ${maxRounds}`;
}

// ═══════════════════════════════════════════════════════════════════════════
// TOPOLOGY CANVAS
// ═══════════════════════════════════════════════════════════════════════════

let topoCanvas, topoCtx;
let topoNodes = [];  // { x, y, url, data }
let animFrame = null;
let activeEdge = null;  // animated edge for gossip viz
let activeEdgeTimer = null;

function initTopology() {
  topoCanvas = document.getElementById('topo-canvas');
  topoCtx    = topoCanvas.getContext('2d');
  resizeTopo();
  window.addEventListener('resize', resizeTopo);
}

function resizeTopo() {
  const panel = document.getElementById('topology-panel');
  const hdr   = panel.querySelector('.panel-header');
  topoCanvas.width  = panel.clientWidth;
  topoCanvas.height = panel.clientHeight - hdr.offsetHeight;
  renderTopology();
}

function positionNodes(n, w, h) {
  const cx = w / 2, cy = h / 2;
  const r  = Math.min(w, h) * 0.33;
  return Array.from({ length: n }, (_, i) => {
    const angle = (i / n) * 2 * Math.PI - Math.PI / 2;
    return { x: cx + r * Math.cos(angle), y: cy + r * Math.sin(angle) };
  });
}

function renderTopology() {
  if (!topoCtx) return;
  const W = topoCanvas.width, H = topoCanvas.height;
  const ctx = topoCtx;

  ctx.clearRect(0, 0, W, H);

  const urls = NODE_URLS;
  if (!urls.length) return;
  const positions = positionNodes(urls.length, W, H);

  // Draw edges
  for (let i = 0; i < urls.length; i++) {
    const d = nodeData[urls[i]];
    if (!d || !d._online) continue;
    const peers = d.gossip?.peers || [];

    peers.forEach(peerUrl => {
      const j = urls.indexOf(peerUrl.replace(/\/$/, ''));
      if (j < 0 || j <= i) return;  // avoid double draw
      const a = positions[i], b = positions[j];
      const peerOnline = nodeData[peerUrl.replace(/\/$/, '')]?._online;
      const lastSeen = d.gossip?.peer_last_seen?.[peerUrl];
      const fresh = lastSeen && (Date.now() / 1000 - lastSeen) < 30;

      ctx.beginPath();
      ctx.moveTo(a.x, a.y);
      ctx.lineTo(b.x, b.y);
      ctx.strokeStyle = fresh ? '#00d4ff44' : '#1e2e44';
      ctx.lineWidth   = fresh ? 1.5 : 0.8;
      if (!peerOnline) { ctx.setLineDash([4, 4]); } else { ctx.setLineDash([]); }
      ctx.stroke();
      ctx.setLineDash([]);
    });
  }

  // Draw nodes
  urls.forEach((url, i) => {
    const d = nodeData[url];
    const pos = positions[i];
    const online = d?._online;
    const color  = d?._color || NODE_COLORS[i];
    const label  = d?.node_id || `node_${i}`;
    const rounds = d?._online ? (d.rounds_trained || 0) : null;
    const acc    = d?._online && d.eval_metrics?.test_accuracy
      ? (d.eval_metrics.test_accuracy * 100).toFixed(0) + '%'
      : online ? '—' : 'OFF';

    const R = 20;

    // Outer ring
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, R + 6, 0, Math.PI * 2);
    ctx.strokeStyle = online ? color + '44' : '#ff475744';
    ctx.lineWidth = 1;
    ctx.stroke();

    // Glow
    if (online) {
      const grd = ctx.createRadialGradient(pos.x, pos.y, R - 4, pos.x, pos.y, R + 16);
      grd.addColorStop(0, color + '30');
      grd.addColorStop(1, 'transparent');
      ctx.fillStyle = grd;
      ctx.beginPath();
      ctx.arc(pos.x, pos.y, R + 16, 0, Math.PI * 2);
      ctx.fill();
    }

    // Node circle
    ctx.beginPath();
    ctx.arc(pos.x, pos.y, R, 0, Math.PI * 2);
    ctx.fillStyle = online ? '#0c1220' : '#1a0a10';
    ctx.fill();
    ctx.strokeStyle = online ? color : '#ff4757';
    ctx.lineWidth = 1.5;
    ctx.stroke();

    // Label inside
    ctx.fillStyle = online ? color : '#ff4757';
    ctx.font = `700 9px 'Space Mono', monospace`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(acc, pos.x, pos.y);

    // Node name below
    ctx.fillStyle = online ? '#7a93b4' : '#5a2030';
    ctx.font = `10px 'Space Mono', monospace`;
    ctx.fillText(label, pos.x, pos.y + R + 14);

    // Rounds badge
    if (rounds !== null) {
      ctx.fillStyle = '#1a2535';
      ctx.beginPath();
      ctx.roundRect(pos.x - 14, pos.y - R - 18, 28, 14, 3);
      ctx.fill();
      ctx.fillStyle = color;
      ctx.font = `8px 'Space Mono', monospace`;
      ctx.fillText(`r${rounds}`, pos.x, pos.y - R - 11);
    }
  });

  // Centre label
  ctx.fillStyle = '#1e2e44';
  ctx.font = `9px 'Space Mono', monospace`;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText('GOSSIP MESH', W / 2, H / 2);

  document.getElementById('topo-badge').textContent =
    `${Object.values(nodeData).filter(d => d._online).length}/${urls.length} nodes`;
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOBAL STATS
// ═══════════════════════════════════════════════════════════════════════════

function updateStats() {
  const online = Object.values(nodeData).filter(d => d._online);
  const total  = NODE_URLS.length;

  const avgRounds = online.length
    ? Math.round(online.reduce((s, d) => s + (d.rounds_trained || 0), 0) / online.length)
    : 0;

  const bestAcc = online.length
    ? Math.max(...online.map(d => d.eval_metrics?.test_accuracy || 0))
    : 0;

  const totalGossip = online.reduce((s, d) => s + (d.gossip?.successful_exchanges || 0), 0);

  document.getElementById('stat-rounds').textContent  = avgRounds;
  document.getElementById('stat-acc').textContent     = bestAcc ? (bestAcc * 100).toFixed(1) + '%' : '—';
  document.getElementById('stat-gossip').textContent  = totalGossip;
  document.getElementById('stat-online').textContent  = online.length;
  document.getElementById('stat-total').textContent   = total;
  document.getElementById('online-badge').textContent = `${online.length} / ${total}`;
}

// ═══════════════════════════════════════════════════════════════════════════
// ACTIONS
// ═══════════════════════════════════════════════════════════════════════════

async function triggerAllTrain() {
  log('Triggering training on all nodes…', 'info');
  const calls = NODE_URLS.map(url =>
    fetch(`${url}/train/trigger`, { method: 'POST' })
      .then(r => r.json())
      .then(d => log(`${nodeData[url]?.node_id || url}: train round complete — loss=${d.metrics?.loss}`, 'ok'))
      .catch(() => log(`${url}: train trigger failed`, 'err'))
  );
  await Promise.allSettled(calls);
}

async function triggerAllGossip() {
  log('Triggering gossip on all nodes…', 'info');
  const calls = NODE_URLS.map(url =>
    fetch(`${url}/gossip/trigger`, { method: 'POST' })
      .then(r => r.json())
      .then(d => log(`${nodeData[url]?.node_id || url}: gossip done — received=${d.received}`, 'ok'))
      .catch(() => log(`${url}: gossip trigger failed`, 'err'))
  );
  await Promise.allSettled(calls);
}

// ═══════════════════════════════════════════════════════════════════════════
// LOG
// ═══════════════════════════════════════════════════════════════════════════

function log(msg, type = '') {
  const body = document.getElementById('log-body');
  const ts = new Date().toTimeString().slice(0, 8);
  const div = document.createElement('div');
  div.className = 'log-line';
  div.innerHTML = `<span class="log-ts">${ts}</span><span class="log-msg ${type}">${msg}</span>`;
  body.prepend(div);
  // Keep last 100 lines
  while (body.children.length > 100) body.removeChild(body.lastChild);
}

function clearLog() {
  document.getElementById('log-body').innerHTML = '';
}

// ═══════════════════════════════════════════════════════════════════════════
// CLOCK
// ═══════════════════════════════════════════════════════════════════════════

function startClock() {
  setInterval(() => {
    document.getElementById('clock').textContent = new Date().toTimeString().slice(0, 8);
  }, 1000);
}
</script>
</body>
</html>
