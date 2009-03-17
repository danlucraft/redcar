
require 'dbus'

DBUS_REDCAR_SERVICE   = "com.redcaride.app"
DBUS_REDCAR_PATH      = "/com/redcaride/app"
DBUS_REDCAR_INTERFACE = "com.redcaride.iface"

module Redcar
  class DBus < ::DBus::Object
    def self.export_service
      @bus          = ::DBus::SessionBus.instance
      service      = @bus.request_service(DBUS_REDCAR_SERVICE)
      exported_obj = new(DBUS_REDCAR_PATH)
      
      puts "Exporting DBus object"
      service.export(exported_obj)      
    end
    
    dbus_interface DBUS_REDCAR_INTERFACE do
      dbus_method :open, "in path:s" do |path|
        puts "open(#{path.inspect})" 
      end
    end
    
    # Return instance of dbus control object on success, none on failure
    def self.try_export_service
      Redcar::DBus.export_service
    rescue ::DBus::Connection::NameRequestError
      puts "Redcar is already running, trying to send message"
      bus     = ::DBus::SessionBus.instance
      service = bus.service(DBUS_REDCAR_SERVICE)
      object  = service.object(DBUS_REDCAR_PATH)
      object.introspect
      object.default_iface = DBUS_REDCAR_INTERFACE
      object.open("helloworld")
      exit(0)
      # there is already a Redcar instance running
    end
  end
end

