
module Redcar
  module Dialog
    extend FreeBASE::StandardPlugin
    
    def self.open_folder(directory=nil)
      dialog = Gtk::FileChooserDialog.new("Open Folder",
                                          Redcar.win,
                                          Gtk::FileChooser::ACTION_SELECT_FOLDER,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [Gtk::Stock::OPEN, Gtk::Dialog::RESPONSE_ACCEPT])
      if directory
        dialog.current_folder = directory
      end
      
      if dialog.run == Gtk::Dialog::RESPONSE_ACCEPT
        dirname = dialog.filename
      else
        dirname = nil
      end
      dialog.destroy
      dirname
    end
    
    def self.open(win, &block)
      choose_file(win, "Open", Gtk::FileChooser::ACTION_OPEN, Gtk::Stock::OPEN, &block)
    end

    def self.save_as(win, &block)
      choose_file(win, "Save As", Gtk::FileChooser::ACTION_SAVE, Gtk::Stock::SAVE, &block)
    end

    def self.choose_file(win, title, action, button, &block)
      App.log.debug "[Core/Dialog] FileChooserDialog:"
      App.log.debug "[Core/Dialog]  " + Thread.current.inspect
      App.log.debug "[Core/Dialog]  " + win.inspect
      App.log.debug "[Core/Dialog]  " + Redcar::App[:last_dir_opened].to_s
      dialog = Gtk::FileChooserDialog.new(title,
                                          win,
                                          action,
                                          nil,
                                          [Gtk::Stock::CANCEL, Gtk::Dialog::RESPONSE_CANCEL],
                                          [button, Gtk::Dialog::RESPONSE_ACCEPT])
      dialog.modal = false
      
      if Redcar::App[:last_dir_opened]
        dialog.current_folder = Redcar::App[:last_dir_opened]
      end
            
      if win.focussed_tab and dialog.action == Gtk::FileChooser::ACTION_SAVE
        if win.focussed_tab.filename
          dialog.current_folder = win.focussed_tab.filename.split("/")[0..-2].join("/")
        end
      end
      
      App.log.debug "[Core/Dialog]  " + dialog.inspect
      App.log.debug "[Core/Dialog]  " + dialog.destroyed?.to_s
      dialog.run do |response|
        filename = dialog.filename
        dialog.destroy
        case response
        when Gtk::Dialog::RESPONSE_ACCEPT
          Redcar::App[:last_dir_opened] = filename.split("/")[0..-2].join("/")
          block.call(filename)
        end
      end
    end
  end
end

