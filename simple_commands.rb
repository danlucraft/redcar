

# class Document
#   register_record { doc }
  
#   def find_next(re)
#     record :find_next, re
#   end
# end

class FindNext < Redcar::TabCommand
  key "Ctrl+G"
  menu "Edit/Find Next"
  def initialize(re)
    @re = re
  end
  
  def execute(tab)
    
  end
end



# command "Core/Edit/FindNext" do
#   block do
#     tab.doc.find
#   end
# end

require 'gtk2'
class MyWin < Gtk::Window
  def initialize
    super("foo")
    tv = Gtk::TextView.new
    add(tv)
    signal_connect('key-release-event') do |gtk_widget, gdk_eventkey|
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      puts "win: #{key}"
      false
    end
    tv.signal_connect('key-press-event') do |gtk_widget, gdk_eventkey|
      kv = gdk_eventkey.keyval
      ks = gdk_eventkey.state - Gdk::Window::MOD2_MASK
      ks = ks - Gdk::Window::MOD4_MASK
      key = Gtk::Accelerator.get_label(kv, ks)
      puts "tv: #{key}"
      true
    end
  end
end
win = MyWin.new
win.show
Gtk.main
