#!/usr/bin/env python3
import datetime
import urllib.request
import urllib.parse
import json
import sys

REQUEST_TIMEOUT = 4


def fetch_json(url):
    req = urllib.request.Request(url, headers={"User-Agent": "Quickshell Weather"})
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
        return json.loads(response.read().decode())


def get_manual_location(query):
    query = query.strip()
    if not query:
        return None

    try:
        params = urllib.parse.urlencode({
            "name": query,
            "count": 1,
            "language": "en",
            "format": "json",
        })
        data = fetch_json("https://geocoding-api.open-meteo.com/v1/search?" + params)
        result = (data.get("results") or [])[0]
        return (
            float(result["latitude"]),
            float(result["longitude"]),
            result.get("name") or query,
            result.get("country_code") or "",
        )
    except Exception as e:
        sys.stderr.write(f"Weather manual location error: {e}\n")
    return None


def get_ip_location():
    try:
        params = urllib.parse.urlencode({
            "fields": "status,lat,lon,city,countryCode",
        })
        data = fetch_json("https://ipapi.co/json/?" + params)
        if data.get("latitude") is not None and data.get("longitude") is not None:
            return (
                float(data["latitude"]),
                float(data["longitude"]),
                data.get("city") or "Current location",
                data.get("country_code") or "",
            )
    except Exception as e:
        sys.stderr.write(f"Weather IP location error: {e}\n")
    return None


def get_location(manual_location="", allow_ip_geolocation=False):
    if manual_location.strip():
        location = get_manual_location(manual_location)
        return location, "manual" if location else "manual_unavailable"

    if not allow_ip_geolocation:
        return None, "not_configured"

    location = get_ip_location()
    return location, "ip" if location else "ip_unavailable"


def unit_settings(units="auto", country_code=""):
    if units == "imperial":
        use_fahrenheit = True
    elif units == "metric":
        use_fahrenheit = False
    else:
        use_fahrenheit = country_code in ["US", "LR", "MM"]

    return {
        "temperature": "fahrenheit" if use_fahrenheit else "celsius",
        "temperature_suffix": "°F" if use_fahrenheit else "°C",
        "wind": "mph" if use_fahrenheit else "km/h",
        "wind_api": "mph" if use_fahrenheit else "kmh",
    }


WMO_DETAILS = {
    0: ("☀️", "Clear"),
    1: ("🌤️", "Mainly Clear"),
    2: ("⛅", "Partly Cloudy"),
    3: ("☁️", "Overcast"),
    45: ("🌫️", "Foggy"), 48: ("🌫️", "Foggy"),
    51: ("🌦️", "Drizzle"), 53: ("🌦️", "Drizzle"), 55: ("🌦️", "Drizzle"),
    61: ("🌧️", "Rainy"), 63: ("🌧️", "Rainy"), 65: ("🌧️", "Rainy"),
    71: ("❄️", "Snowy"), 73: ("❄️", "Snowy"), 75: ("❄️", "Snowy"),
    80: ("🌧️", "Showers"), 81: ("🌧️", "Showers"), 82: ("🌧️", "Showers"),
    95: ("⛈️", "Thunderstorm"), 96: ("⛈️", "Thunderstorm"), 99: ("⛈️", "Thunderstorm"),
}


def get_wmo_details(code):
    return WMO_DETAILS.get(code, ("❓", "Unknown"))


