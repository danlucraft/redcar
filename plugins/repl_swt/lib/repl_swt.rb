require 'repl_swt/key_listener'

module Redcar
  class REPLSWT
    def self.start_with_app
      if gui = Redcar.gui
        gui.register_controllers(Redcar::REPL::REPLTab => EditViewSWT::Tab)
      end
    end
  end
end