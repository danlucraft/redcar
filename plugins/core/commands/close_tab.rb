
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

    def prompt_then_close(&block)
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
          if @tab.filename
            @tab.save
            close_tab
          else
            Redcar::Dialog.save_as(win) do |filename|
              if filename
                @tab.filename = filename
                @tab.save
                close_tab
              end
            end
          end
        when Gtk::Dialog::RESPONSE_REJECT
          close_tab
        when Gtk::Dialog::RESPONSE_CANCEL
        end
      end
    end

    def close_tab
      @tab ||= tab
      @tab.close if @tab
      @tab = nil # want the Tabs to be garbage collected
    end

    def execute
      @tab ||= tab
      if @tab.is_a?(Redcar::EditTab) and @tab.modified?
        prompt_then_close
      else
        close_tab
      end
    end
  end
end
