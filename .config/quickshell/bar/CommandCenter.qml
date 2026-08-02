import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Effects
import Quickshell.Services.UPower
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io

PanelWindow {
  id: root

  property QtObject colors_: null
  property QtObject config: null

  signal dismissed()

  property bool isHorizontal: false
  signal toggleHorizontal()

  property int currentTab: 0 // Default to Overview tab
  property double openTime: 0

  // Session & Weather properties
  property string uptimeText: "up ..."
  property string weatherCity: "Asunción"
  property string weatherIcon: "❓"
  property string weatherTemp: "--°C"
  property string weatherDesc: "Loading..."
  property var weatherForecast: []
  property string weatherHumidity: "--%"
  property string weatherFeelsLike: "--"
  property string weatherWind: "--"
  property string weatherPressure: "--"
  property string weatherUV: "--"
  property string weatherPrecipChance: "--%"
  property var weatherHourly: []

  // Helper functions to map weather description to Material Symbols Rounded and beautiful colors
  function getMaterialIcon(desc) {
    var d = (desc || "").toLowerCase();
    if (d.indexOf("clear") !== -1) return "sunny";
    if (d.indexOf("partly") !== -1 || d.indexOf("mainly") !== -1) return "partly_cloudy_day";
    if (d.indexOf("cloudy") !== -1 || d.indexOf("overcast") !== -1) return "cloud";
    if (d.indexOf("fog") !== -1) return "foggy";
    if (d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "rainy";
    if (d.indexOf("rain") !== -1) return "rainy";
    if (d.indexOf("snow") !== -1) return "snowing";
    if (d.indexOf("thunder") !== -1) return "thunderstorm";
    return "sunny";
  }

  function getMaterialColor(desc) {
    var d = (desc || "").toLowerCase();
    if (d.indexOf("clear") !== -1) return "#FFB703"; // warm amber
    if (d.indexOf("partly") !== -1 || d.indexOf("mainly") !== -1) return "#90CAF9"; // soft blue
    if (d.indexOf("cloudy") !== -1 || d.indexOf("overcast") !== -1) return "#B0BEC5"; // grey-blue
    if (d.indexOf("fog") !== -1) return "#CFD8DC"; // light grey
    if (d.indexOf("drizzle") !== -1 || d.indexOf("shower") !== -1) return "#4FC3F7"; // light rain
    if (d.indexOf("rain") !== -1) return "#29B6F6"; // rain blue
    if (d.indexOf("snow") !== -1) return "#E0F7FA"; // snowy white-cyan
    if (d.indexOf("thunder") !== -1) return "#AB47BC"; // thunderstorm purple
    return "#FFB703";
  }

  // MPRIS Media properties
  property string mprisStatus: "NoPlayer"
  property string mprisTitle: ""
  property string mprisArtist: ""
  property string mprisAlbum: ""
  property string mprisArtUrl: ""
  property int mprisLengthSec: 0
  property string mprisLengthStr: "0:00"

  // Track elapsed seconds
  property int elapsedSeconds: 0
  property var cavaBarValues: []

  // Reset elapsed time when track changes
  onMprisTitleChanged: {
    elapsedSeconds = 0
  }

  // Timer to increment playback position
  Timer {
    id: playbackTimer
    interval: 1000
    running: root.visible && root.mprisStatus === "Playing"
    repeat: true
    onTriggered: {
      if (root.elapsedSeconds < root.mprisLengthSec) {
        root.elapsedSeconds += 1
      }
    }
  }

  function formatTime(sec) {
    var m = Math.floor(sec / 60)
    var s = sec % 60
    return m + ":" + (s < 10 ? "0" : "") + s
  }

  function applyPresetColor(hex) {
    Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-accent-color.sh", hex])
  }

  // UPower laptop battery detection
  readonly property var batteryDevice: {
    for (var i = 0; i < UPower.devices.count; i++) {
      var d = UPower.devices.get(i)
      if (d.ready && d.isLaptopBattery) return d
    }
    if (UPower.displayDevice && UPower.displayDevice.ready)
      return UPower.displayDevice
    return null
  }
  readonly property real batteryPct: batteryDevice ? batteryDevice.percentage * 100 : 100
  readonly property bool batteryCharging: batteryDevice ? (batteryDevice.state === UPowerDeviceState.Charging || batteryDevice.state === UPowerDeviceState.PendingCharge) : false

  // Volume state
  property real systemVolume: 0.5
  property bool systemMuted: false

  Process {
    id: ccAudioQuery
    command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var out = text.trim()
        var m = /Volume:\s*([\d.]+)/.exec(out)
        if (m) root.systemVolume = parseFloat(m[1])
        root.systemMuted = out.indexOf("[MUTED]") >= 0
      }
    }
  }

  function ccPollAudio() { ccAudioQuery.running = true }

  function ccSetVolume(val) {
    root.systemVolume = Math.max(0, Math.min(1, val))
    Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", String(root.systemVolume)])
  }

  Process {
    id: ccAudioWatcher
    command: ["pactl", "subscribe"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        if (data.indexOf("sink") >= 0) {
          root.ccPollAudio()
        }
      }
    }
    onRunningChanged: {
      if (!running && root.visible) ccAudioWatcherRetry.start()
    }
  }

  Timer {
    id: ccAudioWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) ccAudioWatcher.running = true
    }
  }

  // Brightness state
  property real systemBrightness: 50

  Process {
    id: ccGetBrightness
    command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d %"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var val = parseFloat(text.trim())
        if (!isNaN(val)) {
          root.systemBrightness = val
        }
      }
    }
  }

  function ccFetchBrightness() { ccGetBrightness.running = true }

  function ccSetBrightness(val) {
    root.systemBrightness = Math.max(0, Math.min(100, val))
    Quickshell.execDetached(["brightnessctl", "set", Math.round(root.systemBrightness) + "%"])
  }

  Process {
    id: ccBrightnessWatcher
    command: ["sh", "-c", "inotifywait -m -e modify /sys/class/backlight/*/brightness"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        root.ccFetchBrightness()
      }
    }
    onRunningChanged: {
      if (!running && root.visible) ccBrightnessWatcherRetry.start()
    }
  }

  Timer {
    id: ccBrightnessWatcherRetry
    interval: 1000
    onTriggered: {
      if (root.visible) ccBrightnessWatcher.running = true
    }
  }

  // Clock properties
  property string clockHours: "00"
  property string clockMinutes: "00"
  property string clockDate: "Jan 01"

  Timer {
    id: clockTimer
    interval: 1000
    running: root.visible
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      var d = new Date();
      var hrs = d.getHours();
      clockHours = (hrs < 10 ? "0" : "") + hrs;
      var mins = d.getMinutes();
      clockMinutes = (mins < 10 ? "0" : "") + mins;
      clockDate = d.toLocaleDateString(Qt.locale(), "MMM dd");
    }
  }

  // Calendar properties
  property date currentDate: new Date()
  property date displayMonth: new Date(currentDate.getFullYear(), currentDate.getMonth(), 1)
  
  readonly property var weekDays: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
  readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  function daysInMonth(d) {
    return new Date(d.getFullYear(), d.getMonth() + 1, 0).getDate()
  }

  function monthStartDay(d) {
    return new Date(d.getFullYear(), d.getMonth(), 1).getDay()
  }

  function isToday(dayNum) {
    var today = new Date()
    return dayNum === today.getDate()
      && displayMonth.getMonth() === today.getMonth()
      && displayMonth.getFullYear() === today.getFullYear()
  }

  function buildDayModel(date) {
    if (!date || isNaN(date.getTime())) return []
    var list = []
    var startDay = monthStartDay(date)
    var days = daysInMonth(date)
    for (var i = 0; i < startDay; i++) list.push(-1)
    for (var d = 1; d <= days; d++) list.push(d)
    while (list.length % 7 !== 0) list.push(-1)
    return list
  }

  property var dayModel: buildDayModel(displayMonth)

  onDisplayMonthChanged: {
    dayModel = buildDayModel(displayMonth)
  }

  function getBatteryIcon(pct, charging) {
    if (charging) return "battery_charging_full"
    if (pct <= 10) return "battery_alert"
    if (pct <= 20) return "battery_1_bar"
    if (pct <= 40) return "battery_2_bar"
    if (pct <= 60) return "battery_3_bar"
    if (pct <= 80) return "battery_4_bar"
    if (pct <= 95) return "battery_5_bar"
    return "battery_full"
  }

  Component {
    id: verticalSliderComponent
    Item {
      id: sliderRoot
      property string icon: ""
      property real value: 0.0 // 0 to 1
      property bool interactive: true
      property color activeColor: colors_ ? colors_.primary : "#BEE8C7"
      signal sliderMoved(real newValue)

      ColumnLayout {
        anchors.fill: parent
        spacing: 8

        Rectangle {
          id: track
          Layout.fillWidth: true
          Layout.fillHeight: true
          radius: 8
          color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
          clip: true

          Rectangle {
            width: parent.width
            height: parent.height * sliderRoot.value
            radius: 8
            color: sliderRoot.activeColor
            anchors.bottom: parent.bottom
          }

          MouseArea {
            anchors.fill: parent
            enabled: sliderRoot.interactive
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            
            function handleMouse(mouse) {
              var clickY = Math.max(0, Math.min(height, mouse.y));
              var newVal = 1.0 - (clickY / height);
              sliderRoot.sliderMoved(newVal);
            }

            onPressed: function(mouse) { handleMouse(mouse) }
            onPositionChanged: function(mouse) { handleMouse(mouse) }
            
            onWheel: function(wheel) {
              var step = 0.05
              var delta = wheel.angleDelta.y > 0 ? step : -step
              var newVal = Math.max(0.0, Math.min(1.0, sliderRoot.value + delta))
              sliderRoot.sliderMoved(newVal)
            }
          }
        }

        Rectangle {
          width: 26
          height: 26
          radius: 13
          color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
          border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
          border.width: 1
          Layout.alignment: Qt.AlignHCenter

          Text {
            anchors.centerIn: parent
            text: sliderRoot.icon
            font.family: config ? config.iconFont : "Material Symbols Outlined"
            font.pixelSize: 14
            color: colors_ ? colors_.fgSurface : "#FFFFFF"
          }
        }
      }
    }
  }

  // Wallpapers list
  property var wallpapersList: []

  // Current active wallpaper
  property string currentWallpaper: ""

  Process {
    id: ccGetWallpaper
    command: ["sh", "-c", "awww query | grep -o 'image: .*' | cut -d' ' -f2 | xargs basename"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.currentWallpaper = text.trim()
        if (root.currentTab === 2) {
          scrollTimer.start()
        }
      }
    }
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim()) {
        }
      }
    }
  }

  Timer {
    id: scrollTimer
    interval: 150
    running: false
    repeat: false
    onTriggered: {
      if (root.currentWallpaper && root.wallpapersList.length > 0) {
        var idx = root.wallpapersList.indexOf(root.currentWallpaper);
        if (idx >= 0 && typeof wallpaperGrid !== "undefined" && wallpaperGrid) {
          wallpaperGrid.positionViewAtIndex(idx, GridView.Center);
        }
      }
    }
  }

  onCurrentTabChanged: {
    if (currentTab === 2) {
      ccGetWallpaper.running = false;
      ccGetWallpaper.running = true;
      scrollTimer.start();
    }
  }

  // System Diagnostics Stats
  property real statsCpu: 0
  property string statsRamStr: "0.0 / 0.0 GB"
  property real statsRamPct: 0.0
  property string statsDiskStr: "0.0 / 0.0 GB"
  property real statsDiskPct: 0.0

  Process {
    id: statsProc
    command: ["sh", "-c", "cpu=$(top -bn1 | grep 'Cpu(s)' | sed 's/.*, *\\([0-9.]*\\)%* id.*/\\1/' | awk '{print 100 - $1}'); mem=$(free -m | awk '/Mem:/ { printf \"%d,%d,%d\", $3, $2, $3*100/$2 }'); disk=$(df -h / | awk '/\\// {printf \"%s,%s,%s\", $3, $2, $5}' | head -n 1); echo \"$cpu|$mem|$disk\""]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parts = text.trim().split("|");
          if (parts.length >= 3) {
            root.statsCpu = parseFloat(parts[0]);
            
            var memParts = parts[1].split(",");
            var memUsedGb = (parseFloat(memParts[0]) / 1024.0).toFixed(1);
            var memTotalGb = (parseFloat(memParts[1]) / 1024.0).toFixed(1);
            root.statsRamStr = memUsedGb + " / " + memTotalGb + " GB";
            root.statsRamPct = parseFloat(memParts[2]) / 100.0;

            var diskParts = parts[2].split(",");
            var diskUsed = diskParts[0];
            var diskTotal = diskParts[1];
            var diskPctVal = parseFloat(diskParts[2].replace("%", ""));
            root.statsDiskStr = diskUsed + " / " + diskTotal;
            root.statsDiskPct = diskPctVal / 100.0;
          }
        } catch(e) {}
      }
    }
  }

  Timer {
    id: statsTimer
    interval: 3000
    running: root.visible && root.currentTab === 4
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statsProc.running = false;
      statsProc.running = true;
    }
  }

  implicitWidth: 800
  visible: false
  implicitHeight: 606
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.namespace: "quickshell-popup"
  WlrLayershell.layer: WlrLayer.Top

  // Center window on desktop
  property int desktopW: Screen.desktopAvailableWidth
  property int desktopH: Screen.desktopAvailableHeight

  anchors.left: true
  margins.left: (desktopW - implicitWidth) / 2
  anchors.top: true
  margins.top: (desktopH - implicitHeight) / 2

  property bool caffeineOn: false

  // Find wallpapers on start
  Process {
    id: listWallpapersProc
    command: ["sh", "-c", "find " + Quickshell.env("HOME") + "/Pictures/Walls -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' -o -iname '*.webp' \\) -printf '%f\\n' | sort"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var list = text.trim().split("\n");
        var arr = [];
        for (var i = 0; i < list.length; i++) {
          var line = list[i].trim();
          if (line) arr.push(line);
        }
        root.wallpapersList = arr;
      }
    }
  }

  // Pre-generate wallpaper thumbnails on start
  Process {
    id: genWallpapersThumbsProc
    command: [Quickshell.env("HOME") + "/.config/quickshell/scripts/generate-thumbnails.sh"]
    running: true
  }

  // Uptime Process
  Process {
    id: uptimeProc
    command: ["uptime", "-p"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.uptimeText = text.trim();
      }
    }
  }

  Timer {
    id: uptimeTimer
    interval: 60000
    running: root.visible
    repeat: true
    onTriggered: {
      uptimeProc.running = false
      uptimeProc.running = true
    }
  }

  // Weather Process
  Process {
    id: weatherProc
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/weather.py"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var info = JSON.parse(text.trim());
          root.weatherCity = info.city;
          root.weatherIcon = info.current_emoji;
          root.weatherTemp = info.current_temp;
          root.weatherDesc = info.current_desc;
          root.weatherHumidity = info.humidity;
          root.weatherFeelsLike = info.apparent_temp;
          root.weatherWind = info.wind_speed;
          root.weatherPressure = info.pressure;
          root.weatherUV = info.uv_index;
          root.weatherPrecipChance = info.precipitation_chance;
          root.weatherForecast = info.forecast;
          root.weatherHourly = info.hourly;
        } catch (e) {
          // Parse error
        }
      }
    }
  }

  Timer {
    id: weatherTimer
    interval: 900000 // 15 minutes
    running: root.visible
    repeat: true
    onTriggered: {
      weatherProc.running = false
      weatherProc.running = true
    }
  }

  // MPRIS Process
  Process {
    id: mprisProcess
    command: ["python3", "-u", Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_monitor.py"]
    running: root.visible
    stdout: SplitParser {
      onRead: function(data) {
        try {
          var info = JSON.parse(data.trim());
          root.mprisStatus = info.status;
          root.mprisTitle = info.title;
          root.mprisArtist = info.artist;
          root.mprisAlbum = info.album;
          root.mprisArtUrl = info.artUrl;
          root.mprisLengthSec = info.length_sec;
          root.mprisLengthStr = info.length_str;
        } catch (e) {
          // Parse error
        }
      }
    }

    onRunningChanged: {
      if (!running && root.visible) {
        mprisProcessRetry.start()
      }
    }
  }

  Timer {
    id: mprisProcessRetry
    interval: 3000
    onTriggered: {
      if (root.visible) mprisProcess.running = true
    }
  }

  Process {
    id: cavaProcess
    command: ["cava", "-p", Quickshell.env("HOME") + "/.config/quickshell/config/cava.ini"]
    running: root.visible && (root.currentTab === 0 || root.currentTab === 1)
    stdout: SplitParser {
      onRead: function(data) {
        var parts = data.trim().split(";");
        var vals = [];
        for (var i = 0; i < parts.length; i++) {
          var n = parseInt(parts[i]);
          if (!isNaN(n)) vals.push(n);
        }
        if (vals.length === 0) return;
        var prev = root.cavaBarValues;
        if (prev && prev.length === vals.length) {
          var smoothed = [];
          for (var j = 0; j < vals.length; j++)
            smoothed.push(prev[j] * 0.4 + vals[j] * 0.6);
          root.cavaBarValues = smoothed;
        } else {
          root.cavaBarValues = vals;
        }
      }
    }
    onRunningChanged: {
      if (!running) {
        root.cavaBarValues = [];
        if (root.visible && root.currentTab === 1) cavaRetry.start();
      }
    }
  }

  Timer {
    id: cavaRetry
    interval: 2000
    onTriggered: {
      if (root.visible && root.currentTab === 1) cavaProcess.running = true;
    }
  }

  Process {
    id: idleCheck
    command: ["sh", "-c", "pgrep -x swayidle >/dev/null 2>&1 && echo active || echo inactive"]
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        root.caffeineOn = text.trim() !== "active"
      }
    }
  }

  onVisibleChanged: {
    if (visible) {
      idleCheck.running = true
      entryAnimation.start()
      mainItem.forceActiveFocus()
      root.openTime = Date.now()

      // Refresh dynamic content
      uptimeProc.running = false
      uptimeProc.running = true
      weatherProc.running = false
      weatherProc.running = true
      mprisProcess.running = false
      mprisProcess.running = true
      root.ccPollAudio()
      root.ccFetchBrightness()
      ccGetWallpaper.running = false
      ccGetWallpaper.running = true
    }
  }

  WlrLayershell.focusable: true

  Component.onCompleted: {
    Qt.application.activeChanged.connect(function() {
      if (!Qt.application.active && root.visible) root.dismissed()
    })
  }

  Item {
    id: mainItem
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      if (event.key === Qt.Key_Escape) {
        if (Date.now() - root.openTime > 150) {
          root.dismissed()
        }
        event.accepted = true
      }
    }

    Rectangle {
      id: bg
      anchors.fill: parent
      radius: config ? config.borderRadius : 16
      color: colors_ ? colors_.surfaceContainerHigh : "#2B2930"
      clip: true
      border.width: 1
      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)

      transform: [
        Translate { id: transX; x: 0 },
        Scale { id: scaleTransform; origin.x: bg.width / 2; origin.y: bg.height / 2; xScale: 1.0; yScale: 1.0 }
      ]

      ParallelAnimation {
        id: entryAnimation
        NumberAnimation {
          target: scaleTransform
          properties: "xScale,yScale"
          from: 0.85
          to: 1.0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: transX
          property: "x"
          from: -30
          to: 0
          duration: 250
          easing.type: Easing.OutBack
        }
        NumberAnimation {
          target: bg
          property: "opacity"
          from: 0.0
          to: 1.0
          duration: 200
          easing.type: Easing.OutCubic
        }
      }

      Column {
        id: contentColumn
        anchors {
          fill: parent
          margins: 24
        }
        spacing: 12

        // Tab Bar (DankMaterialShell centered vertical icon-label design)
        Item {
          width: parent.width
          height: 64

          RowLayout {
            anchors.fill: parent
            spacing: 0

            Repeater {
              model: [
                { icon: "grid_view", label: "Overview" },
                { icon: "music_note", label: "Media" },
                { icon: "wallpaper", label: "Wallpapers" },
                { icon: "wb_sunny", label: "Weather" },
                { icon: "settings", label: "Settings" }
              ]

              delegate: Item {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                Layout.fillHeight: true

                Column {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.icon
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 28
                    color: root.currentTab === index ? (colors_ ? colors_.primary : "#BEE8C7") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")

                    Behavior on color { ColorAnimation { duration: 150 } }
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: modelData.label
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                    color: root.currentTab === index ? (colors_ ? colors_.primary : "#BEE8C7") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")

                    Behavior on color { ColorAnimation { duration: 150 } }
                  }
                }

                // Active indicator line below the text
                Rectangle {
                  width: 48
                  height: 3
                  radius: 1.5
                  color: colors_ ? colors_.primary : "#BEE8C7"
                  anchors.bottom: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  visible: root.currentTab === index
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    root.currentTab = index
                  }
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: 1
          color: colors_ ? Qt.rgba(colors_.outline.r, colors_.outline.g, colors_.outline.b, 0.12) : Qt.rgba(255, 255, 255, 0.08)
        }

        // Tab Content Area Container
        Item {
          id: tabContainer
          width: parent.width
          height: 480

          // Tab 0: Overview (Session Card, Status Info, System Stats Greeting)
          Row {
            id: overviewTab
            anchors.fill: parent
            spacing: 16
            visible: root.currentTab === 0

            // Column 1: Clock & Weather
            Column {
              width: 148
              height: parent.height
              spacing: 16

              // Clock Card
              Rectangle {
                width: 148
                height: 232
                radius: 20
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Column {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockHours
                    color: colors_ ? colors_.primary : "#BEE8C7"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 64
                    font.weight: Font.Bold
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockMinutes
                    color: colors_ ? colors_.primary : "#BEE8C7"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 64
                    font.weight: Font.Bold
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockDate
                    color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 13
                    font.weight: Font.Medium
                  }
                }
              }

              // Weather Card
              Rectangle {
                width: 148
                height: 232
                radius: 20
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Column {
                  anchors.centerIn: parent
                  spacing: 8

                  Text {
                    text: getMaterialIcon(root.weatherDesc)
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 64
                    color: getMaterialColor(root.weatherDesc)
                    verticalAlignment: Text.AlignVCenter
                  }

                  Text {
                    text: root.weatherTemp
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                  }

                  Text {
                    text: root.weatherDesc
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: 120
                    horizontalAlignment: Text.AlignHCenter
                  }
                }
              }
            }

            // Column 2: Profile + Calendar
            Column {
              width: 408
              height: parent.height
              spacing: 16

              // Profile Card
                Rectangle {
                  width: 408
                  height: 120
                  radius: 20
                  color: colors_ ? colors_.surfaceContainer : "#25232A"
                  border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                  border.width: 1

                  Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                      id: profilePicContainer
                      width: 72
                      height: 72
                      radius: 36
                      color: colors_ ? colors_.surfaceContainerHighest : "#3C3A43"
                      anchors.verticalCenter: parent.verticalCenter

                      Image {
                        id: profilePicCC
                        source: "file://" + Quickshell.env("HOME") + "/.face.icon"
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        visible: false
                      }

                      Rectangle {
                        id: profileMaskCC
                        anchors.fill: parent
                        radius: 36
                        color: "black"
                        visible: false
                        layer.enabled: true
                      }

                      MultiEffect {
                        id: profilePicEffect
                        anchors.fill: parent
                        source: profilePicCC
                        visible: profilePicCC.status === Image.Ready
                        maskEnabled: true
                        maskSource: profileMaskCC
                      }

                      Text {
                        id: fallbackPicCC
                        anchors.centerIn: parent
                        text: "person"
                        font.family: config ? config.iconFont : "Material Symbols Outlined"
                        font.pixelSize: 36
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        visible: profilePicCC.status !== Image.Ready
                      }
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 6

                      Text {
                        text: Quickshell.env("USER") || "User"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 18
                        font.weight: Font.Bold
                      }

                      Row {
                        spacing: 6
                        Text {
                          text: "navigation"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 14
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "on niri"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 13
                        }
                      }

                      Row {
                        spacing: 6
                        Text {
                          text: "schedule"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 14
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        }
                        Text {
                          text: root.uptimeText.replace("up ", "")
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 13
                          elide: Text.ElideRight
                          width: 120
                        }
                      }
                    }
                  }
                }

              // Calendar Card
              Rectangle {
                width: 408
                height: 344
                radius: 20
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 16
                  spacing: 12

                  // Month Navigation Row
                  Item {
                    Layout.fillWidth: true
                    height: 32

                    Text {
                      text: root.monthNames[root.displayMonth.getMonth()] + " " + root.displayMonth.getFullYear()
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 16
                      font.weight: Font.Bold
                      anchors.left: parent.left
                      anchors.verticalCenter: parent.verticalCenter
                    }

                    Row {
                      id: navArrows
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 4

                      Repeater {
                        model: ["chevron_left", "chevron_right"]
                        Rectangle {
                          width: 32
                          height: 32
                          radius: 16
                          color: calNavArea.containsMouse ? (colors_ ? colors_.surfaceContainerHighest : "#36343B") : "transparent"
                          Behavior on color {
                            ColorAnimation { duration: config ? config.animationDuration : 150 }
                          }
                          Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: colors_ ? colors_.fgSurface : "#FFFFFF"
                            font.family: config ? config.iconFont : "Material Symbols Outlined"
                            font.pixelSize: 18
                          }
                          MouseArea {
                            id: calNavArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              var m = new Date(root.displayMonth)
                              m.setMonth(m.getMonth() + (index === 0 ? -1 : 1))
                              root.displayMonth = m
                            }
                          }
                        }
                      }
                    }
                  }

                  // Days of Week Header
                  Row {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: 4
                    Repeater {
                      model: root.weekDays
                      Text {
                        text: modelData
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        width: 50
                        height: 24
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                      }
                    }
                  }

                  // Calendar Grid
                  Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Repeater {
                      model: root.dayModel

                      Rectangle {
                        property int dayNum: modelData
                        visible: dayNum > 0
                        x: (index % 7) * 54
                        y: Math.floor(index / 7) * (parent.height / 6)
                        width: 50
                        height: (parent.height / 6) - 6
                        radius: 15
                        color: root.isToday(dayNum) ? (colors_ ? colors_.primary : "#BEE8C7") : "transparent"

                        Text {
                          anchors.centerIn: parent
                          text: dayNum > 0 ? dayNum.toString() : ""
                          color: root.isToday(dayNum)
                            ? (colors_ ? colors_.fgPrimary : "#0F3C2C")
                            : (colors_ ? colors_.fgSurface : "#FFFFFF")
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 12
                          font.weight: root.isToday(dayNum) ? Font.Bold : Font.Normal
                        }
                      }
                    }
                  }
                }
              }
            }

            // Column 3: Mini Media Player Card
            Rectangle {
              width: 164
              height: parent.height
              radius: 20
              color: colors_ ? colors_.surfaceContainer : "#25232A"
              border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
              border.width: 1

              Column {
                anchors.centerIn: parent
                width: parent.width - 24
                spacing: 16

                // Rotating cover art blob
                Item {
                  id: miniCoverArtContainer
                  width: 160
                  height: 160
                  anchors.horizontalCenter: parent.horizontalCenter

                  SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: root.visible && root.mprisStatus === "Playing"
                    NumberAnimation { to: 1.04; duration: 350; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0.96; duration: 450; easing.type: Easing.InOutQuad }
                  }

                  Canvas {
                    id: miniVizCanvas
                    anchors.fill: parent

                    Connections {
                      target: root
                      function onCavaBarValuesChanged() { miniVizCanvas.requestPaint() }
                    }

                    onPaint: {
                      var ctx = getContext("2d");
                      ctx.clearRect(0, 0, width, height);
                      var bars = root.cavaBarValues;
                      if (!bars || bars.length === 0) return;

                      var cx = width / 2;
                      var cy = height / 2;
                      var n = bars.length;
                      var baseR = 48;
                      var maxExtend = 28;
                      var steps = 120;

                      var primary = colors_ ? colors_.primary : Qt.rgba(0.66, 0.78, 1, 1);
                      var r = Math.round(primary.r * 255);
                      var g = Math.round(primary.g * 255);
                      var b = Math.round(primary.b * 255);

                      var maxVal = 0;
                      for (var k = 0; k < n; k++) maxVal = Math.max(maxVal, bars[k]);
                      var intensity = maxVal / 100.0;

                      ctx.beginPath();
                      for (var s = 0; s <= steps; s++) {
                        var angle = (s / steps) * 2 * Math.PI - Math.PI / 2;
                        var binFloat = (s / steps) * n;
                        var bin0 = Math.floor(binFloat) % n;
                        var bin1 = (bin0 + 1) % n;
                        var t = binFloat - Math.floor(binFloat);
                        t = (1 - Math.cos(t * Math.PI)) / 2;
                        var val = (bars[bin0] * (1 - t) + bars[bin1] * t) / 100.0;
                        var radius = baseR + val * maxExtend;
                        var x = cx + radius * Math.cos(angle);
                        var y = cy + radius * Math.sin(angle);
                        if (s === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                      }
                      ctx.closePath();

                      var grad = ctx.createRadialGradient(cx, cy, baseR * 0.6, cx, cy, baseR + maxExtend);
                      grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + "," + (intensity * 0.45).toFixed(2) + ")");
                      grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.0)");
                      ctx.fillStyle = grad;
                      ctx.fill();

                      ctx.strokeStyle = "rgba(" + r + "," + g + "," + b + "," + (0.3 + intensity * 0.6).toFixed(2) + ")";
                      ctx.lineWidth = 2;
                      ctx.lineJoin = "round";
                      ctx.stroke();
                    }
                  }

                  Rectangle {
                    width: 86
                    height: 86
                    radius: 43
                    clip: true
                    anchors.centerIn: parent
                    color: colors_ ? colors_.surfaceContainerHighest : "#3C3A43"

                    Image {
                      source: root.mprisArtUrl ? root.mprisArtUrl : ""
                      anchors.fill: parent
                      fillMode: Image.PreserveAspectCrop
                    }

                    Rectangle {
                      anchors.fill: parent
                      color: "transparent"
                      visible: root.mprisArtUrl === ""

                      Text {
                        anchors.centerIn: parent
                        text: "music_note"
                        font.family: config ? config.iconFont : "Material Symbols Outlined"
                        font.pixelSize: 32
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                      }
                    }
                  }
                }

                // Title & Artist
                Column {
                  width: parent.width
                  spacing: 2

                  Text {
                    width: parent.width
                    text: root.mprisTitle ? root.mprisTitle : "No Media"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }

                  Text {
                    width: parent.width
                    text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
                    color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }
                }

                WaveProgressBar {
                  width: parent.width - 12
                  anchors.horizontalCenter: parent.horizontalCenter
                  progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
                  activeColor: colors_ ? colors_.primary : "#BEE8C7"
                  trackColor: colors_ ? colors_.surfaceContainerHighest : "#3C3A43"
                  lineWidth: 2.5
                  dotRadius: 4
                  trackLineWidth: 1.5
                }

                // Playback Controls Row
                Row {
                  anchors.horizontalCenter: parent.horizontalCenter
                  spacing: 10

                  // Prev
                  Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    Text {
                      anchors.centerIn: parent
                      text: "skip_previous"
                      font.family: config ? config.iconFont : "Material Symbols Outlined"
                      font.pixelSize: 18
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "prev"])
                      }
                    }
                  }

                  // Play/Pause (circular accent)
                  Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    color: colors_ ? colors_.primary : "#BEE8C7"
                    Text {
                      anchors.centerIn: parent
                      text: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
                      font.family: config ? config.iconFont : "Material Symbols Outlined"
                      font.pixelSize: 20
                      color: colors_ ? colors_.fgPrimary : "#0F3C2C"
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
                      }
                    }
                  }

                  // Next
                  Rectangle {
                    width: 32
                    height: 32
                    radius: 16
                    color: "transparent"
                    Text {
                      anchors.centerIn: parent
                      text: "skip_next"
                      font.family: config ? config.iconFont : "Material Symbols Outlined"
                      font.pixelSize: 18
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    }
                    MouseArea {
                      anchors.fill: parent
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "next"])
                      }
                    }
                  }
                }
              }
            }
          }

          // Tab 1: Media Player (DankMaterialShell inspired design)
          Item {
            anchors.fill: parent
            visible: root.currentTab === 1

            // Blurred Album Art Background
            Image {
              source: root.mprisArtUrl ? root.mprisArtUrl : ""
              anchors.fill: parent
              fillMode: Image.PreserveAspectCrop
              opacity: 0.12
              visible: root.mprisArtUrl !== ""
            }


            // Central Media Player Layout
            ColumnLayout {
              anchors.centerIn: parent
              width: parent.width - 120
              spacing: 24

              // Centered Album Art & Rotating Wave outline
              Item {
                Layout.alignment: Qt.AlignHCenter
                width: 280
                height: 280

                Canvas {
                  id: vizCanvas
                  anchors.fill: parent

                  Connections {
                    target: root
                    function onCavaBarValuesChanged() { vizCanvas.requestPaint() }
                  }

                  onPaint: {
                    var ctx = getContext("2d");
                    ctx.clearRect(0, 0, width, height);
                    var bars = root.cavaBarValues;
                    if (!bars || bars.length === 0) return;

                    var cx = width / 2;
                    var cy = height / 2;
                    var n = bars.length;
                    var baseR = 74;
                    var maxExtend = 56;
                    var steps = 180;

                    var primary = colors_ ? colors_.primary : Qt.rgba(0.66, 0.78, 1, 1);
                    var r = Math.round(primary.r * 255);
                    var g = Math.round(primary.g * 255);
                    var b = Math.round(primary.b * 255);

                    var maxVal = 0;
                    for (var k = 0; k < n; k++) maxVal = Math.max(maxVal, bars[k]);
                    var intensity = maxVal / 100.0;

                    ctx.beginPath();
                    for (var s = 0; s <= steps; s++) {
                      var angle = (s / steps) * 2 * Math.PI - Math.PI / 2;
                      var binFloat = (s / steps) * n;
                      var bin0 = Math.floor(binFloat) % n;
                      var bin1 = (bin0 + 1) % n;
                      var t = binFloat - Math.floor(binFloat);
                      t = (1 - Math.cos(t * Math.PI)) / 2;
                      var val = (bars[bin0] * (1 - t) + bars[bin1] * t) / 100.0;
                      var radius = baseR + val * maxExtend;
                      var x = cx + radius * Math.cos(angle);
                      var y = cy + radius * Math.sin(angle);
                      if (s === 0) ctx.moveTo(x, y);
                      else ctx.lineTo(x, y);
                    }
                    ctx.closePath();

                    var grad = ctx.createRadialGradient(cx, cy, baseR * 0.6, cx, cy, baseR + maxExtend);
                    grad.addColorStop(0, "rgba(" + r + "," + g + "," + b + "," + (intensity * 0.45).toFixed(2) + ")");
                    grad.addColorStop(1, "rgba(" + r + "," + g + "," + b + ",0.0)");
                    ctx.fillStyle = grad;
                    ctx.fill();

                    ctx.strokeStyle = "rgba(" + r + "," + g + "," + b + "," + (0.3 + intensity * 0.6).toFixed(2) + ")";
                    ctx.lineWidth = 2.5;
                    ctx.lineJoin = "round";
                    ctx.stroke();
                  }
                }


                // Album Art Circular view
                Rectangle {
                  width: 136
                  height: 136
                  radius: 68
                  clip: true
                  anchors.centerIn: parent
                  color: colors_ ? colors_.surfaceContainerHighest : "#3C3A43"

                  Image {
                    source: root.mprisArtUrl ? root.mprisArtUrl : ""
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                  }

                  // Default Music Note icon if no art
                  Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    visible: root.mprisArtUrl === ""

                    Text {
                      anchors.centerIn: parent
                      text: "music_note"
                      font.family: config ? config.iconFont : "Material Symbols Outlined"
                      font.pixelSize: 48
                      color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    }
                  }
                }
              }

              // Text Details
              ColumnLayout {
                spacing: 4
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter

                Text {
                  text: root.mprisTitle ? root.mprisTitle : "No Media Playing"
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 18
                  font.weight: Font.Bold
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
                  color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 13
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  horizontalAlignment: Text.AlignHCenter
                }
              }

              // Wavy Progress Bar Slider
              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                  text: root.formatTime(root.elapsedSeconds)
                  color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 11
                }

                WaveProgressBar {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 16
                  progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
                  activeColor: colors_ ? colors_.primary : "#BEE8C7"
                  trackColor: colors_ ? colors_.surfaceContainerHighest : "#3C3A43"
                  lineWidth: 3
                  dotRadius: 5
                  trackLineWidth: 2
                }

                Text {
                  text: root.mprisLengthStr
                  color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 11
                }
              }

              // Large Controls row
              RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                // Prev
                Rectangle {
                  width: 44
                  height: 44
                  radius: 22
                  color: "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: "skip_previous"
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "prev"])
                    }
                  }
                }

                // Play/Pause
                Rectangle {
                  width: 52
                  height: 52
                  radius: 26
                  color: colors_ ? colors_.primary : "#BEE8C7"

                  Text {
                    anchors.centerIn: parent
                    text: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 26
                    color: colors_ ? colors_.fgPrimary : "#0F3C2C"
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
                    }
                  }
                }

                // Next
                Rectangle {
                  width: 44
                  height: 44
                  radius: 22
                  color: "transparent"

                  Text {
                    anchors.centerIn: parent
                    text: "skip_next"
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  }

                  MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "next"])
                    }
                  }
                }
              }
            }

            // Right Vertical Control Column (Volume, Devices buttons)
            Column {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: 12

              // Volume Button
              Rectangle {
                width: 36
                height: 36
                radius: 18
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: root.systemMuted ? "volume_off" : (root.systemVolume <= 0.01 ? "volume_mute" : (root.systemVolume <= 0.3 ? "volume_mute" : (root.systemVolume <= 0.7 ? "volume_down" : "volume_up")))
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: 18
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onClicked: {
                    Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.systemMuted ? "0" : "1"])
                    Quickshell.execDetached(["touch", "/tmp/qsosd-vol"])
                  }
                  onWheel: function(wheel) {
                    var diff = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                    root.ccSetVolume(root.systemVolume + diff);
                    Quickshell.execDetached(["touch", "/tmp/qsosd-vol"])
                  }
                }
              }

              // Devices Button
              Rectangle {
                width: 36
                height: 36
                radius: 18
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "devices"
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: 18
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onClicked: {
                    Quickshell.execDetached(["pavucontrol"])
                  }
                }
              }

              // Shift Active Player Button (queue_music)
              Rectangle {
                width: 36
                height: 36
                radius: 18
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "queue_music"
                  font.family: config ? config.iconFont : "Material Symbols Outlined"
                  font.pixelSize: 18
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  hoverEnabled: true
                  onClicked: {
                    Quickshell.execDetached(["sh", "-c", "echo shift > /tmp/qsmpris-fifo"])
                  }
                }
              }
            }
          }

          // Tab 2: Wallpapers (Large visual grid taking up the full panel width and height!)
          ColumnLayout {
            anchors.fill: parent
            spacing: 8
            visible: root.currentTab === 2

            Text {
              text: "Visual Wallpaper Selector (" + root.wallpapersList.length + " walls found) • Active: " + (root.currentWallpaper || "None")
              color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
              font.family: config ? config.fontFamily : "Roboto"
              font.pixelSize: 12
              font.weight: Font.Medium
            }

            Rectangle {
              Layout.fillWidth: true
              Layout.fillHeight: true
              radius: 16
              color: colors_ ? colors_.surfaceContainer : "#25232A"
              border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
              border.width: 1
              clip: true

              GridView {
                id: wallpaperGrid
                anchors.fill: parent
                anchors.margins: 16
                cellWidth: 180
                cellHeight: 120
                model: root.wallpapersList
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                delegate: Rectangle {
                  id: wallDelegate
                  width: 160
                  height: 104
                  radius: 10
                  color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                  clip: true
                  
                  readonly property bool isCurrent: modelData === root.currentWallpaper
                  
                  border.width: isCurrent ? 3 : (wallDelegateMouse.containsMouse ? 2 : 1)
                  border.color: isCurrent || wallDelegateMouse.containsMouse ? (colors_ ? colors_.primary : "#BEE8C7") : (colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1))

                  Image {
                    id: wallThumb
                    source: "file://" + Quickshell.env("HOME") + "/.cache/quickshell/wallpaper-thumbs/" + modelData
                    sourceSize.width: 200
                    sourceSize.height: 130
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop

                    onStatusChanged: {
                      if (status === Image.Error && source !== "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData) {
                        source = "file://" + Quickshell.env("HOME") + "/Pictures/Walls/" + modelData;
                      }
                    }
                  }

                  // Selected checkmark badge
                  Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    color: colors_ ? colors_.primary : "#BEE8C7"
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: 6
                    visible: wallDelegate.isCurrent

                    Text {
                      anchors.centerIn: parent
                      text: "check"
                      font.family: config ? config.iconFont : "Material Symbols Outlined"
                      font.pixelSize: 12
                      font.weight: Font.Bold
                      color: colors_ ? colors_.fgPrimary : "#0F3C2C"
                    }
                  }

                  MouseArea {
                    id: wallDelegateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.config/quickshell/scripts/apply-wallpaper.sh", modelData])
                      root.currentWallpaper = modelData
                    }
                  }
                }
              }
            }
          }

          // Tab 3: Weather Forecast Details
          ColumnLayout {
            anchors.fill: parent
            spacing: 12
            visible: root.currentTab === 3

            // Top Row: Current Weather & Hourly Forecast
            RowLayout {
              Layout.fillWidth: true
              Layout.preferredHeight: 115
              spacing: 12

              // Current Weather Summary Card
              Rectangle {
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                RowLayout {
                  anchors.centerIn: parent
                  spacing: 16

                  Text {
                    text: getMaterialIcon(root.weatherDesc)
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 82
                    color: getMaterialColor(root.weatherDesc)
                    Layout.alignment: Qt.AlignVCenter
                  }

                  ColumnLayout {
                    spacing: 1
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter

                    Text {
                      text: root.weatherTemp
                      color: colors_ ? colors_.fgSurface : "#FFFFFF"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 32
                      font.weight: Font.Bold
                    }

                    Text {
                      text: root.weatherDesc
                      color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 15
                      font.weight: Font.Medium
                      elide: Text.ElideRight
                    }

                    Text {
                      text: root.weatherCity || "Location Auto"
                      color: colors_ ? Qt.rgba(colors_.fgSurfaceVariant.r, colors_.fgSurfaceVariant.g, colors_.fgSurfaceVariant.b, 0.5) : "#70CAC4D0"
                      font.family: config ? config.fontFamily : "Roboto"
                      font.pixelSize: 11
                    }
                  }
                }
              }

              // Hourly Forecast Card
              Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                Text {
                  anchors.centerIn: parent
                  text: "Loading hourly forecast..."
                  color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 12
                  visible: !root.weatherHourly || root.weatherHourly.length === 0
                }

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 4
                  visible: root.weatherHourly && root.weatherHourly.length > 0

                  Text {
                    text: "Hourly Forecast"
                    color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                      model: root.weatherHourly

                      delegate: Item {
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80

                        ColumnLayout {
                          anchors.centerIn: parent
                          spacing: 2

                          Text {
                            text: modelData.time
                            color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            Layout.alignment: Qt.AlignHCenter
                          }

                          Text {
                            text: getMaterialIcon(modelData.desc)
                            font.family: "Material Symbols Rounded"
                            font.pixelSize: 36
                            color: getMaterialColor(modelData.desc)
                            Layout.alignment: Qt.AlignHCenter
                          }

                          Text {
                            text: modelData.temp
                            color: colors_ ? colors_.fgSurface : "#FFFFFF"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            Layout.alignment: Qt.AlignHCenter
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            // Weather Details Grid (6 Columns)
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "Current Conditions Details"
                color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Roboto"
                font.pixelSize: 12
                font.weight: Font.Medium
              }

              GridLayout {
                columns: 6
                Layout.fillWidth: true
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                  model: [
                    { icon: "thermostat", label: "Feels Like", value: root.weatherFeelsLike, color: "#FF5252" },
                    { icon: "water_drop", label: "Humidity", value: root.weatherHumidity, color: "#26C6DA" },
                    { icon: "air", label: "Wind", value: root.weatherWind, color: "#00F5D4" },
                    { icon: "compress", label: "Pressure", value: root.weatherPressure, color: "#BA68C8" },
                    { icon: "sunny", label: "UV Index", value: root.weatherUV, color: "#FFA726" },
                    { icon: "umbrella", label: "Precipitation", value: root.weatherPrecipChance, color: "#4FC3F7" }
                  ]

                  delegate: Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
                    radius: 12
                    color: colors_ ? colors_.surfaceContainer : "#25232A"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    RowLayout {
                      anchors.centerIn: parent
                      spacing: 10

                      Text {
                        text: modelData.icon
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 26
                        font.weight: Font.Medium
                        color: modelData.color
                        Layout.alignment: Qt.AlignVCenter
                      }

                      ColumnLayout {
                        spacing: 0
                        Layout.alignment: Qt.AlignVCenter

                        Text {
                          text: modelData.label
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 9
                          font.weight: Font.Medium
                        }

                        Text {
                          text: modelData.value
                          color: colors_ ? colors_.fgSurface : "#FFFFFF"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 12
                          font.weight: Font.Bold
                        }
                      }
                    }
                  }
                }
              }
            }

            // 5-Day Weather Forecast Row
            ColumnLayout {
              Layout.fillWidth: true
              spacing: 6

              Text {
                text: "5-Day Weather Forecast"
                color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                font.family: config ? config.fontFamily : "Roboto"
                font.pixelSize: 12
                font.weight: Font.Medium
              }

              RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Repeater {
                  model: root.weatherForecast

                  delegate: Rectangle {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 115
                    radius: 12
                    color: colors_ ? colors_.surfaceContainer : "#25232A"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    ColumnLayout {
                      anchors.centerIn: parent
                      spacing: 4

                      Text {
                        text: {
                          var dateStr = modelData.date;
                          var d = new Date(dateStr + "T00:00:00");
                          var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                          if (index === 0) return "Today";
                          return days[d.getDay()];
                        }
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: getMaterialIcon(modelData.desc)
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 46
                        color: getMaterialColor(modelData.desc)
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: modelData.max_temp + " / " + modelData.min_temp
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 10
                        Layout.alignment: Qt.AlignHCenter
                      }

                      Text {
                        text: modelData.desc
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 8
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                        Layout.preferredWidth: 65
                        horizontalAlignment: Text.AlignHCenter
                      }
                    }
                  }
                }
              }
            }

            // Spacer to push everything to the top and prevent weird vertical stretching
            Item {
              Layout.fillHeight: true
            }
          }

          // Tab 4: System Settings
          Flickable {
            anchors.fill: parent
            visible: root.currentTab === 4
            clip: true
            interactive: true
            contentHeight: settingsCol.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
              id: settingsCol
              width: parent.width
              spacing: 24
              Layout.alignment: Qt.AlignTop

            // Color Scheme Card
            Rectangle {
              Layout.fillWidth: true
              Layout.preferredHeight: 100
              radius: 16
              color: colors_ ? colors_.surfaceContainer : "#25232A"
              border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
              border.width: 1

              ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 8

                Text {
                  text: "Color Scheme"
                  color: colors_ ? colors_.fgSurface : "#FFFFFF"
                  font.family: config ? config.fontFamily : "Roboto"
                  font.pixelSize: 13
                  font.weight: Font.Bold
                }

                RowLayout {
                  spacing: 8
                  Layout.fillWidth: true

                  Repeater {
                    model: [
                      { id: "matugen", label: "Matugen",
                        swatch: ["#446829", "#795369", "#4c5d8b", "#11131a"] },
                      { id: "claude",  label: "Claude",
                        swatch: ["#BD5D3A", "#8492A3", "#B0BCB6", "#3D3929"] }
                    ]

                    delegate: Rectangle {
                      required property var modelData
                      property bool active: colors_ && colors_.colorScheme === modelData.id
                      Layout.fillWidth: true
                      height: 48
                      radius: 12
                      color: active
                        ? (colors_ ? colors_.primaryContainer : "#2d4f13")
                        : (colors_ ? colors_.surfaceContainerHigh : "#282A31")
                      border.color: active
                        ? (colors_ ? colors_.primary : "#a9d387")
                        : (colors_ ? colors_.outlineVariant : Qt.rgba(255,255,255,0.08))
                      border.width: active ? 2 : 1

                      Behavior on color { ColorAnimation { duration: 150 } }

                      RowLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // colour swatches preview
                        Row {
                          spacing: 3
                          Repeater {
                            model: modelData.swatch
                            Rectangle {
                              width: 14; height: 14; radius: 3
                              color: modelData
                            }
                          }
                        }

                        Text {
                          text: modelData.label
                          color: active
                            ? (colors_ ? colors_.fgPrimaryContainer : "#c5efa1")
                            : (colors_ ? colors_.fgSurface : "#FFFFFF")
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 12
                          font.weight: Font.Medium
                          Layout.fillWidth: true
                        }

                        Text {
                          visible: active
                          text: "check_circle"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#a9d387"
                        }
                      }

                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                          if (colors_) {
                            colors_.colorScheme = modelData.id
                            var mode = colors_.darkMode ? "dark" : "light"
                            Quickshell.execDetached(["sh", "-c",
                              "echo " + modelData.id + " > " + Quickshell.env("HOME") + "/.config/quickshell/colorscheme"
                              + " && $HOME/.local/bin/sync-terminal-theme.sh " + mode + " " + modelData.id])
                          }
                        }
                      }
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 24
              Layout.alignment: Qt.AlignTop

              // Bar Alignment Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 200
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Bar Alignment"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Rectangle {
                    width: 180
                    height: 40
                    radius: 20
                    color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    Row {
                      anchors.fill: parent

                      Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 20
                        color: root.isHorizontal ? (colors_ ? colors_.primary : "#BEE8C7") : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "horizontal_split"
                            font.family: config ? config.iconFont : "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                          Text {
                            text: "Horiz"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: { if (!root.isHorizontal) root.toggleHorizontal() }
                        }
                      }

                      Rectangle {
                        width: parent.width / 2
                        height: parent.height
                        radius: 20
                        color: !root.isHorizontal ? (colors_ ? colors_.primary : "#BEE8C7") : "transparent"

                        Row {
                          anchors.centerIn: parent
                          spacing: 6
                          Text {
                            text: "vertical_split"
                            font.family: config ? config.iconFont : "Material Symbols Outlined"
                            font.pixelSize: 16
                            color: !root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                          Text {
                            text: "Vert"
                            font.family: config ? config.fontFamily : "Roboto"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            color: !root.isHorizontal ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                          }
                        }

                        MouseArea {
                          anchors.fill: parent
                          cursorShape: Qt.PointingHandCursor
                          onClicked: { if (root.isHorizontal) root.toggleHorizontal() }
                        }
                      }
                    }
                  }
                }
              }

              // Light/Dark Mode Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 200
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 8
                  Layout.alignment: Qt.AlignHCenter

                  Text {
                    text: "Light/Dark Mode"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    Layout.alignment: Qt.AlignHCenter
                  }

                  Rectangle {
                    width: 180
                    height: 40
                    radius: 20
                    color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                    border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                    border.width: 1

                    Row {
                      anchors.fill: parent

                      Repeater {
                        model: [
                          { value: 0, icon: "brightness_auto", label: "Auto" },
                          { value: 1, icon: "light_mode", label: "Light" },
                          { value: 2, icon: "dark_mode", label: "Dark" }
                        ]

                        delegate: Rectangle {
                          required property var modelData
                          width: parent.width / 3
                          height: parent.height
                          radius: 20
                          color: (colors_ && colors_.themePreference === modelData.value) ? colors_.primary : "transparent"

                          Column {
                            anchors.centerIn: parent
                            spacing: 1
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.icon
                              font.family: config ? config.iconFont : "Material Symbols Outlined"
                              font.pixelSize: 15
                              color: (colors_ && colors_.themePreference === modelData.value) ? colors_.fgPrimary : colors_.fgSurfaceVariant
                            }
                            Text {
                              anchors.horizontalCenter: parent.horizontalCenter
                              text: modelData.label
                              font.family: config ? config.fontFamily : "Roboto"
                              font.pixelSize: 8
                              font.weight: Font.Bold
                              color: (colors_ && colors_.themePreference === modelData.value) ? colors_.fgPrimary : colors_.fgSurfaceVariant
                            }
                          }

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                              if (colors_) {
                                colors_.themePreference = modelData.value
                                var modes = ["auto", "light", "dark"]
                                Quickshell.execDetached(["/bin/sh", "-c", "$HOME/.local/bin/sync-theme-mode.sh " + modes[modelData.value]])
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }

              // Accent Color Picker Card
              Rectangle {
                Layout.fillWidth: false
                Layout.preferredWidth: 294
                Layout.preferredHeight: 130
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1
                Layout.alignment: Qt.AlignTop

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  RowLayout {
                    spacing: 12
                    Layout.fillWidth: true

                    Rectangle {
                      width: 24
                      height: 24
                      radius: 6
                      color: colors_ ? colors_.primary : "#D0BCFF"
                      Layout.alignment: Qt.AlignVCenter
                      Text {
                        anchors.centerIn: parent
                        text: "palette"
                        color: colors_ ? colors_.fgPrimary : "#0F3C2C"
                        font.family: config ? config.iconFont : "Material Symbols Outlined"
                        font.pixelSize: 16
                      }
                    }

                    ColumnLayout {
                      spacing: 1
                      Layout.fillWidth: true
                      Layout.alignment: Qt.AlignVCenter
                      Text {
                        text: "Accent Color"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 13
                        font.weight: Font.Bold
                      }
                      Text {
                        text: "Choose a color"
                        color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 9
                      }
                    }

                    Rectangle {
                      width: 48
                      height: 28
                      radius: 14
                      color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                      border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                      border.width: 1
                      Layout.alignment: Qt.AlignVCenter
                      Rectangle {
                        width: 20
                        height: 20
                        radius: 5
                        anchors.centerIn: parent
                        color: colors_ ? colors_.primary : "#D0BCFF"
                      }
                      MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { colorDialog.open() }
                      }
                    }
                  }

                  Flow {
                    spacing: 6
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter

                    Repeater {
                      model: [
                        { name: "Blue",    hex: "6750A4" },
                        { name: "Green",   hex: "4F8A4F" },
                        { name: "Yellow",  hex: "E6A23C" },
                        { name: "Red",     hex: "C44545" },
                        { name: "Purple",  hex: "9C4F96" },
                        { name: "Orange",  hex: "D97A3B" }
                      ]

                      ColumnLayout {
                        spacing: 3
                        Layout.alignment: Qt.AlignHCenter

                        Rectangle {
                          width: 40
                          height: 28
                          radius: 6
                          color: "#" + modelData.hex
                          Layout.alignment: Qt.AlignHCenter
                          border.width: 0

                          MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: parent.opacity = 0.8
                            onExited: parent.opacity = 1.0
                            onClicked: { root.applyPresetColor(modelData.hex) }
                          }
                        }

                        Text {
                          text: modelData.name
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 7
                          horizontalAlignment: Text.AlignHCenter
                          Layout.alignment: Qt.AlignHCenter
                        }
                      }
                    }
                  }
                }
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: 16

              // Caffeine Box
              Rectangle {
                Layout.preferredWidth: 80
                Layout.preferredHeight: 120
                radius: 16
                color: root.caffeineOn ? (colors_ ? colors_.primary : "#BEE8C7") : (colors_ ? colors_.surfaceContainer : "#25232A")
                border.color: root.caffeineOn ? "transparent" : (colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1))
                border.width: 1

                Behavior on color {
                  ColorAnimation { duration: config ? config.animationDuration : 150 }
                }

                ColumnLayout {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    text: "coffee"
                    font.family: config ? config.iconFont : "Material Symbols Outlined"
                    font.pixelSize: 32
                    color: root.caffeineOn ? (colors_ ? colors_.fgPrimary : "#0F3C2C") : (colors_ ? colors_.fgSurfaceVariant : "#CAC4D0")
                    Layout.alignment: Qt.AlignHCenter
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (root.caffeineOn) {
                      Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/idle.sh"])
                      root.caffeineOn = false
                    } else {
                      Quickshell.execDetached(["killall", "swayidle"])
                      root.caffeineOn = true
                    }
                  }
                }
              }

              // System Diagnostics Card
              Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                radius: 16
                color: colors_ ? colors_.surfaceContainer : "#25232A"
                border.color: colors_ ? colors_.outlineVariant : Qt.rgba(255, 255, 255, 0.1)
                border.width: 1

                ColumnLayout {
                  anchors.fill: parent
                  anchors.margins: 12
                  spacing: 8

                  Text {
                    text: "System Diagnostics & Resources"
                    color: colors_ ? colors_.fgSurface : "#FFFFFF"
                    font.family: config ? config.fontFamily : "Roboto"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                  }

                  RowLayout {
                    Layout.fillWidth: true
                    spacing: 20

                    // CPU usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "memory"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "CPU Usage"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * (root.statsCpu / 100.0)
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: Math.round(root.statsCpu) + "%"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }

                    // RAM usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "database"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "Memory (RAM)"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * root.statsRamPct
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: root.statsRamStr + " (" + Math.round(root.statsRamPct * 100) + "%)"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }

                    // Disk usage column
                    ColumnLayout {
                      Layout.fillWidth: true
                      spacing: 4

                      RowLayout {
                        spacing: 6
                        Text {
                          text: "storage"
                          font.family: config ? config.iconFont : "Material Symbols Outlined"
                          font.pixelSize: 16
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                        Text {
                          text: "Disk Storage"
                          color: colors_ ? colors_.fgSurfaceVariant : "#CAC4D0"
                          font.family: config ? config.fontFamily : "Roboto"
                          font.pixelSize: 11
                          font.weight: Font.Medium
                        }
                      }

                      Rectangle {
                        Layout.fillWidth: true
                        height: 8
                        radius: 4
                        color: colors_ ? colors_.surfaceContainerHigh : "#312F37"
                        Rectangle {
                          width: parent.width * root.statsDiskPct
                          height: parent.height
                          radius: 4
                          color: colors_ ? colors_.primary : "#BEE8C7"
                        }
                      }

                      Text {
                        text: root.statsDiskStr + " (" + Math.round(root.statsDiskPct * 100) + "%)"
                        color: colors_ ? colors_.fgSurface : "#FFFFFF"
                        font.family: config ? config.fontFamily : "Roboto"
                        font.pixelSize: 11
                        font.weight: Font.Bold
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  ColorDialog {
    id: colorDialog
    title: "Pick Accent Color"
    selectedColor: colors_ ? colors_.primary : "#D0BCFF"

    onAccepted: {
      var hex = selectedColor.toString().slice(1, 7)
      root.applyPresetColor(hex)
    }
  }
}
}
