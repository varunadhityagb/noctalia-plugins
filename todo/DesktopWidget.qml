import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Modules.DesktopWidgets
import qs.Widgets

DraggableDesktopWidget {
  id: root

  property var pluginApi: null

  property bool expanded: false

  property bool showCompleted: pluginApi?.pluginSettings?.showCompleted || pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false

  property ListModel filteredTodosModel: ListModel {}

  implicitWidth: 300
  implicitHeight: {
    var headerHeight = Style.baseWidgetSize + Style.marginL * 2;
    if (!expanded)
      return headerHeight;

    var todosCount = root.filteredTodosModel.count;
    var contentHeight = (todosCount === 0) ? Style.baseWidgetSize : (Style.baseWidgetSize * todosCount + Style.marginS * (todosCount - 1));

    var totalHeight = contentHeight + Style.marginM * 2 + headerHeight;
    return Math.min(totalHeight, headerHeight + 400); // Max 400px of content
  }

  function getCurrentTodos() {
    return pluginApi?.pluginSettings?.todos || [];
  }

  function getCurrentShowCompleted() {
    return pluginApi?.pluginSettings?.showCompleted || pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
  }

  function updateFilteredTodos() {
    if (!pluginApi)
      return;

    filteredTodosModel.clear();

    var pluginTodos = getCurrentTodos();
    var currentShowCompleted = getCurrentShowCompleted();
    var filtered = pluginTodos;

    if (!currentShowCompleted) {
      filtered = pluginTodos.filter(function (todo) {
        return !todo.completed;
      });
    }

    for (var i = 0; i < filtered.length; i++) {
      filteredTodosModel.append({
                                  id: filtered[i].id,
                                  text: filtered[i].text,
                                  completed: filtered[i].completed
                                });
    }
  }

  Timer {
    id: updateTimer
    interval: 200
    running: !!pluginApi
    repeat: true
    onTriggered: {
      updateFilteredTodos();
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      root.showCompleted = getCurrentShowCompleted();
      updateFilteredTodos();
    }
  }

  Component.onCompleted: {
    if (pluginApi) {
      updateFilteredTodos();
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: {
      root.expanded = !root.expanded;
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    RowLayout {
      spacing: Style.marginS
      Layout.fillWidth: true

      NIcon {
        icon: "checklist"
        pointSize: Style.fontSizeL
      }

      NText {
        text: pluginApi?.tr("desktop_widget.header_title")
        font.pointSize: Style.fontSizeL
        font.weight: Font.Medium
      }

      Item {
        Layout.fillWidth: true
      }

      NText {
        text: {
          var todos = pluginApi?.pluginSettings?.todos || [];
          var activeTodos = todos.filter(function (todo) {
            return !todo.completed;
          }).length;

          var text = pluginApi?.tr("desktop_widget.items_count");
          return text.replace("{active}", activeTodos).replace("{total}", todos.length);
        }
        color: Color.mOnSurfaceVariant
        font.pointSize: Style.fontSizeS
      }

      NIcon {
        icon: root.expanded ? "chevron-up" : "chevron-down"
        pointSize: Style.fontSizeM
        color: Color.mOnSurfaceVariant
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: expanded ? (root.implicitHeight - (Style.baseWidgetSize + Style.marginL * 2)) : 0
      visible: expanded

      NBox {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.2)
        radius: Style.radiusM

        ListView {
          id: todoListView
          anchors.fill: parent
          anchors.margins: Style.marginS
          model: root.filteredTodosModel
          spacing: Style.marginS
          boundsBehavior: Flickable.StopAtBounds
          flickableDirection: Flickable.VerticalFlick

          height: Math.min(contentHeight, 400 - 2 * Style.marginS)

          delegate: Rectangle {
            width: ListView.view.width
            height: Style.baseWidgetSize
            color: model.completed ? Color.mSurfaceVariant : Color.mSurface
            radius: Style.radiusS

            RowLayout {
              anchors.fill: parent
              anchors.margins: Style.marginS
              spacing: Style.marginS

              NIcon {
                icon: model.completed ? "square-check" : "square"
                color: model.completed ? Color.mPrimary : Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
              }

              NText {
                text: model.text
                color: model.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                font.strikeout: model.completed
                elide: Text.ElideRight
                Layout.fillWidth: true
              }
            }
          }
        }

        Item {
          anchors.fill: parent
          anchors.margins: Style.marginS
          visible: root.filteredTodosModel.count === 0

          NText {
            anchors.centerIn: parent
            text: pluginApi?.tr("desktop_widget.empty_state")
            color: Color.mOnSurfaceVariant
            font.pointSize: Style.fontSizeM
            font.weight: Font.Normal
          }
        }
      }
    }
  }
}
