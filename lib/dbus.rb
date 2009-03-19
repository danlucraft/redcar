
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
      
      service.export(exported_obj)      
    end
    
    dbus_interface DBUS_REDCAR_INTERFACE do
      dbus_method :focus do
        Redcar.win.window.focus Gdk::Event::CURRENT_TIME
      end
      
      dbus_method :open, "in path:s" do |path|
        # TODO: fix this hardcoded reference
        OpenTab.new(path).do
      end
      
      dbus_method :new_tab, "in contents:s" do |contents|
        tab = NewTab.new.do
        tab.buffer.text = contents
      end
    end
    
    # Return instance of dbus control object on success, none on failure
    def self.try_export_service
      Redcar::DBus.export_service
    rescue ::DBus::Connection::NameRequestError
      bus     = ::DBus::SessionBus.instance
      service = bus.service(DBUS_REDCAR_SERVICE)
      object  = service.object(DBUS_REDCAR_PATH)
      object.introspect
      object.default_iface = DBUS_REDCAR_INTERFACE
      ARGV.each do |arg|
        if File.exist?(arg)
          object.open(File.expand_path(arg))
        end
      end
      if $stdin_contents
        object.new_tab($stdin_contents)
      end
      object.focus
      exit(0)
      # there is already a Redcar instance running
    end
  end
end

