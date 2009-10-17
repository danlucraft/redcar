require 'edit_view_swt/tab'

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    
    def self.load
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      
      JavaMateView::Bundle.load_bundles(Redcar::ROOT + "/../java-mateview/input/")
      JavaMateView::ThemeManager.load_themes(Redcar::ROOT + "/../java-mateview/input/")
    end
  end
end