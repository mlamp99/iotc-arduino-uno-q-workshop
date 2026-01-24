#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <app_dir> [example_name]"
  exit 1
fi

APP_DIR="$1"
EXAMPLE_NAME="${2:-$(basename "$APP_DIR")}"
MAIN_PY="$APP_DIR/python/main.py"
RELAY_SRC="$(cd "$(dirname "$0")/.." && pwd)/app-lab/iotc_relay_client.py"
RELAY_DST="$APP_DIR/python/iotc_relay_client.py"
CONFIG_PATH="$(cd "$(dirname "$0")/.." && pwd)/app-configs/$EXAMPLE_NAME/config.json"

if [[ ! -f "$MAIN_PY" ]]; then
  echo "main.py not found: $MAIN_PY"
  exit 1
fi

if [[ ! -f "$RELAY_SRC" ]]; then
  echo "relay client not found: $RELAY_SRC"
  exit 1
fi

cp "$RELAY_SRC" "$RELAY_DST"

python3 - "$MAIN_PY" "$CONFIG_PATH" <<'PY'
from pathlib import Path
import sys
import json

main_py = Path(sys.argv[1])
config_path = Path(sys.argv[2])
text = main_py.read_text(encoding="utf-8")
marker = "# IOTCONNECT SETUP START"

if marker in text:
    print("IoTConnect block already present. Skipping insert.")
    sys.exit(0)

telemetry_keys = []
commands = []
if config_path.exists():
    try:
        cfg = json.loads(config_path.read_text(encoding="utf-8"))
        telemetry_keys = [t.get("name") for t in cfg.get("telemetry", []) if isinstance(t, dict) and t.get("name")]
        commands = [c.get("name") for c in cfg.get("commands", []) if isinstance(c, dict) and c.get("name")]
    except Exception as e:
        print(f"Warning: failed to read config {config_path}: {e}")

lines = text.splitlines()

insert_block = [
    "# IOTCONNECT SETUP START",
    "from iotc_relay_client import IoTConnectRelayClient",
    "",
    "IOTC_SOCKET = \"tcp://172.17.0.1:8899\"",
    "IOTC_CLIENT_ID = \"unoq-demo-1\"",
    "",
    "def IOTC_ON_COMMAND(command_name, parameters):",
    "    print(f\"IOTConnect command: {command_name} {parameters}\")",
    "",
    "IOTC_CLIENT = IoTConnectRelayClient(IOTC_SOCKET, IOTC_CLIENT_ID, command_callback=IOTC_ON_COMMAND)",
    "IOTC_CLIENT.start()",
    "",
    "def IOTC_SEND(data):",
    "    return IOTC_CLIENT.send_telemetry(data)",
    "# IOTCONNECT SETUP END",
    "",
]

if telemetry_keys or commands:
    insert_block += [
        "# IOTCONNECT TODO: add telemetry send calls in your app logic",
        f"# Telemetry keys: {', '.join(telemetry_keys) if telemetry_keys else 'TODO'}",
        f"# Commands: {', '.join(commands) if commands else 'TODO'}",
        "",
    ]

last_import_idx = -1
for i, line in enumerate(lines):
    stripped = line.strip()
    if stripped.startswith("import ") or stripped.startswith("from "):
        last_import_idx = i
    elif stripped and last_import_idx != -1:
        # Stop once we pass initial import block
        break

insert_at = last_import_idx + 1 if last_import_idx >= 0 else 0

new_lines = lines[:insert_at] + insert_block + lines[insert_at:]
main_py.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
print("Inserted IoTConnect setup block.")
PY

echo "Patched: $MAIN_PY"
if [[ -f "$CONFIG_PATH" ]]; then
  echo "Config: $CONFIG_PATH"
fi
