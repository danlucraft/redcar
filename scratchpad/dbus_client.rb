
require 'dbus'

bus = DBus.session_bus

ruby_service = bus.service("org.ruby.service")
obj = ruby_service.object("/org/ruby/MyInstance")
obj.introspect
obj.default_iface = "org.ruby.SampleInterface" 
obj.hello("giligiligiligili", "haaaaaaa")
