module Redcar
  # A type of dialog containing a textbox and a list. Used to create the Find File dialog.
  class FilterListDialog
    include Redcar::Model
    include Redcar::Observable
    
    def initialize
      self.controller = Redcar.gui.controller_for(self).new(self)
    end
    
    def open
      notify_listeners(:open)
    end
  end
end
