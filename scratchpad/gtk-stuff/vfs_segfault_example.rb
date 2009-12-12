
# This demonstrates the bug in Gtk::FileChooserDialog
# that is caused by GnomeVFS.
# Press the 'choose' button then press Alt+Up many times 
# fast. It doesn't happen every time but most times.

require 'gtk2'
require 'gnomevfs'
GnomeVFS.init

win = Gtk::Window.new
button = Gtk::Button.new("choose")
win.add(button)
button.signal_connect("clicked") do 
  dialog = Gtk::FileChooserDialog.new("Open",
                                      win,
                                      Gtk::FileChooser::ACTION_OPEN,
                                       "gnome-vfs",
                                      [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                      [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
                                      
  # This needs to be quite a long path to cause the failure:
  dialog.current_folder = "/home/dan/projects/textmate/Support/lib"
  filename = nil
  if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
   filename = dialog.filename
  end
  dialog.destroy
  puts filename
end
win.signal_connect("destroy") { Gtk.main_quit }
win.show_all
Gtk.main
