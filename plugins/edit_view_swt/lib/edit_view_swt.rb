require 'edit_view_swt/document'
require 'edit_view_swt/tab'

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    def self.load
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      
      JavaMateView::Bundle.load_bundles(Redcar::ROOT + "/textmate/")
      JavaMateView::ThemeManager.load_themes(Redcar::ROOT + "/textmate/")
      p JavaMateView::Bundle.bundles.to_a.map {|b| b.name }
      p JavaMateView::ThemeManager.themes.to_a.map {|t| t.name }
    end

    def initialize(tab)
      @tab = tab
      parent = @tab.notebook.tab_folder
      @widget = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
      @widget.layout = Swt::Layout::FillLayout.new
      @mate_text = JavaMateView::MateText.new(@widget)
      @mate_text.set_grammar_by_name "Ruby"
      @mate_text.set_theme_by_name "Twilight"
      @mate_text.set_font "Monaco", 15
      tab.item.control = @widget
    end
    
    def document
      EditViewSWT::Document.new(@mate_text.document)
    end
  end
end