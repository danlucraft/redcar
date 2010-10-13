module Redcar
  class EditView
    module Actions
      class CmdEnterHandler
        def self.handle(edit_view, modifiers)
          Redcar::Top::MoveNextLineCommand.new.run
        end
      end
    end
  end
end