# IOTCONNECT Version: weather-forecast

This is the IOTCONNECT-enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/blob/main/examples/weather-forecast/README.md

## Overview
This version adds an IOTCONNECT relay client, a device template, and optional command handling so the app can publish telemetry and receive commands from IOTCONNECT.

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)
- Optional debug logs for telemetry send

App Lab folder: `/home/arduino/ArduinoApps/weather-forecast-on-led-matrix`

## Files
- `python/main.py` (IOTCONNECT-enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQWF`
- Template name: `UnoQWeather`

## Telemetry Fields
| Field | Type |
| --- | --- |
| `city` | `STRING` |
| `forecast_category` | `STRING` |
| `forecast_description` | `STRING` |
| `UnoQdemo` | `STRING` |
| `interval_sec` | `INTEGER` |

## Commands
| Command | Parameters |
| --- | --- |
| `set-interval` | `seconds` |
| `set-city` | `city` |

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/weather-forecast-on-led-matrix weather-forecast
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