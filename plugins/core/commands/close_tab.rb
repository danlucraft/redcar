
module Redcar
  class CloseTab < Redcar::TabCommand
    key "Ctrl+W"
    icon :CLOSE

    def initialize(tab=nil)
      @tab = tab
    end

    def execute
      dialog = Gtk::Dialog.new("Document has unsaved changes",
	      Redcar.win,
	      Gtk::Dialog::DESTROY_WITH_PARENT,
	      [ Gtk::Stock::OK, Gtk::Dialog::RESPONSE_NONE ])    
      dialog.vbox.add(Gtk::Label.new("Unsaved changes."))
      dialog.signal_connect('response') { dialog.destroy }
      

      dialog.show_all
      
      @tab ||= tab
      @tab.close if @tab
      @tab = nil # want the Tabs to be collected
    end
  end
end
