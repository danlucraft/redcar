require 'edit_view_swt/tab'

module Redcar
  class EditViewSWT
    
    def self.load
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
    end
  end
end