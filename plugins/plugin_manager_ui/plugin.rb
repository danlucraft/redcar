
Plugin.define do
  name "Plugin Manager UI"
  version "0.3.2"
  
  object "Redcar::PluginManagerUi"
  file "lib", "plugin_manager_ui"
  
  dependencies "core",      ">0",
               "HTML View", ">=0.3.2",
               "application", ">=1.1"
  
end
