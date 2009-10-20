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

    def initialize(tab_folder)
      @contents = Swt::Widgets::Composite.new(tab_folder, Swt::SWT::NONE)
      @contents.layout = Swt::Layout::FillLayout.new
      @mate_text = JavaMateView::MateText.new(@contents)
      @mate_text.set_grammar_by_name "Ruby"
      @mate_text.set_theme_by_name "Twilight"
      @mate_text.set_font "Monaco", 15
      @contents
    end
    
    def widget
      @contents
    end
    
    def document
      EditViewSWT::Document.new(@mate_text.document)
    end
  end
end