# IOTCONNECT Version: video-face-detection

This is the IOTCONNECT?enabled version of the Arduino example.

Original Arduino README:
- https://github.com/arduino/app-bricks-examples/tree/main/examples/video-face-detection

## What this adds
- IOTCONNECT relay client wiring
- Device template for telemetry + commands
- Optional commands (if defined below)

## Files
- `python/main.py` (IOTCONNECT?enabled app code)
- `device-template.json` (IOTCONNECT device template)
- `config.json` (telemetry/command definitions)

## Device Template
- Template code: `UnoQVF`
- Template name: `UnoQVideoFaceDetection`

## Telemetry Fields
- `UnoQdemo`
- `auto_mode`
- `interval_sec`
- `detection_count`
- `max_confidence`
- `avg_confidence`
- `detections_json`
- `status`
- `class_name_1`
- `confidence_1`
- `class_name_2`
- `confidence_2`
- `class_name_3`
- `confidence_3`
- `class_name_4`
- `confidence_4`

## Commands
- `set-interval`
- `set-confidence`
- `set-auto`
- `run-detect`

## How to use in App Lab
1) Copy the example into your App Lab workspace.
2) Run the patcher from the workshop repo:
   ```bash
   ./scripts/unoq_patch_app.sh /home/arduino/ArduinoApps/video-face-detection
   ```
3) Run the app and verify telemetry in IOTCONNECT.
