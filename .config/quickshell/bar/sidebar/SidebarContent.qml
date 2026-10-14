import QtQuick
import Quickshell.Io
import "../../config"
import "../../config/SidebarPages.js" as SidebarPages

// Her sidebar body: Home, Agenda and Media pages over the page indicators.
// Ctrl+PageUp/PageDown step pages (clamped), Esc asks the window to close.
Item {
  id: root
  property bool active: false
  property int currentPage: 0
  readonly property int pageCount: 3
  signal escaped()
  // PopupBase's FocusScope hands focus to this item; the timer re-takes it
  // after the window has keyboard focus on open (the old search field did this).
  focus: true
  Timer { id: focusTimer; interval: 50; onTriggered: root.forceActiveFocus() }
  onActiveChanged: if (root.active) focusTimer.restart(); else focusTimer.stop()

  Keys.onPressed: function(event) {
    if ((event.modifiers & Qt.ControlModifier)
        && (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
      root.currentPage = SidebarPages.stepPage(root.currentPage, event.key === Qt.Key_PageUp ? -1 : 1, root.pageCount)
      event.accepted = true
    } else if (event.key === Qt.Key_Escape) {
      root.escaped(); event.accepted = true
    }
  }

  Item {
    id: pages
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    height: Config.dp(554)

    HomePage { anchors.fill: parent; visible: root.currentPage === 0; active: root.active && root.currentPage === 0 }
    AgendaPage {
      objectName: "agendaPage"
      anchors.fill: parent
      visible: root.currentPage === 1
      active: root.active && root.currentPage === 1
      sidebarOpen: root.active
      weekStartsMonday: Settings.calendarWeekStartsMonday
    }
    MediaPage {
      anchors.fill: parent
      visible: root.currentPage === 2
      status: MediaService.status
      title: MediaService.title
      artist: MediaService.artist
      artUrl: MediaService.artUrl
      positionSec: MediaService.positionSec
      lengthSec: MediaService.lengthSec
      onPlayPause: MediaService.playPause()
      onPrevious: MediaService.previous()
      onNext: MediaService.next()
      onStop: MediaService.stop()
      onSeekBy: function(d) { MediaService.seekBy(d) }
      onSeekFraction: function(f) { MediaService.seekTo(f * MediaService.lengthSec) }
      onVolumeStep: function(d) { AudioService.setVolume(Math.max(0, Math.min(1, AudioService.volume + d / 100))) }
      onPlayerVolumeStep: function(d) { MediaService.playerVolumeBy(d) }
      onFavorite: favoriteProc.running = true
    }
  }

  Binding { target: MediaService; property: "sidebarActive"; value: root.active && root.currentPage === 2 }

  // Appends "artist - title" to her playlist file; an empty title is a no-op.
  Process {
    id: favoriteProc
    command: ["sh", "-c", 'f="$HOME/Music/playlists/songs"; [ -n "$T" ] || exit 0; mkdir -p "$(dirname "$f")" && printf "%s - %s\\n" "$A" "$T" >> "$f"']
    environment: ({ A: MediaService.artist, T: MediaService.title })
  }

  PageIndicators {
    anchors.top: pages.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    currentPage: root.currentPage
    count: root.pageCount
    onPageSelected: function(p) { root.currentPage = p }
    onPageStepped: function(d) { root.currentPage = SidebarPages.stepPage(root.currentPage, d, root.pageCount) }
  }
}
