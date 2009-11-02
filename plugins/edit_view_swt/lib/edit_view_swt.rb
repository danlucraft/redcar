require 'edit_view_swt/document'
require 'edit_view_swt/tab'

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    def self.load
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      load_textmate_assets
    end
    
    def self.load_textmate_assets
      JavaMateView::Bundle.load_bundles(Redcar::ROOT + "/textmate/")
      JavaMateView::ThemeManager.load_themes(Redcar::ROOT + "/textmate/")
      p JavaMateView::Bundle.bundles.to_a.map {|b| b.name }
      p JavaMateView::ThemeManager.themes.to_a.map {|t| t.name }
    end
    
    attr_reader :mate_text

    def initialize(model, edit_tab)
      @model = model
      @edit_tab = edit_tab
      create_mate_text
      create_document
      attach_listeners
    end
    
    def create_mate_text
      parent = @edit_tab.notebook.tab_folder
      @widget = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
      @widget.layout = Swt::Layout::FillLayout.new
      @mate_text = JavaMateView::MateText.new(@widget)
      @mate_text.set_grammar_by_name "Ruby"
      @mate_text.set_theme_by_name "Twilight"
      @mate_text.set_font "Monaco", 15
      @edit_tab.item.control = @widget
      @model.controller = self
    end
    
    def create_document
      @document = EditViewSWT::Document.new(@model.document, @mate_text.document)
      @model.document.controller = @document
    end
    
    def focus
      @mate_text.set_focus
    end
    
    def has_focus?
      focus_control = ApplicationSWT.display.get_focus_control
      focus_control.parent.parent == @mate_text
    end
    
    def attach_listeners
      @document.add_listener(:set_text, &method(:reparse))
    end
    
    def reparse
      @mate_text.parser.parse_range(0, @mate_text.parser.styledText.get_line_count-1)
    end
  end
end