# IOTCONNECT Version: home-climate-monitoring-and-storage

This is the IOTCONNECT-enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/blob/main/examples/home-climate-monitoring-and-storage/README.md

## Overview
This version adds an IOTCONNECT relay client, a device template, and optional command handling so the app can publish telemetry and receive commands from IOTCONNECT.

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)
- Optional debug logs for telemetry send

App Lab folder: `/home/arduino/ArduinoApps/home-climate-monitoring-and-storage`

## Files
- `python/main.py` (IOTCONNECT-enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQHC`
- Template name: `UnoQHomeClimate`

## Telemetry Fields
| Field | Type |
| --- | --- |
| `temperature_c` | `DECIMAL` |
| `humidity` | `DECIMAL` |
| `dew_point` | `DECIMAL` |
| `heat_index` | `DECIMAL` |
| `absolute_humidity` | `DECIMAL` |
| `ts` | `INTEGER` |
| `UnoQdemo` | `STRING` |
| `interval_sec` | `INTEGER` |

## Commands
| Command | Parameters |
| --- | --- |
| `set-interval` | `seconds` |

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/home-climate-monitoring-and-storage home-climate-monitoring-and-storage
   ```
3) Run the app and verify telemetry in IOTCONNECT.

## IOTCONNECT setup checklist
- Create or select the device template using the fields above.
- Create a device bound to that template.
- Download `iotcDeviceConfig.json`, `device-cert.pem`, and `device-pkey.pem`.
- Copy those files to `/home/arduino/demo` on the UNO Q.

## Notes
- If the example sends telemetry only on user action, you will not see data until that action occurs.
- If you change the device template in IOTCONNECT, re-create the device or update it to match these fields.