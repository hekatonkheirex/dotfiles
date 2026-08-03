import QtQuick
import QtQuick.Layouts
import Quickshell
import QtQuick.Effects
import "../"
import "../../config"

          Row {
            property QtObject root: null
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
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                Column {
                  anchors.centerIn: parent
                  spacing: 4

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockHours
                    color: Colors.primary
                    font.family: Config.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Bold
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockMinutes
                    color: Colors.primary
                    font.family: Config.fontFamily
                    font.pixelSize: 64
                    font.weight: Font.Bold
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.clockDate
                    color: Colors.fgSurfaceVariant
                    font.family: Config.fontFamily
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
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
                border.width: 1

                Column {
                  anchors.centerIn: parent
                  spacing: 8

                  Text {
                    text: root.getMaterialIcon(root.weatherDesc)
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: Config.iconFont
                    font.pixelSize: 64
                    color: root.getMaterialColor(root.weatherDesc)
                    verticalAlignment: Text.AlignVCenter
                  }

                  Text {
                    text: root.weatherTemp
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 22
                    font.weight: Font.Bold
                  }

                  Text {
                    text: root.weatherDesc
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: Colors.fgSurfaceVariant
                    font.family: Config.fontFamily
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
                  color: Colors.surfaceContainer
                  border.color: Colors.outlineVariant
                  border.width: 1

                  Row {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                      id: profilePicContainer
                      width: 72
                      height: 72
                      radius: 36
                      color: Colors.surfaceContainerHighest
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
                        font.family: Config.iconFont
                        font.pixelSize: 36
                        color: Colors.fgSurfaceVariant
                        visible: profilePicCC.status !== Image.Ready
                      }
                    }

                    Column {
                      anchors.verticalCenter: parent.verticalCenter
                      spacing: 6

                      Text {
                        text: Quickshell.env("USER") || "User"
                        color: Colors.fgSurface
                        font.family: Config.fontFamily
                        font.pixelSize: 18
                        font.weight: Font.Bold
                      }

                      Row {
                        spacing: 6
                        Text {
                          text: "navigation"
                          font.family: Config.iconFont
                          font.pixelSize: 14
                          color: Colors.primary
                        }
                        Text {
                          text: "on niri"
                          color: Colors.fgSurfaceVariant
                          font.family: Config.fontFamily
                          font.pixelSize: 13
                        }
                      }

                      Row {
                        spacing: 6
                        Text {
                          text: "schedule"
                          font.family: Config.iconFont
                          font.pixelSize: 14
                          color: Colors.fgSurfaceVariant
                        }
                        Text {
                          text: root.uptimeText.replace("up ", "")
                          color: Colors.fgSurfaceVariant
                          font.family: Config.fontFamily
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
                color: Colors.surfaceContainer
                border.color: Colors.outlineVariant
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
                      color: Colors.fgSurface
                      font.family: Config.fontFamily
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
                          color: calNavArea.containsMouse ? Qt.tint("transparent", Colors.hoverOverlay) : "transparent"
                          Behavior on color {
                            ColorAnimation { duration: Config.animationDuration}
                          }
                          Text {
                            anchors.centerIn: parent
                            text: modelData
                            color: Colors.fgSurface
                            font.family: Config.iconFont
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
                        color: Colors.fgSurfaceVariant
                        font.family: Config.fontFamily
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
                        color: root.isToday(dayNum) ? (Colors.primary) : "transparent"

                        Text {
                          anchors.centerIn: parent
                          text: dayNum > 0 ? dayNum.toString() : ""
                          color: root.isToday(dayNum)
                            ? (Colors.fgPrimary)
                            : (Colors.fgSurface)
                          font.family: Config.fontFamily
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
              color: Colors.surfaceContainer
              border.color: Colors.outlineVariant
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
                    running: root.visible && root.mprisStatus === "Playing" && !(Config.reducedMotion)
                    NumberAnimation { to: 1.04; duration: Config.motionLong; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0.96; duration: Config.motionExtraLong; easing.type: Easing.InOutQuad }
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
                    color: Colors.surfaceContainerHighest

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
                        font.family: Config.iconFont
                        font.pixelSize: 32
                        color: Colors.fgSurfaceVariant
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
                    color: Colors.fgSurface
                    font.family: Config.fontFamily
                    font.pixelSize: 13
                    font.weight: Font.Bold
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }

                  Text {
                    width: parent.width
                    text: root.mprisArtist ? root.mprisArtist : "Unknown Artist"
                    color: Colors.fgSurfaceVariant
                    font.family: Config.fontFamily
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                  }
                }

                WaveProgressBar {
                  width: parent.width - 12
                  anchors.horizontalCenter: parent.horizontalCenter
                  progress: root.mprisLengthSec > 0 ? (root.elapsedSeconds / root.mprisLengthSec) : 0.0
                  activeColor: Colors.primary
                  trackColor: Colors.surfaceContainerHighest
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
                      font.family: Config.iconFont
                      font.pixelSize: 18
                      color: Colors.fgSurface
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
                    color: Colors.primary
                    Text {
                      anchors.centerIn: parent
                      text: root.mprisStatus === "Playing" ? "pause" : "play_arrow"
                      font.family: Config.iconFont
                      font.pixelSize: 20
                      color: Colors.fgPrimary
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
                      font.family: Config.iconFont
                      font.pixelSize: 18
                      color: Colors.fgSurface
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
