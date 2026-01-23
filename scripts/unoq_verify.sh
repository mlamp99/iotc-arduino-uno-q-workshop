#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="/home/weston/demo"
BRIDGE_PORT="8899"

usage() {
  cat <<EOF
Usage: $0 [--demo-dir PATH] [--bridge-port PORT]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo-dir) DEMO_DIR="$2"; shift 2;;
    --bridge-port) BRIDGE_PORT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
 done

ok() { echo "[OK] $*"; }
warn() { echo "[WARN] $*"; }
fail() { echo "[FAIL] $*"; }

if python3 -c "from avnet.iotconnect.sdk.lite import Client" >/dev/null 2>&1; then
  ok "IoTConnect Lite SDK import"
else
  warn "IoTConnect Lite SDK import failed (is it installed?)"
fi

if [[ -S /tmp/iotconnect-relay.sock ]]; then
  ok "Relay socket present: /tmp/iotconnect-relay.sock"
else
  warn "Relay socket missing: /tmp/iotconnect-relay.sock"
fi

if command -v ss >/dev/null 2>&1; then
  if ss -ltn 2>/dev/null | grep -q ":${BRIDGE_PORT} "; then
    ok "TCP bridge listening on port ${BRIDGE_PORT}"
  else
    warn "TCP bridge not listening on port ${BRIDGE_PORT}"
  fi
else
  warn "ss not available; skipping port check"
fi

if command -v systemctl >/dev/null 2>&1; then
  if systemctl is-active --quiet iotc-relay.service; then
    ok "iotc-relay.service active"
  else
    warn "iotc-relay.service not active"
  fi
  if systemctl is-active --quiet iotc-socat.service; then
    ok "iotc-socat.service active"
  else
    warn "iotc-socat.service not active"
  fi
fi

echo "Verify complete."
