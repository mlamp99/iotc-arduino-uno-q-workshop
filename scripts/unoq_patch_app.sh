#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <app_dir>"
  exit 1
fi

APP_DIR="$1"
MAIN_PY="$APP_DIR/python/main.py"
RELAY_SRC="$(cd "$(dirname "$0")/.." && pwd)/app-lab/iotc_relay_client.py"
RELAY_DST="$APP_DIR/python/iotc_relay_client.py"

if [[ ! -f "$MAIN_PY" ]]; then
  echo "main.py not found: $MAIN_PY"
  exit 1
fi

if [[ ! -f "$RELAY_SRC" ]]; then
  echo "relay client not found: $RELAY_SRC"
  exit 1
fi

cp "$RELAY_SRC" "$RELAY_DST"

python3 - "$MAIN_PY" <<'PY'
from pathlib import Path
import sys

main_py = Path(sys.argv[1])
text = main_py.read_text(encoding="utf-8")
marker = "# IOTCONNECT SETUP START"

if marker in text:
    print("IoTConnect block already present. Skipping insert.")
    sys.exit(0)

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
