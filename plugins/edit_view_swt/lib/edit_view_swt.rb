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
    
    attr_reader :mate_text, :widget

    def initialize(model, edit_tab)
      @model = model
      @edit_tab = edit_tab
      create_mate_text
      create_grammar_selector
      create_document
      attach_listeners
    end
    
    def create_mate_text
      parent = @edit_tab.notebook.tab_folder
      @widget = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
      layout = Swt::Layout::GridLayout.new
      layout.numColumns = 2
      @widget.layout = layout
      @mate_text = JavaMateView::MateText.new(@widget)
      @mate_text.set_grammar_by_name "Plain Text"
      @mate_text.set_theme_by_name "Twilight"
      if Core.platform == :osx
        @mate_text.set_font "Menlo", 15
      elsif Core.platform == :linux
        @mate_text.set_font "Monospace", 14
      end
      @edit_tab.item.control = @widget
      
      @mate_text.layoutData = Swt::Layout::GridData.construct do |data|
        data.horizontalAlignment = Swt::Layout::GridData::FILL
        data.verticalAlignment = Swt::Layout::GridData::FILL
        data.grabExcessHorizontalSpace = true
        data.grabExcessVerticalSpace = true
        data.horizontalSpan = 2  
      end
      
      update_caret
      
      @model.controller = self
    end
    
    def create_grammar_selector
      @combo = Swt::Widgets::Combo.new @widget, Swt::SWT::READ_ONLY
      bundles  = JavaMateView::Bundle.bundles.to_a
      grammars = bundles.map{|b| b.grammars.to_a}.flatten
      items    = grammars.map{|g| g.name}
      @combo.items = items.to_java(:string)
      #@combo.select(@combo.index_of ) => Name of current Grammer
        
      @combo.add_selection_listener do |event|
        puts "selected #{@combo.text}"
        @mate_text.set_grammar_by_name(@combo.text)
      end
      
      @widget.pack
    end
    
    def create_document
      @document = EditViewSWT::Document.new(@model.document, @mate_text.mate_document)
      @model.document.controller = @document
      @model.document.add_listener(:new_mirror, &method(:update_grammar))
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
    
    def cursor_offset=(offset)
      @mate_text.get_text_widget.set_caret_offset(offset)
    end
    
    def cursor_offset
      @mate_text.get_text_widget.get_caret_offset
    end
    
    def scroll_to_line(line_index)
      @mate_text.get_text_widget.set_top_index(line_index)
    end
    
    def update_grammar(*)
      @mate_text.set_grammar_by_filename(@model.document.title)
      first_line = @model.document.to_s.split("\n").first
      @mate_text.set_grammar_by_first_line(first_line) if first_line
    end
    
    def update_caret
      caret = @mate_text.getTextWidget.getCaret
      bounds = caret.getBounds
      width, height = bounds.width*2, bounds.height
      caret = Swt::Widgets::Caret.new(@mate_text.getTextWidget, Swt::SWT::NONE)
      display = ApplicationSWT.display
      white = display.getSystemColor(Swt::SWT::COLOR_WHITE)
      black = display.getSystemColor(Swt::SWT::COLOR_BLACK)
      
      image = Swt::Graphics::Image.new(display, width, height)
      gc = Swt::Graphics::GC.new(image)
      gc.setBackground(white)
      gc.fillRectangle(0, 0, width, height)
      gc.setForeground(white)
      gc.drawLine(0, 0, width, height)
      gc.dispose()
      caret.setLocation(10, 10)
      caret.setImage(image)
      @mate_text.getTextWidget.setCaret(caret)
    end
  end
end
