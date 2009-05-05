
module Redcar
  class CloseTab < Redcar::TabCommand
    key "Ctrl+W"
    icon :CLOSE

    def initialize(tab=nil)
      @tab = tab
    end

    def responses
      result = [[ Gtk::Stock::DISCARD, Gtk::Dialog::RESPONSE_REJECT],
                [ Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL]]
      if tab.filename
        result = [[ Gtk::Stock::SAVE, Gtk::Dialog::RESPONSE_OK]] + result
      else
        result = [[ Gtk::Stock::SAVE_AS, Gtk::Dialog::RESPONSE_OK]] + result
      end
      result
    end

    def prompt_and_save
      dialog = Gtk::Dialog.new("Document has unsaved changes",
                                Redcar.win,
                                nil,
                                *responses
                                )
      dialog.vbox.add(Gtk::Label.new("Unsaved changes."))
      should_close_tab = true
      dialog.run do |response|
        dialog.destroy
        case response
        when Gtk::Dialog::RESPONSE_OK
          if tab.filename
            tab.save
          else
            if filename = Redcar::Dialog.save_as(win)
              tab.filename = filename
              tab.save
            else
              should_close_tab = false
            end
          end
        when Gtk::Dialog::RESPONSE_CANCEL
          should_close_tab = false
        end
      end
      should_close_tab
    end

    def close_tab
      @tab ||= tab
      @tab.close if @tab
      @tab = nil # want the Tabs to be garbage collected
    end

    def execute
      if tab.is_a?(Redcar::EditTab) and tab.modified?
        if prompt_and_save
          close_tab
        end
      else
        close_tab
      end
    end
  end
end
