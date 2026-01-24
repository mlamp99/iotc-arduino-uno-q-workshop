#!/usr/bin/env bash
set -euo pipefail

DEMO_DIR="/home/weston/demo"
BRIDGE_PORT="8899"
SKIP_APT="0"
NO_SYSTEMD="0"
SKIP_SDK="0"
NO_RENAME_CERTS="0"
PIP_BREAK_SYSTEM_PACKAGES="1"

RELAY_SERVER_URL="https://raw.githubusercontent.com/avnet-iotconnect/iotc-relay-service/main/relay-server/iotc-relay-server.py"
RELAY_CLIENT_URL="https://raw.githubusercontent.com/avnet-iotconnect/iotc-relay-service/main/client-module/python/iotc_relay_client.py"

usage() {
  cat <<EOF
Usage: $0 [--demo-dir PATH] [--bridge-port PORT] [--skip-apt] [--no-systemd] [--skip-sdk] [--no-rename-certs] [--pip-break-system-packages]

  --demo-dir     Directory that contains iotcDeviceConfig.json and cert files
  --bridge-port  TCP port for the socat bridge (default: 8899)
  --skip-apt     Skip apt-get install step
  --no-systemd   Do not install or start systemd services
  --skip-sdk     Skip installing the IoTConnect Python Lite SDK
  --no-rename-certs  Do not try to rename device cert/key files in demo dir
  --pip-break-system-packages  Allow pip to install system-wide packages
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --demo-dir) DEMO_DIR="$2"; shift 2;;
    --bridge-port) BRIDGE_PORT="$2"; shift 2;;
    --skip-apt) SKIP_APT="1"; shift;;
    --no-systemd) NO_SYSTEMD="1"; shift;;
    --skip-sdk) SKIP_SDK="1"; shift;;
    --no-rename-certs) NO_RENAME_CERTS="1"; shift;;
    --pip-break-system-packages) PIP_BREAK_SYSTEM_PACKAGES="1"; shift;;
    -h|--help) usage; exit 0;;
    *) echo "Unknown arg: $1"; usage; exit 1;;
  esac
 done

if [[ "$NO_SYSTEMD" == "0" || "$SKIP_APT" == "0" ]]; then
  if [[ "$EUID" -ne 0 ]]; then
    echo "Please run as root (sudo)."
    exit 1
  fi
fi

RUN_USER="${SUDO_USER:-$USER}"

if [[ "$SKIP_APT" == "0" ]]; then
  apt-get update
  apt-get install -y socat python3-pip
fi

mkdir -p "$DEMO_DIR"

# Some relay server builds expect /home/weston/demo by default. Provide a compatibility symlink.
if [[ "$DEMO_DIR" != "/home/weston/demo" ]]; then
  if [[ ! -e "/home/weston" ]]; then
    mkdir -p /home/weston
  fi
  if [[ -L "/home/weston/demo" ]]; then
    true
  elif [[ -e "/home/weston/demo" ]]; then
    true
  else
    ln -s "$DEMO_DIR" /home/weston/demo
    echo "Created symlink: /home/weston/demo -> $DEMO_DIR"
  fi
fi

if command -v curl >/dev/null 2>&1; then
  DL_CMD=(curl -fsSL)
elif command -v wget >/dev/null 2>&1; then
  DL_CMD=(wget -qO-)
else
  echo "Need curl or wget installed."
  exit 1
fi

fetch_file() {
  local url="$1"
  local dest="$2"
  echo "Downloading $url -> $dest"
  "${DL_CMD[@]}" "$url" > "$dest"
}

if [[ ! -f "$DEMO_DIR/iotc-relay-server.py" ]]; then
  fetch_file "$RELAY_SERVER_URL" "$DEMO_DIR/iotc-relay-server.py"
fi

if [[ ! -f "$DEMO_DIR/iotc_relay_client.py" ]]; then
  fetch_file "$RELAY_CLIENT_URL" "$DEMO_DIR/iotc_relay_client.py"
fi

chmod +x "$DEMO_DIR/iotc-relay-server.py"

