# Automated Lab Flow (Arduino UNO Q -> IOTCONNECT via Relay)

This README describes the automated path for the customer lab. The scripts run on the UNO Q host OS. Participants can
use their Windows laptop for account creation, certificates, and shell access.

What is automated on the UNO Q:
- IOTCONNECT Python Lite SDK install
- Relay server and client download
- socat TCP bridge (container -> host relay socket)
- systemd services for relay + bridge
- App Lab project patch (copy relay client + insert init block)
- Health checks

What is still manual:
- IOTCONNECT account/device creation
- Downloading device certs and config from IOTCONNECT
- Arduino App Lab installation
- Android tools (ADB) installation on the laptop

---

## Prerequisites

On the laptop (manual):
1) Create the IOTCONNECT device and template for the lab.
2) Download the device files:
   - `iotcDeviceConfig.json`
   - `device-cert.pem`
   - `device-pkey.pem`
   Note: the downloaded cert files may include the device name (for example, `cert_unoQ2mcl.crt` and `key_unoQ2mcl.key`).
   The setup script will try to copy them to `device-cert.pem` and `device-pkey.pem` automatically.
3) Use the Windows helper script to install Android Platform Tools (ADB) and push the files to the UNO Q.

On the UNO Q (manual once):
- Arduino App Lab installed
- Internet access (Ethernet or Wi-Fi)

---

## Step 1: Clone this repo on the UNO Q

```bash
cd /home/arduino

git clone https://github.com/mlamp99/iotc-arduino-uno-q-workshop
cd iotc-arduino-uno-q-workshop

chmod +x scripts/*.sh
```

---

## Windows Step: Install Android Platform Tools (ADB) and push certs to the UNO Q

Run this on the Windows laptop after you download the IOTCONNECT files:

```powershell
cd C:\Users\<you>\Downloads
git clone https://github.com/mlamp99/iotc-arduino-uno-q-workshop
cd iotc-arduino-uno-q-workshop

.\scripts\windows\unoq_push_certs.ps1
```

Notes:
- The script will download Android Platform Tools if `adb` is not found.
- It looks for `iotcDeviceConfig.json` and the latest `*cert*.zip` in your Downloads folder.
- It extracts cert/key files, renames them to `device-cert.pem` and `device-pkey.pem`, and pushes them to `/home/arduino/demo`.
- If your Downloads folder is different, run:
  `.\scripts\windows\unoq_push_certs.ps1 -DownloadsDir "D:\Downloads"`

---

## Step 2: Run the automated host setup

This installs the IOTCONNECT Python Lite SDK, installs socat, downloads the relay server + client, and sets up systemd services.

```bash
cd /home/arduino/iotc-arduino-uno-q-workshop
sudo ./scripts/unoq_setup.sh --demo-dir /home/arduino/demo
```

Optional flags:
- `--bridge-port 8899`
- `--no-systemd` (skip service install/start)
- `--skip-apt` (skip apt install step)
- `--skip-sdk` (skip IOTCONNECT Python Lite SDK install)
- `--no-rename-certs` (skip renaming cert/key files in the demo dir)

---

## Step 3: Verify the host setup

```bash
./scripts/unoq_verify.sh --demo-dir /home/arduino/demo
```

You should see:
- IOTCONNECT Lite SDK import check ok
- Relay socket present: `/tmp/iotconnect-relay.sock`
- Port 8899 listening

---

## Step 4: Choose and clone a lab example in App Lab

In Arduino App Lab:
1) Browse examples from `app-bricks-examples`.
2) Copy the selected app into your workspace.
3) Note the app folder path (example: `/home/arduino/ArduinoApps/air-quality-monitoring`).

---

## Step 5: Patch the App Lab project for IOTCONNECT

This copies the patched relay client into the app and inserts a minimal setup block into `python/main.py`.

```bash
./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/air-quality-monitoring
```

After patching, open `python/main.py` and add telemetry calls where your app produces data:

```python
# Example
IOTC_SEND({"temp_c": temp_c, "humidity": humidity})
```

---

## Step 6: Run the app and confirm telemetry

1) Run the app in App Lab.
2) Confirm telemetry appears in IOTCONNECT.
3) If you enabled commands, test a command from IOTCONNECT and verify the app receives it.

Expected result: the selected App Lab example runs on the UNO Q and publishes telemetry to IOTCONNECT.

---

## Scripts

- `scripts/unoq_setup.sh`
  - Installs socat
  - Downloads relay server and client into `/home/arduino/demo`
  - Configures and starts systemd services

- `scripts/unoq_patch_app.sh <app_dir>`
  - Copies `app-lab/iotc_relay_client.py` into `<app_dir>/python/`
  - Inserts a minimal IOTCONNECT init block into `<app_dir>/python/main.py`

- `scripts/unoq_verify.sh`
  - Verifies SDK import, relay socket, and TCP port

---

## Troubleshooting

- If App Lab cannot connect, confirm the bridge is listening on port 8899:
  `ss -ltnp | grep 8899`
- If the relay socket is missing, restart the relay service:
  `sudo systemctl restart iotc-relay`
- If systemd is not available, run these manually:
  - `python3 /home/arduino/demo/iotc-relay-server.py`
  - `sudo socat TCP-LISTEN:8899,reuseaddr,fork UNIX-CONNECT:/tmp/iotconnect-relay.sock`
