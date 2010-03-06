module Redcar
  class EditView
    module Actions
      class EscapeHandler
        def self.handle(edit_view, modifiers)
          return false if modifiers.any?
          # on osx menu items with "Escape" as their keybinding don't seem to activate correctly
          return false if Redcar.platform != :osx
          AutoCompleter::AutoCompleteCommand.new.run
        end
      end
    end
  end
end