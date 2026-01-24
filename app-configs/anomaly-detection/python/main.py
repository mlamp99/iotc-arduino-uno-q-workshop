# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0

from arduino.app_utils import *
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.visual_anomaly_detection import VisualAnomalyDetection
from arduino.app_utils import draw_anomaly_markers
from PIL import Image
import io
import base64
import time
import os
from pathlib import Path

# ---- IOTCONNECT Relay (App Lab TCP bridge) ----
from iotc_relay_client import IoTConnectRelayClient

RELAY_ENDPOINT = "tcp://172.17.0.1:8899"
RELAY_CLIENT_ID = "concrete_crack_detector"
UNOQ_DEMO_NAME = "anomaly-detection"
IOTC_INTERVAL_SEC = 5
IOTC_LAST_SEND = 0.0


def on_relay_command(command_name, parameters):
    global IOTC_INTERVAL_SEC
    print(f"IOTCONNECT command: {command_name} {parameters}")
    if command_name == "set-interval":
        try:
            if isinstance(parameters, dict):
                IOTC_INTERVAL_SEC = int(parameters.get("seconds", IOTC_INTERVAL_SEC))
            else:
                IOTC_INTERVAL_SEC = int(str(parameters).strip())
            print(f"IOTCONNECT interval set to {IOTC_INTERVAL_SEC}s")
        except Exception as e:
            print(f"IOTCONNECT interval update failed: {e}")


relay = IoTConnectRelayClient(
    RELAY_ENDPOINT,
    client_id=RELAY_CLIENT_ID,
    command_callback=on_relay_command
)
relay.start()


def send_telemetry(payload):
    global IOTC_LAST_SEND
    now = time.time()
    if now - IOTC_LAST_SEND < IOTC_INTERVAL_SEC:
        return False
    payload.setdefault("UnoQdemo", UNOQ_DEMO_NAME)
    payload["interval_sec"] = int(IOTC_INTERVAL_SEC)
    IOTC_LAST_SEND = now
    print("IOTCONNECT send:", payload)
    ok = relay.send_telemetry(payload)
    print("IOTCONNECT send result:", ok)
    return ok


anomaly_detection = VisualAnomalyDetection()

SCRIPT_DIR = Path(__file__).resolve().parent.parent
IMAGES_DIR = SCRIPT_DIR / "assets"
os.makedirs(IMAGES_DIR, exist_ok=True)


def on_detect_anomalies(client_id, data):
    try:
        image_data = data.get('image')
        if not image_data:
            ui.send_message('detection_error', {'error': 'No image data'})
            send_telemetry({
                "status": "error",
                "detection_count": 0,
                "processing_time_ms": 0,
                "has_anomaly": "false",
            })
            return

        image_bytes = base64.b64decode(image_data)
        pil_image = Image.open(io.BytesIO(image_bytes))

        start_time = time.time() * 1000
        results = anomaly_detection.detect(pil_image)
        diff = time.time() * 1000 - start_time

        if results is None:
            ui.send_message('detection_error', {'error': 'No results returned'})
            send_telemetry({
                "status": "error",
                "detection_count": 0,
                "processing_time_ms": int(diff),
                "has_anomaly": "false",
            })
            return

        img_with_markers = draw_anomaly_markers(pil_image, results)

        if img_with_markers is not None:
            img_buffer = io.BytesIO()
            img_with_markers.save(img_buffer, format="PNG")
            img_buffer.seek(0)
            b64_result = base64.b64encode(img_buffer.getvalue()).decode("utf-8")
        else:
            img_buffer = io.BytesIO()
            pil_image.save(img_buffer, format="PNG")
            img_buffer.seek(0)
            b64_result = base64.b64encode(img_buffer.getvalue()).decode("utf-8")

        response = {
            'success': True,
            'result_image': b64_result,
            'detection_count': len(results) if results else 0,
            'processing_time': f"{diff:.2f} ms"
        }
        ui.send_message('detection_result', response)

        send_telemetry({
            "status": "ok",
            "detection_count": len(results) if results else 0,
            "processing_time_ms": int(diff),
            "has_anomaly": "true" if (results and len(results) > 0) else "false",
        })

    except Exception as e:
        ui.send_message('detection_error', {'error': str(e)})
        send_telemetry({
            "status": "error",
            "detection_count": 0,
            "processing_time_ms": 0,
            "has_anomaly": "false",
        })


ui = WebUI()
ui.on_message('detect_anomalies', on_detect_anomalies)

App.run()
