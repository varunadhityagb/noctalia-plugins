import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services.UI

Item {
  id: root
  property var pluginApi: null

  // Ensure Logger exists (fallback to console if not provided)
  function ensureLogger() {
    if (typeof Logger === 'undefined') {
      Logger = {
        d: function(m) { console.log(m); },
        i: function(m) { if (console.info) console.info(m); else console.log(m); },
        w: function(m) { if (console.warn) console.warn(m); else console.log("WARN: " + m); },
        e: function(m) { if (console.error) console.error(m); else console.log("ERROR: " + m); }
      }
    }
  }

  onPluginApiChanged: {
    ensureLogger();
    if (pluginApi) {
      Logger.i("HyprlandCheatsheet: pluginApi loaded, starting generator");
      runGenerator();
    }
  }

  Component.onCompleted: {
    ensureLogger();
    if (pluginApi) {
      Logger.d("HyprlandCheatsheet: Component.onCompleted, starting generator");
      runGenerator();
    }
  }

  function runGenerator() {
    Logger.d("HyprlandCheatsheet: === START GENERATOR ===");
    
    // Get HOME from environment
    var homeDir = process.environment["HOME"];
    if (!homeDir) {
      Logger.e("HyprlandCheatsheet: ERROR - cannot get $HOME");
      saveToDb([{
        "title": pluginApi?.tr("main.error") || "ERROR",
        "binds": [{ "keys": "ERROR", "desc": pluginApi?.tr("main.cannot_get_home") || "Cannot get $HOME" }]
      }]);
      return;
    }
    
    var filePath = homeDir + "/.config/hypr/keybind.conf";
    var cmd = "cat " + filePath;
    
    Logger.d("HyprlandCheatsheet: HOME = " + homeDir);
    Logger.d("HyprlandCheatsheet: Full path = " + filePath);
    Logger.d("HyprlandCheatsheet: Command = " + cmd);
    
    var proc = process.create("bash", ["-c", cmd]);
    
    proc.finished.connect(function() {
      Logger.d("HyprlandCheatsheet: Process finished. ExitCode: " + proc.exitCode);
      Logger.d("HyprlandCheatsheet: Stdout length: " + proc.stdout.length);
      Logger.d("HyprlandCheatsheet: Stderr: " + proc.stderr);
      
      if (proc.exitCode !== 0) {
          Logger.e("HyprlandCheatsheet: ERROR! Code: " + proc.exitCode);
          Logger.e("HyprlandCheatsheet: Full stderr: " + proc.stderr);
          
          saveToDb([{
              "title": pluginApi?.tr("main.read_error") || "READ ERROR",
              "binds": [
                { "keys": pluginApi?.tr("main.exit_code") || "EXIT CODE", "desc": proc.exitCode.toString() },
                { "keys": pluginApi?.tr("main.stderr") || "STDERR", "desc": proc.stderr }
              ]
          }]);
          return;
      }

      var content = proc.stdout;
      Logger.d("HyprlandCheatsheet: Content retrieved. Length: " + content.length);
      
      // Show first 200 chars
      if (content.length > 0) {
          Logger.d("HyprlandCheatsheet: First 200 chars: " + content.substring(0, 200));
          parseAndSave(content);
      } else {
          Logger.w("HyprlandCheatsheet: File is empty!");
          saveToDb([{
              "title": pluginApi?.tr("main.file_empty") || "FILE EMPTY",
              "binds": [{ "keys": "INFO", "desc": pluginApi?.tr("main.file_no_data") || "File contains no data" }]
          }]);
      }
    });
  }

  Process {
    id: process
    function create(cmd, args) {
      Logger.d("HyprlandCheatsheet: Creating process: " + cmd + " " + args.join(" "));
      command = [cmd].concat(args);
      running = true;
      return this;
    }
  }

  function parseAndSave(text) {
    Logger.d("HyprlandCheatsheet: Parsing started");
    var lines = text.split('\n');
    Logger.d("HyprlandCheatsheet: Number of lines: " + lines.length);
    
    var categories = [];
    var currentCategory = null;

    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();

      if (line.startsWith("#") && line.match(/#\s*\d+\./)) {
        if (currentCategory) {
          Logger.d("HyprlandCheatsheet: Saving category: " + currentCategory.title + " with " + currentCategory.binds.length + " binds");
          categories.push(currentCategory);
        }
        var title = line.replace(/#\s*\d+\.\s*/, "").trim();
        Logger.d("HyprlandCheatsheet: New category: " + title);
        currentCategory = { "title": title, "binds": [] };
      } 
      else if (line.includes("bind") && line.includes('#"')) {
        if (currentCategory) {
            var descMatch = line.match(/#"(.*?)"$/);
            var description = descMatch ? descMatch[1] : "Description";
            
            var parts = line.split(',');
            if (parts.length >= 2) {
                var mod = parts[0].split('=')[1].trim().replace("$mod", "SUPER");
                var key = parts[1].trim().toUpperCase();
                if (parts[0].includes("SHIFT")) mod += "+SHIFT";
                if (parts[0].includes("CTRL")) mod += "+CTRL";
                
                currentCategory.binds.push({
                    "keys": mod + " + " + key,
                    "desc": description
                });
                Logger.d("HyprlandCheatsheet: Added bind: " + mod + " + " + key);
            }
        }
      }
    }
    
    if (currentCategory) {
      Logger.d("HyprlandCheatsheet: Saving last category: " + currentCategory.title);
      categories.push(currentCategory);
    }

    Logger.d("HyprlandCheatsheet: Found " + categories.length + " categories.");
    saveToDb(categories);
  }

  function saveToDb(data) {
      if (pluginApi) {
          pluginApi.pluginSettings.cheatsheetData = data;
          pluginApi.saveSettings();
          Logger.i("HyprlandCheatsheet: SAVED TO DB " + data.length + " categories");
      } else {
          Logger.e("HyprlandCheatsheet: ERROR - pluginApi is null!");
      }
  }

  IpcHandler {
    target: "plugin:hyprland-cheatsheet"
    function toggle() {
      Logger.i("HyprlandCheatsheet: IPC toggle called");
      if (pluginApi) {
        runGenerator();
        pluginApi.withCurrentScreen(screen => pluginApi.openPanel(screen));
      }
    }
  }
}
