require 'erb'

require 'connection_manager/commands'
require 'connection_manager/connection_store'
require 'connection_manager/controller'
require 'connection_manager/private_key_store'

module Redcar
  class ConnectionManager
    CONNECTION_SUPER_CLASS ||= Struct.new(:name, :protocol, :host, :port, :user, :path)

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
    
    def self.menus
      Menu::Builder.build do
        sub_menu "Plugins" do
          sub_menu "Connections" do
            item "Manage", OpenCommand
          end
        end
      end
    end
  end
end