def get_weather(lat, lon, city, country_code, units="auto"):
    format_settings = unit_settings(units, country_code)
    temp_unit = format_settings["temperature"]
    temp_suffix = format_settings["temperature_suffix"]
    wind_unit = format_settings["wind"]
    
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m,weather_code,surface_pressure&daily=weathercode,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_probability_max&hourly=temperature_2m,weather_code&timezone=auto&temperature_unit={temp_unit}&wind_speed_unit={format_settings['wind_api']}"
    try:
        data = fetch_json(url)
        current = data.get("current", {})
        daily = data.get("daily", {})
        hourly = data.get("hourly", {})

        current_emoji, current_desc = get_wmo_details(current.get("weather_code"))
            
        # Construct forecast for 5 days.
        forecast = []
        times = daily.get("time", [])
        codes = daily.get("weathercode", [])
        max_temps = daily.get("temperature_2m_max", [])
        min_temps = daily.get("temperature_2m_min", [])

        limit = min(5, len(times), len(codes), len(max_temps), len(min_temps))
        for i in range(limit):
            emoji, desc = get_wmo_details(codes[i])
            forecast.append({
                "date": times[i],
                "emoji": emoji,
                "desc": desc,
                "max_temp": f"{int(round(max_temps[i]))}{temp_suffix}",
                "min_temp": f"{int(round(min_temps[i]))}{temp_suffix}"
            })

        # Construct hourly forecast for next 6 hours.
        hourly_forecast = []
        current_time = current.get("time")
        hour_boundary = (current_time.split(":")[0] + ":00") if current_time else None
        hourly_times = hourly.get("time", [])
        hourly_temps = hourly.get("temperature_2m", [])
        hourly_codes = hourly.get("weather_code", [])

        if hour_boundary in hourly_times:
            start_idx = hourly_times.index(hour_boundary)
            limit = min(start_idx + 6, len(hourly_times), len(hourly_temps), len(hourly_codes))
            for i in range(start_idx, limit):
                time_str = hourly_times[i]
                hour = time_str.split("T")[1] if "T" in time_str else time_str
                emoji, desc = get_wmo_details(hourly_codes[i])
                hourly_forecast.append({
                    "time": hour,
                    "temp": f"{int(round(hourly_temps[i]))}{temp_suffix}",
                    "emoji": emoji,
                    "desc": desc
                })

        return {
            "status": "ok",
            "message": "",
            "city": city,
            "current_temp": f"{int(round(current.get('temperature_2m', 0)))}{temp_suffix}",
            "current_emoji": current_emoji,
            "current_desc": current_desc,
            "humidity": f"{current.get('relative_humidity_2m', 0)}%",
            "apparent_temp": f"{int(round(current.get('apparent_temperature', 0)))}{temp_suffix}",
            "wind_speed": f"{int(round(current.get('wind_speed_10m', 0)))} {wind_unit}",
            "pressure": f"{int(round(current.get('surface_pressure', 0)))} hPa",
            "uv_index": str((daily.get("uv_index_max") or [0])[0]),
            "precipitation_chance": f"{(daily.get('precipitation_probability_max') or [0])[0]}%",
            "forecast": forecast,
            "hourly": hourly_forecast,
            "updated_at": datetime.datetime.now().astimezone().isoformat(timespec="seconds"),
        }
    except Exception as e:
        sys.stderr.write(f"Weather API error: {e}\n")
    return None


def unavailable_payload(status, message, units="metric", city="", country_code=""):
    format_settings = unit_settings(units, country_code)
    temp_suffix = format_settings["temperature_suffix"]
    wind_unit = format_settings["wind"]
    today = datetime.date.today()

    return {
        "status": status,
        "message": message,
        "city": city,
        "current_temp": "--" + temp_suffix,
        "current_emoji": "❓",
        "current_desc": "Unavailable",
        "humidity": "--%",
        "apparent_temp": "--" + temp_suffix,
        "wind_speed": "-- " + wind_unit,
        "pressure": "-- hPa",
        "uv_index": "--",
        "precipitation_chance": "--%",
        "forecast": [
            {
                "date": (today + datetime.timedelta(days=i)).isoformat(),
                "emoji": "❓",
                "desc": "Unavailable",
                "max_temp": "--" + temp_suffix,
                "min_temp": "--" + temp_suffix,
            }
            for i in range(5)
        ],
        "hourly": [],
        "updated_at": "",
    }


def main():
    units = sys.argv[1] if len(sys.argv) > 1 else "metric"
    manual_location = sys.argv[2] if len(sys.argv) > 2 else ""
    allow_ip_geolocation = len(sys.argv) > 3 and sys.argv[3].lower() in {"1", "true", "yes", "on"}

    location, source = get_location(manual_location, allow_ip_geolocation)
    if not location:
        messages = {
            "not_configured": "Set a manual location or enable IP geolocation.",
            "manual_unavailable": "Manual location could not be resolved.",
            "ip_unavailable": "IP location is unavailable. Set a manual location or try again.",
        }
        status = "unavailable" if source != "ip_unavailable" else "offline"
        print(json.dumps(unavailable_payload(status, messages[source], units)))
        return

    lat, lon, city, country_code = location
    weather = get_weather(lat, lon, city, country_code, units)
    if weather:
        weather["location_source"] = source
        print(json.dumps(weather))
        return

    print(json.dumps(unavailable_payload(
        "offline",
        "Weather service is unavailable. Check your connection and try again.",
        units,
        city,
        country_code,
    )))

if __name__ == '__main__':
    main()
