import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Rectangle {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property bool pillDirection: BarService.getPillDirection(root)

  readonly property var mainInstance: pluginApi?.mainInstance

  implicitWidth: {
    if (barIsVertical) return Style.capsuleHeight
    if (compactMode) return Style.capsuleHeight
    return contentRow.implicitWidth + Style.marginM * 2
  }
  implicitHeight: Style.capsuleHeight

  readonly property bool barIsVertical: Settings.data.bar.position === "left" || Settings.data.bar.position === "right"
  readonly property bool compactMode: mainInstance?.compactMode ?? false
  readonly property bool showIpAddress: mainInstance?.showIpAddress ?? true
  readonly property bool showPeerCount: mainInstance?.showPeerCount ?? true

  color: Style.capsuleColor

  radius: Style.radiusL

  function getStatusIcon() {
    if (!mainInstance?.tailscaleInstalled) return "network-off"
    if (mainInstance?.tailscaleRunning) return "network"
    return "network-off"
  }

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS
    layoutDirection: Qt.LeftToRight

    NIcon {
      icon: getStatusIcon()
      applyUiScale: false
      color: {
        if (mainInstance?.tailscaleRunning) return Color.mPrimary
        return mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
      }
      opacity: mainInstance?.isRefreshing ? 0.5 : 1.0
    }

    NText {
      visible: !barIsVertical && !compactMode && mainInstance?.tailscaleInstalled && mainInstance?.tailscaleRunning && showIpAddress && mainInstance?.tailscaleIp
      family: Settings.data.ui.fontFixed
      pointSize: Style.barFontSize
      text: mainInstance?.tailscaleIp || ""
      color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    }

    NText {
      visible: !barIsVertical && !compactMode && mainInstance?.tailscaleInstalled && mainInstance?.tailscaleRunning && showPeerCount
      family: Settings.data.ui.fontFixed
      pointSize: Style.barFontSize
      text: "(" + (mainInstance?.peerCount || 0) + ")"
      color: mouseArea.containsMouse ? Color.mOnHover : Color.mOnSurface
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton

    onEntered: {
      root.color = Color.mHover
    }

    onExited: {
      root.color = Style.capsuleColor
    }

    onClicked: (mouse) => {
      if (mouse.button === Qt.LeftButton) {
        if (pluginApi) {
          pluginApi.openPanel(root.screen, root)
        }
      } else if (mouse.button === Qt.RightButton) {
        if (mainInstance?.tailscaleInstalled) {
          mainInstance.toggleTailscale()
        }
      }
    }
  }
}
