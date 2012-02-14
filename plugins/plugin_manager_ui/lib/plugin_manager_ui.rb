
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
            item "Reload Last Reloaded", PluginManagerUi::ReloadLastReloadedCommand
            separator
          }
        end
        if [:linux,:windows].include?(Redcar.platform)
          sub_menu "Edit" do
            group(:priority => :last) do
              separator
              item "Preferences", PluginManagerUi::OpenPreferencesCommand
            end
          end
        end
      end
    end

    def self.keymaps
      if [:linux,:windows].include?(Redcar.platform)
        map = Redcar::Keymap.build("main", [:linux,:windows]) do
          link "F2", PluginManagerUi::OpenPreferencesCommand
        end
        [map]
      end
    end

    class OpenPreferencesCommand < Redcar::Command
      def execute
        project = Project::Manager.open_project_for_path(Redcar::Plugin::Storage.storage_dir)
        project.window.title = "Plugin Preferences"
      end
    end

    class ReloadLastReloadedCommand < Redcar::Command
      
      def execute
        if plugin = PluginManagerUi.last_reloaded
          plugin.load
        end
      end
    end

    class ReloadPluginsCommand < Redcar::Command
      def execute
        Redcar.add_plugin_sources(Redcar.plugin_manager)
        Redcar.plugin_manager.load_maximal
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
          plugin = Redcar.plugin_manager.latest_version_by_name name
          plugin.load
          Redcar.plugin_manager.loaded_plugins << plugin unless
            Redcar.plugin_manager.loaded_plugins.include? plugin
          Redcar.app.refresh_menu!
          PluginManagerUi.last_reloaded = plugin
          nil
        end

        def enable_plugin(name)
          disabled_plugins = Redcar.plugin_manager.disabled_plugins.collect &:name

          # Make sure none of it's dependencies are disabled.
          plugin = Redcar.plugin_manager.latest_version_by_name name
          deps = plugin.dependencies.collect(&:required_name) & disabled_plugins

          if deps.empty?
            reload_plugin name
            Redcar.plugin_manager.disabled_plugins = disabled_plugins - [name]
            save_disabled_plugins
            {:message => "#{name} plugin enabled", :label => 'Disable'}
          else
            {:message => "#{name} requires #{deps * ', '} to be enabled first"}
          end
        end

        def disable_plugin(name)

          # Make sure nobody is active that depends on it
          plugin = Redcar.plugin_manager.latest_version_by_name name
          deps = Redcar.plugin_manager.derivative_plugins_for(plugin) &
            Redcar.plugin_manager.loaded_plugins

          if deps.empty?
            Redcar.plugin_manager.loaded_plugins.reject! {|p| p.name == name}
            Redcar.plugin_manager.disabled_plugins =
              Redcar.plugin_manager.disabled_plugins.collect(&:name) + [name]
            save_disabled_plugins
            {:message => "Plugin #{name} will be disabled on restart", :label => 'Enable'}
          else
            {:message => "Cannot disable #{name} because needed by #{deps.collect(&:name) * ', '}"}
          end
        end
        
        private

        # Will persist the new list of disabled plugins to disk
        def save_disabled_plugins
          path = File.join Redcar.user_dir, 'storage/disabled_plugins.yaml'
          disabled = Redcar.plugin_manager.disabled_plugins.collect &:name
          File.open(path, 'w') {|io| YAML.dump disabled, io}
        end
        
        def plugin_table(plugins)
          str = "<table>\n"
          highlight = true
          plugins = plugins.sort_by {|pl| pl.name.downcase }
          plugins.each do |plugin|
            name = plugin.is_a?(PluginManager::PluginDefinition) ? plugin.name : plugin
            derivatives = Redcar.plugin_manager.derivative_plugins_for(plugin).collect(&:name) * ', '
            str << "<tr class=\"#{highlight ? "grey" : ""}\">"
            str << "<td class=\"plugin\">"
            str << "  <div class=\"plugin-name\">#{name}</div>"
            unless derivatives.empty?
              str << "<div class=\"derivatives\">Needed by: #{derivatives}</div>"
            end
            str << "</td>"
            if Redcar.plugin_manager.loaded_plugins.include? plugin
              if plugin.load_time > 1
                clss = "red"
              elsif plugin.load_time > 0.1
                clss = "yellow"
              else
                clss = ""
              end
              str << "<td class=#{ clss }>#{ plugin.load_time.to_s }</td>"
              str << "<td class=\"links\"><a href=\"#\">Reload</a></td>"
              str << "<td class=\"links\"><a href=\"#\">Disable</a></td>"
            else
              str << "<td class=\"links\"><a href=\"#\">Enable</a></td>"
            end
            str << "</tr>"
            highlight = !highlight
          end
          str << "</table>"
        end
      end
      
      def execute
        controller = Controller.new
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
  end
end
