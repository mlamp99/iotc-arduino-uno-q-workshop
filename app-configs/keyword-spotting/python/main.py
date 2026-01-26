# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0

from arduino.app_utils import *
from arduino.app_bricks.keyword_spotting import KeywordSpotting

# ---- IOTCONNECT Relay ----
from iotc_relay_client import IoTConnectRelayClient

RELAY_ENDPOINT = "tcp://172.17.0.1:8899"
RELAY_CLIENT_ID = "keyword_spotting"
UNOQ_DEMO_NAME = "keyword-spotting"

relay = IoTConnectRelayClient(
    RELAY_ENDPOINT,
    client_id=RELAY_CLIENT_ID,
)
relay.start()


def send_telemetry(keyword, status="ok"):
    payload = {
        "UnoQdemo": UNOQ_DEMO_NAME,
        "keyword": keyword or "",
        "status": status,
    }
    print("IOTCONNECT send:", payload)
    relay.send_telemetry(payload)


def on_keyword_detected():
    Bridge.call("keyword_detected")
    send_telemetry("hey_arduino", "detected")


spotter = KeywordSpotting()
spotter.on_detect("hey_arduino", on_keyword_detected)

App.run()
