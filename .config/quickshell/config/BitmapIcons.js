.pragma library

// dwm style draws icons with the Siji bitmap font (siji-ng 1.2, 12px strike in the OTB).
// Install with scripts/install-siji.sh. Labels not listed here return ""
// and IconGlyph falls back to Material Symbols.
// Codepoints picked by eye from the font's glyph sheet; all lie in E000-E27A.
var symbols = {
  "air": 0xE235, "airplanemode_active": 0xE0A9, "airplanemode_inactive": 0xE0A9,
  "application": 0xE0B4, "apps": 0xE00A, "arrow_downward": 0xE12C, "arrow_upward": 0xE12B,
  "arrow_forward": 0xE12D, "arrow_back": 0xE12E, "aspect_ratio": 0xE0C1,
  "battery_1_bar": 0xE243, "battery_2_bar": 0xE244, "battery_3_bar": 0xE246,
  "battery_4_bar": 0xE247, "battery_5_bar": 0xE249, "battery_6_bar": 0xE24B,
  "battery_alert": 0xE211, "battery_charging_full": 0xE23F, "battery_full": 0xE24B,
  "battery_saver": 0xE242, "battery_unknown": 0xE242,
  "bedtime": 0xE233, "bluetooth": 0xE00B, "bluetooth_connected": 0xE00B,
  "bluetooth_searching": 0xE00B, "bolt": 0xE215, "bottom_app_bar": 0xE0B7,
  "brightness_2": 0xE233, "brightness_auto": 0xE1C3, "brightness_empty": 0xE1BC,
  "brightness_high": 0xE1C2, "brightness_low": 0xE1BC, "brightness_medium": 0xE1C3,
  "bubble_chart": 0xE195, "calendar_view_week": 0xE225, "chevron_left": 0xE1AC,
  "chevron_right": 0xE1AA, "circle": 0xE1C2, "cloud": 0xE22B, "cloud_off": 0xE22B,
  "code": 0xE1EC, "content_copy": 0xE1CF, "content_paste": 0xE1ED, "contrast": 0xE1C3,
  "dark_mode": 0xE233, "dashboard": 0xE00A, "delete": 0xE1E6, "delete_sweep": 0xE1E6,
  "device_thermostat": 0xE0CC, "dns": 0xE14A, "dock_to_bottom": 0xE0B7,
  "dock_to_left": 0xE0B5, "dock_to_right": 0xE0B5, "edit": 0xE1E5, "expand_more": 0xE12C,
  "foggy": 0xE22B, "folder": 0xE1D6, "grid_3x3": 0xE005, "grid_view": 0xE00A,
  "history": 0xE128, "image": 0xE1DA, "keyboard": 0xE26F, "lan": 0xE14A,
  "language": 0xE26D, "light_mode": 0xE234, "link": 0xE1CA, "location_on": 0xE26E,
  "looks_5": 0xE164, "mic": 0xE04C, "monitor": 0xE09F, "monitor_heart": 0xE223,
  "mouse": 0xE1C6, "music_note": 0xE05C, "my_location": 0xE26E, "navigation": 0xE26E,
  "nights_stay": 0xE233, "notifications": 0xE0AD, "notifications_active": 0xE0AD,
  "open_in_new": 0xE10A, "partly_cloudy_day": 0xE232, "pause": 0xE059,
  "performance": 0xE215, "person": 0xE075, "play_arrow": 0xE058, "play_circle": 0xE058,
  "power_off": 0xE10D, "power_settings_new": 0xE00D, "priority_high": 0xE0B3,
  "queue_music": 0xE05C, "radio_button_checked": 0xE1C2, "radio_button_unchecked": 0xE1BC,
  "rainy": 0xE22D, "schedule": 0xE016, "screenshot_monitor": 0xE09F, "search": 0xE1EE,
  "select_window": 0xE0B4, "settings": 0xE0AB, "skip_next": 0xE05A, "skip_previous": 0xE054,
  "snowing": 0xE22F, "sports_esports": 0xE00F, "stop": 0xE057, "storage": 0xE144,
  "sunny": 0xE231, "swap_horiz": 0xE11F, "swap_vert": 0xE10F, "sync": 0xE11F,
  "sync_alt": 0xE11F, "terminal": 0xE1EC, "thermostat": 0xE0CC, "thunderstorm": 0xE22C,
  "timer": 0xE016, "touchpad_mouse": 0xE1C6, "trending_up": 0xE12B, "tune": 0xE235,
  "umbrella": 0xE22D, "update": 0xE016, "view_quilt": 0xE0BA, "view_week": 0xE26B,
  "volume_down": 0xE0E1, "volume_mute": 0xE04F, "volume_off": 0xE04F, "volume_up": 0xE0E0,
  "wallpaper": 0xE1DA, "warning": 0xE0B3, "water_drop": 0xE1E4, "web_asset": 0xE0B5,
  "wifi": 0xE21A, "wifi_find": 0xE21A, "wifi_off": 0xE217, "window": 0xE0B4,
  "workspaces": 0xE005
}

function glyph(label) {
  return Object.prototype.hasOwnProperty.call(symbols, label)
    ? String.fromCodePoint(symbols[label]) : ""
}
