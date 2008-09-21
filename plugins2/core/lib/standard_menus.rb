
module Redcar
  class StandardMenus < Redcar::Plugin #:nodoc:all
    include Redcar::MenuBuilder
    extend Redcar::PreferenceBuilder

  end

  class UnifyAll < Redcar::Command
    key "Ctrl+1"
    #      sensitive :multiple_panes

    def execute
      win.unify_all
    end
  end

  class SplitHorizontal < Redcar::Command
    key "Ctrl+2"

    def execute
      if tab
        tab.pane.split_horizontal
      else
        win.panes.first.split_horizontal
      end
    end
  end

  class SplitVertical < Redcar::Command
    key "Ctrl+3"

    def execute
      if tab
        tab.pane.split_vertical
      else
        win.panes.first.split_vertical
      end
    end
  end

end

Coms = Redcar::StandardMenus
