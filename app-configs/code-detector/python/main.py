# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0

from datetime import datetime, UTC
import io
import base64
from PIL.Image import Image
from arduino.app_utils import *
from arduino.app_peripherals.usb_camera import USBCamera
from arduino.app_bricks.web_ui import WebUI
from arduino.app_bricks.camera_code_detection import CameraCodeDetection, Detection, draw_bounding_box
from arduino.app_bricks.dbstorage_sqlstore import SQLStore

# ---- IOTCONNECT Relay ----
from iotc_relay_client import IoTConnectRelayClient

RELAY_ENDPOINT = "tcp://172.17.0.1:8899"
RELAY_CLIENT_ID = "code_detector"
UNOQ_DEMO_NAME = "code-detector"

relay = IoTConnectRelayClient(
    RELAY_ENDPOINT,
    client_id=RELAY_CLIENT_ID,
)
relay.start()


def send_telemetry(content, code_type, status="ok"):
    payload = {
        "UnoQdemo": UNOQ_DEMO_NAME,
        "code_content": content or "",
        "code_type": code_type or "",
        "status": status,
    }
    print("IOTCONNECT send:", payload)
    relay.send_telemetry(payload)


detected = False

def on_code_detected(frame: Image, detection: Detection):
    global detected
    if detected:
        return

    frame = draw_bounding_box(frame, detection)

    buffer = io.BytesIO()
    frame.save(buffer, format="JPEG", quality=100)
    b64_frame = base64.b64encode(buffer.getvalue()).decode("utf-8")

    entry = {
        "content": detection.content,
        "type": detection.type,
        "timestamp": datetime.now(UTC).isoformat(),
        "image": b64_frame,
        "image_type": "image/jpeg",
    }
    store.store("scan_log", entry)
    ui.send_message('code_detected', entry)
    detected = True

    send_telemetry(detection.content, detection.type, "ok")


def on_frame(frame: Image):
    global detected
    if detected:
        return

    buffer = io.BytesIO()
    frame.save(buffer, format="JPEG", quality=100)
    b64_frame = base64.b64encode(buffer.getvalue()).decode("utf-8")

    entry = {
        "timestamp": datetime.now(UTC).isoformat(),
        "image": b64_frame,
        "image_type": "image/jpeg",
    }

    ui.send_message('frame_detected', entry)


def on_list_scans():
    scans = store.read("scan_log", order_by="timestamp DESC", limit=5)
    return {"scans": scans if scans else []}


def reset_detection(_, __):
    global detected
    detected = False
    send_telemetry("", "", "reset")


def on_error(e: Exception):
    ui.send_message('error', str(e))
    send_telemetry("", "", f"error:{e}")

store = SQLStore("code-scanner.db")

camera = USBCamera(resolution=(640, 480), fps=5)
detector = CameraCodeDetection(camera)
detector.on_detect(on_code_detected)
detector.on_frame(on_frame)
detector.on_error(on_error)

ui = WebUI()
ui.expose_api('GET', '/list_scans', on_list_scans)
ui.on_message('reset_detection', reset_detection)

App.run()
