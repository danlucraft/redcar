require 'erb'

require 'connection_manager/commands'
require 'connection_manager/connection_store'
require 'connection_manager/controller'
require 'connection_manager/filter_dialog'
require 'connection_manager/private_key_store'

module Redcar
  class ConnectionManager
    CONNECTION_SUPER_CLASS ||= Struct.new(:name, :protocol, :host, :port, :user, :path)

    def self.open_connection(c)
      Project::Manager.connect_to_remote(c.protocol, c.host, c.user, c.path, PrivateKeyStore.paths)
    end

    class Connection < CONNECTION_SUPER_CLASS
      def to_hash
        {
          "name" => name,
          "host" => host,
          "port" => port,
          "user" => user,
          "protocol" => protocol,
          "path" => path
        }
      end
    end

    class OpenRemoteFilter < Command
      def execute
        FilterDialog.new.open
      end
    end

    # def self.keymaps
    #   osx = Redcar::Keymap.build("main", :osx) do
    #     link "Cmd+P", OpenRemoteFilter
    #   end
    #   linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
    #     link "Ctrl+P", OpenRemoteFilter
    #   end
    #   [osx, linwin]
    # end

    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Connections", :priority => 36 do
            item "Manage", OpenCommand
            item "Remote Filter", OpenRemoteFilter
          end
        end
      end
    end
  end
end
