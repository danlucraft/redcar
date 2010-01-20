
require 'erb'

module Redcar
  class PluginManagerUi
    class OpenCommand < Redcar::Command
      class Controller
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
        end
        
        private
        
        def plugin_table(plugins)
          str = "<table>\n"
          highlight = true
          plugins.each do |plugin|
            name = plugin.is_a?(PluginManager::PluginDefinition) ? plugin.name : plugin
            str << "<tr class=\"#{highlight ? "grey" : ""}\">"
            str << "<td class=\"plugin\"><span class=\"plugin-name\">" + name + "</span></td>"
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
