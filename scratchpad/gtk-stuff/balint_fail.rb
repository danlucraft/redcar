
require 'gtk2'

Gtk.init
w=Gtk::Window.new("click my button").set_width_request(300)
w.add(@l=Gtk::Button.new)
Thread.new{
       i=0
       while true do
               i+=1
               @l.set_label(i.to_s)
               while (Gtk.events_pending?) do Gtk.main_iteration_do(false);end
               #sleep 0.2
       end
}

w.show_all
Gtk.main
