
module Redcar
  class ConnectionManager
    class OpenCommand < Redcar::Command

      def execute
        controller = Controller.new
        tab = win.new_tab(ConfigTab)
        tab.html_view.controller = controller
        tab.focus
      end
    end
  end
end
