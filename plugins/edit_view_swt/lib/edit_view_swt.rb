require 'edit_view_swt/tab'

Dir[Redcar::ROOT + "/../java-mateview/lib/*.jar"].each do |fn|
  require fn
end

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module JavaMateView
  import com.redcareditor.mate.MateText
  import com.redcareditor.mate.Grammar
  import com.redcareditor.mate.Bundle
  import com.redcareditor.theme.Theme
  import com.redcareditor.theme.ThemeManager
end

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