# IOTCONNECT Version: video-generic-object-detection

This is the IOTCONNECT-enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/blob/main/examples/video-generic-object-detection/README.md

## Overview
This version adds an IOTCONNECT relay client, a device template, and optional command handling so the app can publish telemetry and receive commands from IOTCONNECT.

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)
- Optional debug logs for telemetry send

App Lab folder: `/home/arduino/ArduinoApps/detect-objects-on-camera`

## Files
- `python/main.py` (IOTCONNECT-enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQVG`
- Template name: `UnoQVideoGenericObjectDe`

## Telemetry Fields
| Field | Type |
| --- | --- |
| `UnoQdemo` | `STRING` |
| `auto_mode` | `STRING` |
| `interval_sec` | `INTEGER` |
| `detection_count` | `INTEGER` |
| `max_confidence` | `DECIMAL` |
| `avg_confidence` | `DECIMAL` |
| `detections_json` | `STRING` |
| `status` | `STRING` |
| `class_name_1` | `STRING` |
| `confidence_1` | `DECIMAL` |
| `class_name_2` | `STRING` |
| `confidence_2` | `DECIMAL` |
| `class_name_3` | `STRING` |
| `confidence_3` | `DECIMAL` |
| `class_name_4` | `STRING` |
| `confidence_4` | `DECIMAL` |

## Commands
| Command | Parameters |
| --- | --- |
| `set-interval` | `seconds` |
| `set-confidence` | `confidence` |
| `set-auto` | `enabled` |
| `run-detect` | `(none)` |

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/detect-objects-on-camera video-generic-object-detection
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