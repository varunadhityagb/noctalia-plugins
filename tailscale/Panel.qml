import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  readonly property var geometryPlaceholder: panelContainer
  readonly property bool allowAttach: true

  readonly property var mainInstance: pluginApi?.mainInstance

  onPluginApiChanged: {
    if (pluginApi && pluginApi.mainInstance) {
      mainInstanceChanged()
    }
  }

  readonly property bool panelReady: pluginApi !== null && mainInstance !== null && mainInstance !== undefined

  property real contentPreferredWidth: panelReady ? 400 * Style.uiScaleRatio : 0
  property real contentPreferredHeight: panelReady ? Math.min(500, 100 + (mainInstance?.peerList?.length || 0) * 60) * Style.uiScaleRatio : 0

  anchors.fill: parent

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: "transparent"
    visible: panelReady

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginM
      }
      spacing: Style.marginL

      NBox {
        Layout.fillWidth: true
        Layout.fillHeight: true

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM
          clip: true

          RowLayout {
            Layout.fillWidth: true
            spacing: Style.marginS

            NIcon {
              icon: "network"
              pointSize: Style.fontSizeL
              color: Color.mPrimary
            }

            NText {
              text: pluginApi?.tr("panel.title") || "Tailscale Network"
              pointSize: Style.fontSizeL
              font.weight: Style.fontWeightBold
              color: Color.mOnSurface
              Layout.fillWidth: true
            }

            NText {
              text: (mainInstance?.peerList?.length || 0) + " " + (pluginApi?.tr("panel.peers") || "peers")
              pointSize: Style.fontSizeS
              color: Color.mOnSurfaceVariant
            }
          }

          NText {
            Layout.fillWidth: true
            text: mainInstance?.tailscaleIp || ""
            visible: mainInstance?.tailscaleRunning && mainInstance?.tailscaleIp
            pointSize: Style.fontSizeS
            color: Color.mOnSurfaceVariant
            font.family: Settings.data.ui.fontFixed
          }

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.alpha(Color.mOnSurface, 0.1)
            visible: mainInstance?.tailscaleRunning && mainInstance?.peerList && mainInstance.peerList.length > 0
          }

          Flickable {
            id: peerFlickable
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: width
            contentHeight: peerListColumn.height

            ColumnLayout {
              id: peerListColumn
              width: peerFlickable.width
              spacing: Style.marginS

              Repeater {
                model: mainInstance?.peerList || []

                delegate: Rectangle {
                  width: peerFlickable.width
                  height: 40
                  color: mouseArea.containsMouse ? Qt.alpha(Color.mPrimary, 0.1) : "transparent"
                  radius: Style.radiusM

                  RowLayout {
                    id: peerRow
                    anchors {
                      left: parent.left
                      right: parent.right
                      verticalCenter: parent.verticalCenter
                      leftMargin: Style.marginM
                      rightMargin: Style.marginM
                    }
                    spacing: Style.marginM

                    NIcon {
                      icon: modelData.Online ? "circle-check" : "circle-x"
                      pointSize: Style.fontSizeM
                      color: modelData.Online ? Color.mPrimary : Color.mOnSurfaceVariant
                    }

                    NText {
                      text: modelData.HostName || modelData.DNSName || "Unknown"
                      color: Color.mOnSurface
                      font.weight: Style.fontWeightMedium
                      elide: Text.ElideRight
                      Layout.fillWidth: true
                    }

                    NText {
                      text: {
                        var ips = []
                        if (modelData.TailscaleIPs && modelData.TailscaleIPs.length > 0) {
                          ips = modelData.TailscaleIPs.filter(ip => ip.startsWith("100."))
                        }
                        return ips.length > 0 ? ips[0] : ""
                      }
                      pointSize: Style.fontSizeS
                      color: Color.mOnSurfaceVariant
                      font.family: Settings.data.ui.fontFixed
                      visible: modelData.TailscaleIPs && modelData.TailscaleIPs.length > 0
                    }
                  }

                  MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                  }
                }
              }

              NText {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
                Layout.topMargin: Style.marginL
                text: pluginApi?.tr("panel.no-peers") || "No connected peers"
                visible: !mainInstance?.tailscaleRunning || !mainInstance?.peerList || mainInstance.peerList.length === 0
                pointSize: Style.fontSizeM
                color: Color.mOnSurfaceVariant
                horizontalAlignment: Text.AlignHCenter
              }
            }
          }
        }
      }
    }
  }
}
