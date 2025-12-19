import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

ColumnLayout {
  id: root

  property var pluginApi: null

  property bool valueShowCompleted: pluginApi?.pluginSettings?.showCompleted || pluginApi?.manifest?.metadata?.defaultSettings?.showCompleted || false

  spacing: Style.marginM

  Component.onCompleted: {
    Logger.i("Todo", "Settings UI loaded");
  }

  NToggle {
    Layout.fillWidth: true
    label: pluginApi?.tr("settings.show_completed.label") || "Show Completed Items"
    description: pluginApi?.tr("settings.show_completed.description") || "Display completed to-do items in the list"
    checked: root.valueShowCompleted
    onToggled: function (checked) {
      root.valueShowCompleted = checked;
    }
  }

  function saveSettings() {
    if (!pluginApi) {
      Logger.e("Todo", "Cannot save settings: pluginApi is null");
      return;
    }

    pluginApi.pluginSettings.showCompleted = root.valueShowCompleted;

    pluginApi.saveSettings();

    Logger.i("Todo", "Settings saved successfully");
  }
}
