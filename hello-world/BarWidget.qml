import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets

// Bar Widget Component
Rectangle {
  id: root

  property var pluginApi: null

  // Required properties for bar widgets
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  implicitWidth: contentRow.implicitWidth + Style.marginL * 2
  implicitHeight: Style.barHeight

  // Get message from settings or use manifest defaults
  readonly property string message: pluginApi?.pluginSettings?.message || pluginApi?.manifest?.metadata?.defaultSettings?.message || ""
  readonly property color bgColor: pluginApi?.pluginSettings?.backgroundColor || pluginApi?.manifest?.metadata?.defaultSettings?.backgroundColor || "transparent"

  color: bgColor
  radius: Style.radiusM

  RowLayout {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginS

    NIcon {
      icon: "noctalia"
      applyUiScale: false
    }

    NText {
      text: root.message
      color: Color.mOnPrimary
      pointSize: Style.fontSizeS
      font.weight: Font.Medium
    }
  }

  // Mouse area to open panel
  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor

    onEntered: {
      root.color = Qt.lighter(root.bgColor, 1.1);
    }

    onExited: {
      root.color = root.bgColor;
    }

    onClicked: {
      if (pluginApi) {
        Logger.i("HelloWorld", "Opening Hello World panel");
        pluginApi.openPanel(root.screen);
      }
    }
  }
}

