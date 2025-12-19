import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
  id: root

  property var pluginApi: null

  readonly property var geometryPlaceholder: panelContainer

  property real contentPreferredWidth: 800 * Style.uiScaleRatio
  property real contentPreferredHeight: 600 * Style.uiScaleRatio

  readonly property bool allowAttach: true

  anchors.fill: parent

  property ListModel todosModel: ListModel {}

  property ListModel filteredTodosModel: ListModel {}

  property bool showCompleted: false

  property var rawTodos: []

  Binding {
    target: root
    property: "rawTodos"
    value: pluginApi?.pluginSettings?.todos || []
  }

  Component.onCompleted: {
    if (pluginApi) {
      Logger.i("Todo", "Panel initialized");
      root.showCompleted = pluginApi?.pluginSettings?.showCompleted || pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
      loadTodos();
    }
  }

  function loadTodos() {
    todosModel.clear();
    filteredTodosModel.clear();

    var pluginTodos = root.rawTodos;

    for (var i = 0; i < pluginTodos.length; i++) {
      todosModel.append({
                          id: pluginTodos[i].id,
                          text: pluginTodos[i].text,
                          completed: pluginTodos[i].completed === true,
                          createdAt: pluginTodos[i].createdAt
                        });
    }

    for (var k = 0; k < pluginTodos.length; k++) {
      if (showCompleted || !pluginTodos[k].completed) {
        filteredTodosModel.append({
                                    id: pluginTodos[k].id,
                                    text: pluginTodos[k].text,
                                    completed: pluginTodos[k].completed === true,
                                    createdAt: pluginTodos[k].createdAt
                                  });
      }
    }
  }

  onPluginApiChanged: {
    if (pluginApi) {
      loadTodos();
    }
  }

  Timer {
    id: settingsWatcher
    interval: 200
    running: !!pluginApi
    repeat: true
    onTriggered: {
      var newShowCompleted = pluginApi?.pluginSettings?.showCompleted || pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false;
      if (root.showCompleted !== newShowCompleted) {
        root.showCompleted = newShowCompleted;
        loadTodos();
      }
    }
  }

  Rectangle {
    id: panelContainer
    anchors.fill: parent
    color: Color.transparent

    ColumnLayout {
      anchors {
        fill: parent
        margins: Style.marginM
      }
      spacing: Style.marginL

      Rectangle {
        Layout.fillWidth: true
        Layout.fillHeight: true
        color: Color.mSurfaceVariant
        radius: Style.radiusL

        ColumnLayout {
          anchors.fill: parent
          anchors.margins: Style.marginM
          spacing: Style.marginM

          RowLayout {
            spacing: Style.marginM

            NIcon {
              icon: "checklist"
              pointSize: Style.fontSizeL
            }

            NText {
              text: pluginApi?.tr("panel.header.title")
              font.pointSize: Style.fontSizeL
              font.weight: Font.Medium
              color: Color.mOnSurface
            }

            Item {
              Layout.fillWidth: true
            }

            NButton {
              text: pluginApi?.tr("panel.header.clear_completed_button")
              onClicked: {
                if (pluginApi) {
                  var todos = pluginApi.pluginSettings.todos || [];

                  var activeTodos = todos.filter(todo => !todo.completed);

                  pluginApi.pluginSettings.todos = activeTodos;

                  pluginApi.pluginSettings.count = activeTodos.length;
                  pluginApi.pluginSettings.completedCount = 0;

                  pluginApi.saveSettings();

                  loadTodos();
                }
              }
            }
          }

          NBox {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
              anchors {
                fill: parent
                margins: Style.marginM
              }
              spacing: Style.marginM

              RowLayout {
                spacing: Style.marginS

                NTextInput {
                  id: newTodoInput
                  placeholderText: pluginApi?.tr("panel.add_todo.placeholder")
                  Layout.fillWidth: true
                  Keys.onReturnPressed: addTodo()
                }

                NButton {
                  text: pluginApi?.tr("panel.add_todo.add_button")
                  onClicked: addTodo()
                }
              }

              ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                  id: todoListView
                  model: root.filteredTodosModel
                  spacing: Style.marginS
                  boundsBehavior: Flickable.StopAtBounds
                  flickableDirection: Flickable.VerticalFlick

                  delegate: Rectangle {
                    width: ListView.view.width
                    height: Style.baseWidgetSize
                    color: Color.mSurface
                    radius: Style.radiusS

                    RowLayout {
                      anchors.left: parent.left
                      anchors.right: parent.right
                      anchors.verticalCenter: parent.verticalCenter
                      anchors.leftMargin: Style.marginM
                      anchors.rightMargin: Style.marginM
                      spacing: Style.marginS

                      NToggle {
                        checked: model.completed
                        onToggled: checked => {
                                     if (pluginApi) {
                                       var todos = pluginApi.pluginSettings.todos || [];

                                       for (var i = 0; i < todos.length; i++) {
                                         if (todos[i].id === model.id) {
                                           todos[i].completed = checked;
                                           break;
                                         }
                                       }

                                       pluginApi.pluginSettings.todos = todos;

                                       var completedCount = 0;
                                       for (var j = 0; j < todos.length; j++) {
                                         if (todos[j].completed) {
                                           completedCount++;
                                         }
                                       }
                                       pluginApi.pluginSettings.completedCount = completedCount;

                                       pluginApi.saveSettings();
                                       loadTodos();
                                     }
                                   }
                      }

                      NText {
                        text: model.text
                        color: model.completed ? Color.mOnSurfaceVariant : Color.mOnSurface
                        font.strikeout: model.completed
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                      }
                      NIconButton {
                        id: deleteButton
                        icon: "circle-x"
                        tooltipText: pluginApi?.tr("panel.todo_item.delete_button_tooltip")
                        color: Color.mError
                        implicitWidth: Style.baseWidgetSize * 0.8
                        implicitHeight: Style.baseWidgetSize * 0.8
                        radius: Style.radiusM
                        opacity: 0.7

                        MouseArea {
                          anchors.fill: parent
                          hoverEnabled: true

                          onEntered: {
                            deleteButton.opacity = 1.0;
                          }

                          onExited: {
                            deleteButton.opacity = 0.7;
                          }
                        }

                        transitions: Transition {
                          PropertyAnimation {
                            properties: "opacity"
                            duration: 150
                          }
                        }

                        onClicked: {
                          var updatedTodos = pluginApi.pluginSettings.todos.filter(function (item) {
                            return item.id !== model.id;
                          });

                          pluginApi.pluginSettings.todos = updatedTodos;
                          pluginApi.pluginSettings.count = updatedTodos.length;

                          var completedCount = 0;
                          for (var i = 0; i < updatedTodos.length; i++) {
                            if (updatedTodos[i].completed) {
                              completedCount++;
                            }
                          }
                          pluginApi.pluginSettings.completedCount = completedCount;

                          pluginApi.saveSettings();
                          loadTodos();
                        }
                      }
                    }
                  }

                  highlightRangeMode: ListView.NoHighlightRange
                  preferredHighlightBegin: 0
                  preferredHighlightEnd: 0

                  header: Item {
                    width: ListView.view.width
                    height: root.todosModel.count === 0 ? contentText.implicitHeight + Style.marginL * 2 : 0

                    NText {
                      id: contentText
                      anchors.centerIn: parent
                      text: root.todosModel.count === 0 ? pluginApi?.tr("panel.empty_state.message") : ""
                      color: Color.mOnSurfaceVariant
                      font.pointSize: Style.fontSizeM
                      font.weight: Font.Normal
                    }
                  }
                }
              }
            }
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: Style.marginM

        NText {
          text: pluginApi?.tr("panel.info.title")
          font.pointSize: Style.fontSizeM * Style.uiScaleRatio
          font.weight: Font.Medium
          color: Color.mOnSurface
        }

        Rectangle {
          Layout.fillWidth: true
          Layout.preferredHeight: infoColumn.implicitHeight + Style.marginM * 2
          color: Color.mSurfaceVariant
          radius: Style.radiusM

          ColumnLayout {
            id: infoColumn
            anchors {
              fill: parent
              margins: Style.marginM
            }
            spacing: Style.marginS

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              NText {
                text: pluginApi?.tr("panel.info.plugin_id_label")
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                Layout.preferredWidth: 100
              }

              NText {
                text: pluginApi?.pluginId || pluginApi?.tr("panel.info.unknown_value")
                font.pointSize: Style.fontSizeS
                font.family: Settings.data.ui.fontFixed
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              NText {
                text: pluginApi?.tr("panel.info.plugin_dir_label")
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurfaceVariant
                Layout.preferredWidth: 100
              }

              NText {
                text: pluginApi?.pluginDir || pluginApi?.tr("panel.info.unknown_value")
                font.pointSize: Style.fontSizeS
                color: Color.mOnSurface
                Layout.fillWidth: true
                elide: Text.ElideMiddle
              }
            }

            RowLayout {
              Layout.fillWidth: true
              spacing: Style.marginM

              NText {
                text: pluginApi?.tr("panel.info.ipc_commands_label")
                font.pointSize: Style.fontSizeS
                font.family: Settings.data.ui.fontFixed
                color: Color.mOnSurfaceVariant
                Layout.preferredWidth: 100
              }

              NText {
                text: pluginApi?.tr("panel.info.ipc_commands_list")
                font.pointSize: Style.fontSizeS
                font.family: Settings.data.ui.fontFixed
                color: Color.mOnSurface
                Layout.fillWidth: true
              }
            }
          }
        }
      }
    }
  }

  function addTodo() {
    if (newTodoInput.text.trim() !== "") {
      if (pluginApi) {
        var todos = pluginApi.pluginSettings.todos || [];

        var newTodo = {
          id: Date.now() // Use timestamp as simple ID
              ,
          text: newTodoInput.text.trim(),
          completed: false,
          createdAt: new Date().toISOString()
        };

        todos.push(newTodo);

        pluginApi.pluginSettings.todos = todos;

        pluginApi.pluginSettings.count = todos.length;

        pluginApi.saveSettings();

        newTodoInput.text = ""; // Clear input
        loadTodos(); // Reload todos to update view
      }
    }
  }
}
