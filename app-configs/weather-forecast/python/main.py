# SPDX-FileCopyrightText: Copyright (C) ARDUINO SRL (http://www.arduino.cc)
#
# SPDX-License-Identifier: MPL-2.0

from arduino.app_bricks.weather_forecast import WeatherForecast
from arduino.app_utils import *

# ---- IOTCONNECT Relay (App Lab TCP bridge) ----
from iotc_relay_client import IoTConnectRelayClient

RELAY_ENDPOINT = "tcp://172.17.0.1:8899"
RELAY_CLIENT_ID = "weather_forecast"

relay = IoTConnectRelayClient(
    RELAY_ENDPOINT,
    client_id=RELAY_CLIENT_ID,
)
relay.start()

forecaster = WeatherForecast()


def get_weather_forecast(city: str) -> str:
    forecast = forecaster.get_forecast_by_city(city)
    print(f"Weather forecast for {city}: {forecast.description}")

    # Publish telemetry
    relay.send_telemetry({
        "city": city,
        "forecast_category": forecast.category,
        "forecast_description": forecast.description,
    })

    return forecast.category


Bridge.provide("get_weather_forecast", get_weather_forecast)

App.run()
