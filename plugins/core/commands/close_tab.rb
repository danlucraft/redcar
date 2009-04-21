
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
        Gtk::Dialog::MODAL,
        [ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_OK],
        [ Gtk::Stock::DISCARD, Gtk::Dialog::RESPONSE_REJECT],
        [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL])
      dialog.vbox.add(Gtk::Label.new("Unsaved changes."))
      dialog_runner = Redcar.win.modal_dialog_runner(dialog)
      
      dialog.signal_connect('response') do 
        dialog_runner.close
      end
      dialog_runner.run
      
      @tab ||= tab
      @tab.close if @tab
      @tab = nil # want the Tabs to be collected
    end
  end
end
