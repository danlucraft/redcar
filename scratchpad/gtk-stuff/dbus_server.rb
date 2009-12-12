
require 'dbus'
require 'gtk2'

bus = DBus.session_bus
service = bus.request_service("org.ruby.service")

class Test < DBus::Object
  # Create an interface.
  dbus_interface "org.ruby.SampleInterface" do
    # Create a hello method in that interface.
    dbus_method :hello, "in name:s, in name2:s" do |name, name2|
      puts "hello(#{name}, #{name2})" 
    end
  end
end

exported_obj = Test.new("/org/ruby/MyInstance")
service.export(exported_obj)

Thread.new do
  main = DBus::Main.new  
  main << bus  
  main.run  
end

Gtk.main
