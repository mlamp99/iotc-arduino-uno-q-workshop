# IOTCONNECT Version: air-quality-monitoring

This is the IOTCONNECT?enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/tree/main/examples/air-quality-monitoring

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)

## Files
- `python/main.py` (IOTCONNECT?enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQAQM`
- Template name: `UnoQAirQuality`

## Telemetry Fields
- `city`
- `aqi`
- `aqi_level`
- `UnoQdemo`
- `interval_sec`

## Commands
- `set-city`
- `set-interval`

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/air-quality-monitoring
   ```
3) Run the app and verify telemetry in IOTCONNECT.
