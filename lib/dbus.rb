
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
      
      dbus_method :open, "in path:s, in line:s, in column:s" do |path, line, column|
        # TODO: fix this hardcoded reference
        puts "open(#{path.inspect})"
        tab = OpenTab.new(path).do
        if tab
          line ||= 1
          column ||= 1
          line = line.to_i
          column = column.to_i
          line -= 1
          column -= 1
          tab.goto(line, column) 
        end
      end
      
      dbus_method :new_tab, "in contents:s" do |contents|
        puts "new_tab(#{contents.inspect})"
        tab = NewTab.new.do
        tab.buffer.text = contents
      end
      
      dbus_method :debug, "in contents:s" do |contents|
        puts "debug(#{contents.inspect})"
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
        if arg =~ /^redcar:\/\/open\/\?url=file:\/\/([^&]*)(?:\&line=(\d+))?(?:\&column=(\d+))?/
          object.open(File.expand_path($1), $2, $3)
        end
      end
      ARGV.each do |arg|
        if File.exist?(arg)
          object.open(File.expand_path(arg), "1", "1")
        end
      end
      if $stdin_contents and $stdin_contents.length > 0
        object.new_tab($stdin_contents)
      end
      object.focus
      exit(0)
      # there is already a Redcar instance running
    end
  end
end

