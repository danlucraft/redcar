
module Redcar
  class PluginManagerUi
    class OpenCommand < Redcar::Command
      class Controller
        def title
          "Plugins"
        end
      
        def index 
          str = []
          jquery_path = File.expand_path(File.join(File.dirname(__FILE__), %w(.. assets jquery-1.4.min.js)))
          str << "<script type=\"text/javascript\" src=\"file://#{jquery_path}\"></script>"
          blueprint_dir = File.expand_path(File.join(File.dirname(__FILE__), %w(.. assets blueprint)))
          str << "<link rel=\"stylesheet\" href=\"#{blueprint_dir}/screen.css\" type=\"text/css\" media=\"screen, projection\">"
          str << "<link rel=\"stylesheet\" href=\"#{blueprint_dir}/print.css\" type=\"text/css\" media=\"print\">"
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
    reloadPlugin($(this).parent().parent().find(".plugin-name").text());
  });
  alertMatt("yo!");
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
      
      class ReloadFunc < Swt::Browser::BrowserFunction
        def function(*args)
          name = args.first.to_a.first
          plugin = Redcar.plugin_manager.loaded_plugins.detect {|pl| pl.name == name }
          plugin.load
        end
      end
      
      class AlertFunc < Swt::Browser::BrowserFunction
        def function(*args)
          p :alert_matt
          name = args.first.to_a.first
          Application::Dialog.message_box("Hi matt: #{name}")
        end
      end
      
      def execute
        controller = Controller.new
        tab = win.new_tab(HtmlTab)
        tab.title = controller.title
        ReloadFunc.new(tab.controller.browser, "reloadPlugin")
        AlertFunc.new(tab.controller.browser, "alertMatt")
        tab.controller.browser.set_text(controller.index)
        tab.controller.browser.evaluate(foo=<<-JAVASCRIPT)
JAVASCRIPT
        tab.focus
      end
    end

  end
end
