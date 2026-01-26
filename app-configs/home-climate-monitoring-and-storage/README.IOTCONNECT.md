# IOTCONNECT Version: home-climate-monitoring-and-storage

This is the IOTCONNECT?enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/tree/main/examples/home-climate-monitoring-and-storage

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)

## Files
- `python/main.py` (IOTCONNECT?enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQHC`
- Template name: `UnoQHomeClimate`

## Telemetry Fields
- `temperature_c`
- `humidity`
- `dew_point`
- `heat_index`
- `absolute_humidity`
- `ts`
- `UnoQdemo`
- `interval_sec`

## Commands
- `set-interval`

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/home-climate-monitoring-and-storage
   ```
3) Run the app and verify telemetry in IOTCONNECT.
