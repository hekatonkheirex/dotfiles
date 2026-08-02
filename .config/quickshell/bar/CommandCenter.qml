import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import QtQuick.Dialogs
import Quickshell
import Quickshell.Wayland
import Quickshell.Wayland._WlrLayerShell
import Quickshell.Io
import "commandcenter"

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
          OverviewTab {
            root: root
            colors_: root.colors_
            config: root.config
          }

          MediaTab {
            root: root
            colors_: root.colors_
            config: root.config
          }

          WallpapersTab {
            root: root
            colors_: root.colors_
            config: root.config
          }

          WeatherTab {
            root: root
            colors_: root.colors_
            config: root.config
          }

          SettingsTab {
            root: root
            colors_: root.colors_
            config: root.config
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
