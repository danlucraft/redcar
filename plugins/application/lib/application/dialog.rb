module Redcar
  class Application
    class Dialog
      # Prompt the user with an open file dialog. Returns a path.
      def self.open_file(window, options)
        Redcar.gui.dialog_adapter.open_file(window, options)
      end

      # Prompt the user with an save file dialog. Returns a path.
      def self.save_file(window, options)
        Redcar.gui.dialog_adapter.save_file(window, options)
      end
    end
  end
end