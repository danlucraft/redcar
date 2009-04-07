
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
        Gtk.queue do
          Redcar.win.window.focus Gdk::Event::CURRENT_TIME
        end
      end
      
      dbus_method :open, "in path:s, in line:s, in column:s" do |path, line, column|
        Gtk.queue do
          # TODO: fix this hardcoded reference
          puts "open(#{path.inspect})"
          tab = OpenTabCommand.new(path).do
          if tab
            line = 1 if line.blank?
            column = 1 if column.blank?
            line = line.to_i
            column = column.to_i
            line -= 1
            column -= 1
            tab.goto(line, column) 
          end
        end
      end
      
      dbus_method :new_tab, "in contents:s" do |contents|
        Gtk.queue do
          puts "new_tab(#{contents.inspect})"
          tab = NewTab.new.do
          tab.buffer.text = contents
        end
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
      any_directories = ARGV.any? {|arg| File.exist?(arg) and File.directory?(arg)}
      object.debug(ARGV.inspect)
      object.debug(any_directories.inspect)
      unless any_directories
        ARGV.each do |arg|
          object.debug(arg)
          if arg =~ /^redcar:\/\/open\/\?url=file:\/\/([^&]*)(?:\&line=(\d+))?(?:\&column=(\d+))?/
            object.open(File.expand_path($1), $2.to_s, $3.to_s)
          end
        end
        ARGV.each do |arg|
          if File.exist?(arg)
            object.open(File.expand_path(arg), "1", "1")
          end
        end
        if $stdin_contents and $stdin_contents.length > 0
          object.new_tab($stdin_contents.to_s)
        end
        object.focus
        exit(0)
      end
    end
  end
end

