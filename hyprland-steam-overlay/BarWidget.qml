import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  implicitWidth: barIsVertical ? Style.capsuleHeight : contentRow.implicitWidth + Style.marginM * 2
  implicitHeight: Style.capsuleHeight

  property bool steamRunning: false

  readonly property string barPosition: Settings.data.bar.position || "top"
  readonly property bool barIsVertical: barPosition === "left" || barPosition === "right"

  color: Style.capsuleColor
  radius: Style.radiusL

  // Process to check Steam status
  Process {
    id: checkSteamProcess
    command: ["pidof", "steam"]
    running: false

    onExited: (exitCode, exitStatus) => {
      steamRunning = (exitCode === 0);
    }
  }

  // IPC Process to toggle overlay
  Process {
    id: ipcProcess
    command: ["qs", "-p", Quickshell.shellDir, "ipc", "call", "plugin:hyprland-steam-overlay", "toggle"]
    running: false
  }

  // Update steam status periodically
  Timer {
    interval: 5000
    repeat: true
    running: true
    onTriggered: {
      checkSteamProcess.running = true;
    }
  }

  Component.onCompleted: {
    checkSteamProcess.running = true;
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS

    NIcon {
      icon: "brand-steam"
      pointSize: Style.fontSizeL
      color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      root.color = Color.mHover;
    }

    onExited: {
      root.color = Style.capsuleColor;
    }

    onClicked: {
      if (pluginApi) {
        Logger.i("SteamOverlay.BarWidget: Calling Steam overlay toggle");
        ipcProcess.running = true;
      }
    }
  }
}
