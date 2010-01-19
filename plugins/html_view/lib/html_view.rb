
require 'html_view/html_tab'

module Redcar
  class HtmlView
  
    class PluginManagerCommand < Redcar::Command
      class Controller < Redcar::Command
        def index 
          str = []
          jquery_path = File.expand_path(File.join(File.dirname(__FILE__), %w(.. assets jquery-1.4.min.js)))
          str << "<script type=\"text/javascript\" src=\"file://#{jquery_path}\"></script>"
          str << "<h1>Plugin Manager</h1>"
          str << "<h3>Loaded Plugins</h3>"
          str << plugin_table(Redcar.plugin_manager.loaded_plugins)
          str << "<h3>Unloaded Plugins</h3>"
          str << plugin_table(Redcar.plugin_manager.unloaded_plugins)
          str << "<h3>Unreadable definitions</h3>"
          str << plugin_table(Redcar.plugin_manager.unreadable_definitions)
          str << "<h3>Plugins with Errors</h3>"
          str << plugin_table(Redcar.plugin_manager.plugins_with_errors)
          str << foo=<<-HTML
<script language="javascript">
  $("a").click(function() {
    alert($(this).parent().parent().find(".plugin-name").text());
  });
  
</script>
HTML
          str.join("\n")
        end
        
        private
        
        def plugin_table(plugins)
          str = "<table>\n"
          plugins.each do |plugin|
            name = plugin.is_a?(Plugin) ? plugin.name : plugin
            str << "<tr>"
            str << "<td><span class=\"plugin-name\">" + plugin.name + "</span></td>"
            str << "<td><a href=\"#\">Reload</a>" + "</td>"
            str << "</tr>"
          end
          str << "</table>"
        end
      end
      
      class MyFirstJavaFunc < Swt::Browser::BrowserFunction
        def function(*args)
          p [MyFirstJavaFunc, args.first.to_a]
          "[1010, 341]"
        end
      end
      
      def execute
        tab = win.new_tab(HtmlTab)
        tab.title = "HTML 1"
        MyFirstJavaFunc.new(tab.controller.browser, "myFirstJavaFunc")
        controller = Controller.new
        puts controller.index
        tab.controller.browser.set_text(controller.index)
        tab.controller.browser.evaluate(foo=<<-JAVASCRIPT)
JAVASCRIPT
        tab.focus
      end
    end

    def initialize(html_tab)
      @html_tab = html_tab
    end
    
  end
end