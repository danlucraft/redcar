require 'erb'

module Redcar
  class ConnectionsManager
    # This method is run as Redcar is booting up.
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Connections" do
            item "Manage", OpenCommand
          end
        end
      end
    end

    class OpenCommand < Redcar::Command
      class Controller
        include Redcar::HtmlController

        def title
          "Connections"
        end

        def index
          rhtml = ERB.new(File.read(File.join(File.dirname(__FILE__), "..", "views", "index.html.erb")))
          rhtml.result(binding)
        end
        
        def delete_connection(name)
          conn = find(name)
          
          temp = storage[:connections].clone
          temp.delete(conn)
          
          storage[:connections] = temp
          nil
        end
        
        def get_connection(name)
          find(name)
        end
        
        def update_connection(name, protocol, host, port, user, password, path)
          connection = find(name)
          
          val_errors = []
          %w(name protocol host port user).each do |p|
            value = eval(p)
            val_errors << "Field #{p} cannot be blank" if !value || value.empty?
          end
          
          val_errors << "Name must be alphanumeric" unless name =~ /^[a-zA-Z0-9_]*$/
          
          if val_errors.any?
            return {
              'success' => false,
              'error' => "Please fix the following errors:<ul>#{val_errors.map {|e| "<li>#{e}</li>"}}<ul>"
            }
          end
          
          delete_connection(name)

          password = connection[:password] if password and password.empty?
          
          storage[:connections] = (storage[:connections]||[]) << { 
            :name               => name,
            :protocol           => protocol,
            :host               => host,
            :port               => port,
            :user               => user,
            :password           => password,
            :path               => path
          }        
        end
        
        def add_connection(name, protocol, host, port, user, password, path)
          if (find(name)||[]).any?
            return { 
              'success' => false, 
              'error' => "Connection #{name} already exists. Choose another name and try again." 
            }
          end

          val_errors = []
          %w(name protocol host port user password).each do |p|
            value = eval(p)
            val_errors << "Field #{p} cannot be blank" if !value || value.empty?
          end
          
          val_errors << "Name must be alphanumeric" unless name =~ /^[a-zA-Z0-9_]*$/
          
          if val_errors.any?
            return {
              'success' => false,
              'error' => "Please fix the following errors:<ul>#{val_errors.map {|e| "<li>#{e}</li>"}}<ul>"
            }
          end
          
          storage[:connections] = (storage[:connections]||[]) << { 
            :name               => name,
            :protocol           => protocol,
            :host               => host,
            :port               => port,
            :user               => user,
            :password           => password,
            :path               => path
          }
          
          return { 'success' => true }
        end
        
        def reload_plugin
          plugin = Redcar.plugin_manager.loaded_plugins.detect {|pl| pl.name == 'Connections Manager' }
          plugin.load
          Redcar.app.refresh_menu!
          PluginManagerUi.last_reloaded = plugin
          nil
        end
        
        private
        
        def find(name)
          return [] unless connections
          connections.find { |c| c[:name] == name }
        end
        
        def storage
          Redcar::Plugin::Storage.new('user_connections')
        end
        
        def connections
          return unless storage[:connections]
          storage[:connections].sort_by { |e| e[:name] }
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
