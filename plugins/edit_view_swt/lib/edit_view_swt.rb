
require 'edit_view_swt/document'
require 'edit_view_swt/edit_tab'

require 'joni'
require 'jcodings'
require 'jdom'

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    include Redcar::Observable
    
    def self.load
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      load_textmate_assets
    end
    
    def self.load_textmate_assets
      JavaMateView::Bundle.load_bundles(Redcar::ROOT + "/textmate/")
      JavaMateView::ThemeManager.load_themes(Redcar::ROOT + "/textmate/")
    end
    
    attr_reader :mate_text, :widget

    def initialize(model, edit_tab)
      @model = model
      @edit_tab = edit_tab
      @handlers = []
      create_mate_text
      create_grammar_selector
      create_document
      attach_listeners
      @mate_text.add_grammar_listener do |new_grammar|
        @model.set_grammar(new_grammar)
      end
      @mate_text.set_grammar_by_name "Plain Text"
      @mate_text.set_theme_by_name(ARGV.option("theme") || "Twilight")
      create_undo_manager
      @document.attach_modification_listeners # comes after undo manager
    end
    
    def create_mate_text
      parent = @edit_tab.notebook.tab_folder
      @widget = Swt::Widgets::Composite.new(parent, Swt::SWT::NONE)
      layout = Swt::Layout::GridLayout.new
      layout.numColumns = 2
      @widget.layout = layout
      @mate_text = JavaMateView::MateText.new(@widget)
      if Core.platform == :osx
        default_font = "Monaco"
        default_font_size = 15
      elsif Core.platform == :linux
        default_font = "Monospace"
        default_font_size = 11
      elsif Core.platform == :windows
        default_font = "FixedSys"
        default_font_size = 15
      end
      @mate_text.set_font(ARGV.option("font") || default_font, 
                          (ARGV.option("font-size") || default_font_size).to_i)
      @edit_tab.item.control = @widget
      
      @mate_text.layoutData = Swt::Layout::GridData.construct do |data|
        data.horizontalAlignment = Swt::Layout::GridData::FILL
        data.verticalAlignment = Swt::Layout::GridData::FILL
        data.grabExcessHorizontalSpace = true
        data.grabExcessVerticalSpace = true
        data.horizontalSpan = 2  
      end
      
      @model.controller = self
    end
    
    def create_undo_manager
      @undo_manager = JFace::Text::TextViewerUndoManager.new(100)
      @undo_manager.connect(@mate_text.viewer)
    end
    
    def undo
      @undo_manager.undo
      EditView.undo_sensitivity.recompute
      EditView.redo_sensitivity.recompute
    end
    
    def undoable?
      @undo_manager.undoable
    end
    
    def redo
      @undo_manager.redo
      EditView.undo_sensitivity.recompute
      EditView.redo_sensitivity.recompute
    end
    
    def redoable?
      @undo_manager.redoable
    end
    
    def reset_undo
      @undo_manager.reset
    end
    
    def create_grammar_selector
      @combo = Swt::Widgets::Combo.new @widget, Swt::SWT::READ_ONLY
      bundles  = JavaMateView::Bundle.bundles.to_a
      grammars = bundles.map {|b| b.grammars.to_a}.flatten
      items    = grammars.map {|g| g.name}.sort_by {|name| name.downcase }
      @combo.items = items.to_java(:string)
      
      @mate_text.add_grammar_listener do |new_grammar|
        @combo.select(items.index(new_grammar))
      end
      
      @combo.add_selection_listener do |event|
        @mate_text.set_grammar_by_name(@combo.text)
      end
      
      @widget.pack
    end
    
    def create_document
      @document = EditViewSWT::Document.new(@model.document, @mate_text.mate_document)
      @model.document.controller = @document
      h1 = @model.document.add_listener(:before => :new_mirror, 
            &method(:update_grammar))
      h2 = @model.add_listener(:grammar_changed, &method(:model_grammar_changed))
      @mate_text.getTextWidget.addFocusListener(FocusListener.new(self))
      @mate_text.getTextWidget.addVerifyListener(VerifyListener.new(@model.document, self))
      @mate_text.getTextWidget.addModifyListener(ModifyListener.new(@model.document, self))
      @handlers << [@model.document, h1] << [@model, h2]
    end
    
    def swt_focus_gained
      @model.gained_focus
    end
    
    def focus
      @mate_text.set_focus
    end
    
    def has_focus?
      focus_control = ApplicationSWT.display.get_focus_control
      focus_control.parent.parent == @mate_text
    end
    
    def attach_listeners
      # h = @document.add_listener(:set_text, &method(:reparse))
      # @handlers << [@document, h]
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
    
    def model_grammar_changed(name)
      @mate_text.set_grammar_by_name(name)
    end
    
    def update_grammar(new_mirror)
      title = new_mirror.title
      return if @mate_text.set_grammar_by_filename(title)
      contents = new_mirror.read
      first_line = contents.to_s.split("\n").first
      @mate_text.set_grammar_by_first_line(first_line) if first_line
    end
    
    def dispose
      @combo.dispose
      @widget.dispose
      @handlers.each {|obj, h| obj.remove_listener(h) }
      @handlers.clear
    end
    
    class FocusListener
      def initialize(obj)
        @obj = obj
      end

      def focusGained(e)
        @obj.swt_focus_gained
      end

      def focusLost(_); end
    end
    
    class VerifyListener
      def initialize(document, obj)
        @document, @obj = document, obj
      end
      
      def verify_text(e)
        @document.verify_text(e.start, e.end, e.text)
      end
    end
    
    class ModifyListener
      def initialize(document, obj)
        @document, @obj = document, obj
      end
      
      def modify_text(e)
        @document.modify_text
      end
    end
  end
end
