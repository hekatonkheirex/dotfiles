#!/usr/bin/env python3
import urllib.request
import json
import sys

def get_location():
    try:
        # Request geo IP data with a 4 second timeout
        req = urllib.request.Request("http://ip-api.com/json/", headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=4) as response:
            data = json.loads(response.read().decode())
            if data.get("status") == "success":
                return data.get("lat"), data.get("lon"), data.get("city"), data.get("countryCode")
    except Exception:
        pass
    return None

def get_weather(lat, lon, city, country_code):
    use_fahrenheit = country_code in ["US", "LR", "MM"]
    temp_unit = "fahrenheit" if use_fahrenheit else "celsius"
    temp_suffix = "°F" if use_fahrenheit else "°C"
    wind_unit = "mph" if use_fahrenheit else "km/h"
    
    url = f"https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&current=temperature_2m,relative_humidity_2m,apparent_temperature,precipitation,wind_speed_10m,weather_code,surface_pressure&daily=weathercode,temperature_2m_max,temperature_2m_min,uv_index_max,precipitation_probability_max&hourly=temperature_2m,weather_code&timezone=auto&temperature_unit={temp_unit}"
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=4) as response:
            data = json.loads(response.read().decode())
            current = data.get("current", {})
            daily = data.get("daily", {})
            hourly = data.get("hourly", {})
            
            # Map weather codes to emoji & description
            def get_wmo_details(code):
                mapping = {
                    0: ("☀️", "Clear"),
                    1: ("🌤️", "Mainly Clear"),
                    2: ("⛅", "Partly Cloudy"),
                    3: ("☁️", "Overcast"),
                    45: ("🌫️", "Foggy"), 48: ("🌫️", "Foggy"),
                    51: ("🌦️", "Drizzle"), 53: ("🌦️", "Drizzle"), 55: ("🌦️", "Drizzle"),
                    61: ("🌧️", "Rainy"), 63: ("🌧️", "Rainy"), 65: ("🌧️", "Rainy"),
                    71: ("❄️", "Snowy"), 73: ("❄️", "Snowy"), 75: ("❄️", "Snowy"),
                    80: ("🌧️", "Showers"), 81: ("🌧️", "Showers"), 82: ("🌧️", "Showers"),
                    95: ("⛈️", "Thunderstorm"), 96: ("⛈️", "Thunderstorm"), 99: ("⛈️", "Thunderstorm")
                }
                return mapping.get(code, ("❓", "Unknown"))

            current_emoji, current_desc = get_wmo_details(current.get("weather_code"))
            
            # Construct forecast for 5 days
            forecast = []
            times = daily.get("time", [])
            codes = daily.get("weathercode", [])
            max_temps = daily.get("temperature_2m_max", [])
            min_temps = daily.get("temperature_2m_min", [])
            
            limit = min(5, len(times))
            for i in range(limit):
                emoji, desc = get_wmo_details(codes[i])
                forecast.append({
                    "date": times[i],
                    "emoji": emoji,
                    "desc": desc,
                    "max_temp": f"{int(round(max_temps[i]))}{temp_suffix}",
                    "min_temp": f"{int(round(min_temps[i]))}{temp_suffix}"
                })
                
            # Construct hourly forecast for next 6 hours
            hourly_forecast = []
            current_time = current.get("time")
            hour_boundary = (current_time.split(":")[0] + ":00") if current_time else None
            hourly_times = hourly.get("time", [])
            hourly_temps = hourly.get("temperature_2m", [])
            hourly_codes = hourly.get("weather_code", [])
            
            if hour_boundary in hourly_times:
                start_idx = hourly_times.index(hour_boundary)
                for i in range(start_idx, min(start_idx + 6, len(hourly_times))):
                    time_str = hourly_times[i]
                    # Extract the hour: "19:00" from "2026-06-23T19:00"
                    hour = time_str.split("T")[1] if "T" in time_str else time_str
                    emoji, desc = get_wmo_details(hourly_codes[i])
                    hourly_forecast.append({
                        "time": hour,
                        "temp": f"{int(round(hourly_temps[i]))}{temp_suffix}",
                        "emoji": emoji,
                        "desc": desc
                    })
            else:
                for i in range(6):
                    hourly_forecast.append({
                        "time": f"+{i}h",
                        "temp": "--°C",
                        "emoji": "❓",
                        "desc": "Unknown"
                    })
                
            return {
                "city": city,
                "current_temp": f"{int(round(current.get('temperature_2m', 0)))}{temp_suffix}",
                "current_emoji": current_emoji,
                "current_desc": current_desc,
                "humidity": f"{current.get('relative_humidity_2m', 0)}%",
                "apparent_temp": f"{int(round(current.get('apparent_temperature', 0)))}{temp_suffix}",
                "wind_speed": f"{int(round(current.get('wind_speed_10m', 0)))} {wind_unit}",
                "pressure": f"{int(round(current.get('surface_pressure', 0)))} hPa",
                "uv_index": str(daily.get("uv_index_max", [0])[0]),
                "precipitation_chance": f"{daily.get('precipitation_probability_max', [0])[0]}%",
                "forecast": forecast,
                "hourly": hourly_forecast
            }
    except Exception as e:
        sys.stderr.write(f"Weather API error: {e}\n")
    return None

def main():
    loc = get_location()
    if not loc:
        # Fallback to Asunción if geo IP fails
        loc = (-25.2869, -57.6511, "Asunción", "PY")
        
    lat, lon, city, country_code = loc
    weather = get_weather(lat, lon, city, country_code)
    if weather:
        print(json.dumps(weather))
    else:
        # Fallback payload in case of errors
        print(json.dumps({
            "city": city, "current_temp": "--°C", "current_emoji": "❓", "current_desc": "Offline",
            "humidity": "--%", "apparent_temp": "--°C", "wind_speed": "-- km/h", "pressure": "-- hPa",
            "uv_index": "--", "precipitation_chance": "--%",
            "forecast": [{"date": "2026-06-23", "emoji": "❓", "desc": "Offline", "max_temp": "--°C", "min_temp": "--°C"} for _ in range(5)],
            "hourly": [{"time": f"+{h}h", "temp": "--°C", "emoji": "❓", "desc": "Offline"} for h in range(6)]
        }))

if __name__ == '__main__':
    main()
