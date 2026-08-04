import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"
import "../primitives"
import "../../config"

          Item {
            property QtObject root: null
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

                    var primary = Colors.primary;
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
                  color: Colors.surfaceContainerHighest

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
                      font.family: Config.iconFont
                      font.pixelSize: 48
                      color: Colors.fgSurfaceVariant
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
                  color: Colors.fgSurface
                  font.family: Config.fontFamily
                  font.pixelSize: 18
                  font.weight: Font.Bold
                  elide: Text.ElideRight
                  Layout.fillWidth: true
                  horizontalAlignment: Text.AlignHCenter
                }

                Text {
                  text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
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
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: 11
                }

                WaveProgressBar {
                  Layout.fillWidth: true
                  Layout.preferredHeight: 16
                  progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
                  activeColor: Colors.primary
                  trackColor: Colors.surfaceContainerHighest
                  lineWidth: 3
                  dotRadius: 5
                  trackLineWidth: 2
                }

                Text {
                  text: root.mprisLengthStr
                  color: Colors.fgSurfaceVariant
                  font.family: Config.fontFamily
                  font.pixelSize: 11
                }
              }

              // Large Controls row
              RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 20

                IconButton {
                  size: 44
                  iconSize: 24
                  iconLabel: "skip_previous"
                  accessibleName: "Previous track"
                  tooltipText: "Previous track"
                  onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "prev"])
                }

                IconButton {
                  size: 52
                  iconSize: 26
                  iconLabel: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
                  iconColor: Colors.fgPrimary
                  backgroundColor: Colors.primary
                  accessibleName: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
                  tooltipText: root.mprisStatus === "Playing" ? "Pause playback" : "Play playback"
                  onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "play"])
                }

                IconButton {
                  size: 44
                  iconSize: 24
                  iconLabel: "skip_next"
                  accessibleName: "Next track"
                  tooltipText: "Next track"
                  onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.config/quickshell/scripts/mpris_control.py", "next"])
                }
              }
            }

            // Right Vertical Control Column (Volume, Devices buttons)
            Column {
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: 12

              IconButton {
                size: 36
                iconSize: 18
                iconLabel: root.systemMuted ? "volume_off" : (root.systemVolume <= 0.3 ? "volume_mute" : (root.systemVolume <= 0.7 ? "volume_down" : "volume_up"))
                backgroundColor: Colors.surfaceContainer
                outlined: true
                accessibleName: root.systemMuted ? "Unmute output" : "Mute output"
                accessibleDescription: "Scroll to adjust output volume"
                tooltipText: root.systemMuted ? "Unmute output" : "Mute output"
                onClicked: {
                  Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.systemMuted ? "0" : "1"])
                  Quickshell.execDetached(["touch", "/tmp/qsosd-vol"])
                }
                onWheel: function(wheel) {
                  var diff = wheel.angleDelta.y > 0 ? 0.02 : -0.02
                  root.ccSetVolume(root.systemVolume + diff)
                  Quickshell.execDetached(["touch", "/tmp/qsosd-vol"])
                }
              }

              IconButton {
                size: 36
                iconSize: 18
                iconLabel: "devices"
                backgroundColor: Colors.surfaceContainer
                outlined: true
                accessibleName: "Open audio devices"
                tooltipText: "Open audio devices"
                onClicked: Quickshell.execDetached(["pavucontrol"])
              }

              IconButton {
                size: 36
                iconSize: 18
                iconLabel: "queue_music"
                backgroundColor: Colors.surfaceContainer
                outlined: true
                accessibleName: "Switch active player"
                tooltipText: "Switch active player"
                onClicked: Quickshell.execDetached(["sh", "-c", "echo shift > /tmp/qsmpris-fifo"])
              }
            }
          }
