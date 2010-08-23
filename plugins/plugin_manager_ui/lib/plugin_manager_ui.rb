
require 'erb'

module Redcar
  class PluginManagerUi
    class << self
      attr_accessor :last_reloaded
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins", :priority => 40 do
          group(:priority => :first) {
            item "Plugin Manager", PluginManagerUi::OpenCommand
            item "Reload Again", PluginManagerUi::ReloadLastReloadedCommand
            item("Edit Preferences") { Project::Manager.open_project_for_path(Redcar::Plugin::Storage.storage_dir) }
            separator
          }
        end
      end
    end
    
    class ReloadLastReloadedCommand < Redcar::Command
      
      def execute
        if plugin = PluginManagerUi.last_reloaded
          plugin.load
        end
      end
    end
    
    class OpenCommand < Redcar::Command
      class Controller
        include Redcar::HtmlController
        
        def title
          "Plugins"
        end
      
        def index
          rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
          rhtml.result(binding)
        end
        
        def reload_plugin(name)
          plugin = Redcar.plugin_manager.loaded_plugins.detect {|pl| pl.name == name }
          plugin.load
          Redcar.app.refresh_menu!
          PluginManagerUi.last_reloaded = plugin
          nil
        end
        
        private
        
        def plugin_table(plugins)
          str = "<table>\n"
          highlight = true
          plugins = plugins.sort_by {|pl| pl.name.downcase }
          plugins.each do |plugin|
            name = plugin.is_a?(PluginManager::PluginDefinition) ? plugin.name : plugin
            str << "<tr class=\"#{highlight ? "grey" : ""}\">"
            str << "<td class=\"plugin\"><span class=\"plugin-name\">" + name + "</span></td>"
            if plugin.load_time > 1
              clss = "red"
            elsif plugin.load_time > 0.1
              clss = "yellow"
            else
              clss = ""
            end
            str << "<td class=#{ clss }>#{ plugin.load_time.to_s }</td>"
            str << "<td class=\"links\"><a href=\"#\">Reload</a>" + "</td>"
            str << "</tr>"
            highlight = !highlight
          end
          str << "</table>"
        end
      end
      
      def execute
        controller = Controller.new
        tab = win.new_tab(HtmlTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
  end
end