if [[ "$NO_RENAME_CERTS" == "0" ]]; then
  # If user copied files to /tmp via scp, pull them into the demo dir.
  if [[ -f "/tmp/iotcDeviceConfig.json" && ! -f "$DEMO_DIR/iotcDeviceConfig.json" ]]; then
    cp "/tmp/iotcDeviceConfig.json" "$DEMO_DIR/iotcDeviceConfig.json"
    echo "Copied /tmp/iotcDeviceConfig.json -> $DEMO_DIR/iotcDeviceConfig.json"
  fi

  if [[ ! -f "$DEMO_DIR/device-cert.pem" ]]; then
    if [[ -f "/tmp/device-cert.pem" ]]; then
      cp "/tmp/device-cert.pem" "$DEMO_DIR/device-cert.pem"
      echo "Copied /tmp/device-cert.pem -> $DEMO_DIR/device-cert.pem"
    fi
  fi

  if [[ ! -f "$DEMO_DIR/device-pkey.pem" ]]; then
    if [[ -f "/tmp/device-pkey.pem" ]]; then
      cp "/tmp/device-pkey.pem" "$DEMO_DIR/device-pkey.pem"
      echo "Copied /tmp/device-pkey.pem -> $DEMO_DIR/device-pkey.pem"
    fi
  fi

  if [[ ! -f "$DEMO_DIR/device-cert.pem" ]]; then
    cert_src="$(ls -1 /tmp/cert_*.crt /tmp/cert_*.pem 2>/dev/null | head -n 1 || true)"
    if [[ -z "$cert_src" ]]; then
      cert_src="$(ls -1 "$DEMO_DIR"/cert_*.crt "$DEMO_DIR"/cert_*.pem 2>/dev/null | head -n 1 || true)"
    fi
    if [[ -n "$cert_src" ]]; then
      cp "$cert_src" "$DEMO_DIR/device-cert.pem"
      echo "Copied cert: $(basename "$cert_src") -> device-cert.pem"
    else
      echo "No cert_*.crt or cert_*.pem found in $DEMO_DIR"
    fi
  fi

  if [[ ! -f "$DEMO_DIR/device-pkey.pem" ]]; then
    key_src="$(ls -1 /tmp/pk_*.pem /tmp/key_*.key /tmp/key_*.pem 2>/dev/null | head -n 1 || true)"
    if [[ -z "$key_src" ]]; then
      key_src="$(ls -1 "$DEMO_DIR"/key_*.key "$DEMO_DIR"/key_*.pem 2>/dev/null | head -n 1 || true)"
    fi
    if [[ -n "$key_src" ]]; then
      cp "$key_src" "$DEMO_DIR/device-pkey.pem"
      echo "Copied key: $(basename "$key_src") -> device-pkey.pem"
    else
      echo "No key_*.key or key_*.pem found in $DEMO_DIR"
    fi
  fi
fi

if [[ "$SKIP_SDK" == "0" ]]; then
  set +e
  python3 -m pip install --upgrade pip
  if [[ "$PIP_BREAK_SYSTEM_PACKAGES" == "1" ]]; then
    python3 -m pip install --break-system-packages iotconnect-sdk-lite
  else
    python3 -m pip install iotconnect-sdk-lite
  fi
  if [[ $? -ne 0 ]]; then
    echo "WARNING: SDK install failed (possibly due to externally managed env)."
    echo "Re-run with --pip-break-system-packages or --skip-sdk."
  fi
  set -e
fi

if [[ "$NO_SYSTEMD" == "0" ]]; then
  cat > /usr/local/bin/iotc-wait-relay-sock.sh <<'EOF'
#!/usr/bin/env bash
set -e
for _ in $(seq 1 30); do
  if [[ -S /tmp/iotconnect-relay.sock ]]; then
    exit 0
  fi
  sleep 1
done
exit 1
EOF
  chmod +x /usr/local/bin/iotc-wait-relay-sock.sh

  cat > /etc/systemd/system/iotc-relay.service <<EOF
[Unit]
Description=IoTConnect Relay Server
After=network.target

[Service]
Type=simple
User=$RUN_USER
WorkingDirectory=$DEMO_DIR
ExecStart=/usr/bin/python3 $DEMO_DIR/iotc-relay-server.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  cat > /etc/systemd/system/iotc-socat.service <<EOF
[Unit]
Description=IoTConnect Relay Socket Bridge (socat)
After=network.target iotc-relay.service
Requires=iotc-relay.service

[Service]
Type=simple
ExecStartPre=/usr/local/bin/iotc-wait-relay-sock.sh
ExecStart=/usr/bin/socat TCP-LISTEN:${BRIDGE_PORT},reuseaddr,fork UNIX-CONNECT:/tmp/iotconnect-relay.sock
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now iotc-relay.service
  systemctl enable --now iotc-socat.service
fi

echo "Setup complete."
echo "Demo dir: $DEMO_DIR"
echo "Bridge port: $BRIDGE_PORT"
if [[ "$NO_SYSTEMD" == "1" ]]; then
  echo "Start manually:"
  echo "  python3 $DEMO_DIR/iotc-relay-server.py"
  echo "  sudo socat TCP-LISTEN:${BRIDGE_PORT},reuseaddr,fork UNIX-CONNECT:/tmp/iotconnect-relay.sock"
fi
