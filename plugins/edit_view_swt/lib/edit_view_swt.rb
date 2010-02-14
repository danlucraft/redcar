
require 'edit_view_swt/document'
require 'edit_view_swt/edit_tab'
require 'edit_view_swt/word_movement'

require 'joni'
require 'jcodings'
require 'jdom'

require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    include Redcar::Observable
    
    def self.start
      gui = ApplicationSWT.gui
      gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      load_textmate_assets
    end
    
    def self.load_textmate_assets
      JavaMateView::Bundle.load_bundles(Redcar.root + "/textmate/")
      JavaMateView::ThemeManager.load_themes(Redcar.root + "/textmate/")
    end
    
    attr_reader :mate_text, :widget, :model
      
    def initialize(model, parent, options={})
      @options = options
      @model = model
      @parent = parent
      @handlers = []
      create_mate_text
      create_document
      attach_listeners
      @mate_text.set_grammar_by_name("Plain Text")
      @model.set_grammar("Plain Text")
      @mate_text.set_theme_by_name(EditView.theme)
      create_undo_manager
      @document.attach_modification_listeners # comes after undo manager
      remove_control_keybindings
      mate_text.add_grammar_listener do |new_grammar|
        @model.set_grammar(new_grammar)
      end
    end
    
    def create_mate_text
      @mate_text = JavaMateView::MateText.new(@parent, !!@options[:single_line])
      @mate_text.set_font(EditView.font, EditView.font_size)
      
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
    
    def create_document
      @document = EditViewSWT::Document.new(@model.document, @mate_text.mate_document)
      @model.document.controller = @document
      h1 = @model.document.add_listener(:before => :new_mirror, 
            &method(:update_grammar))
      h2 = @model.add_listener(:grammar_changed, &method(:model_grammar_changed))
      h3 = @model.add_listener(:focussed, &method(:focus))
      h4 = @model.add_listener(:tab_width_changed) do |new_tab_width|
        @mate_text.get_control.set_tabs(new_tab_width)
      end
      @mate_text.getTextWidget.addFocusListener(FocusListener.new(self))
      @mate_text.getTextWidget.addVerifyListener(VerifyListener.new(@model.document, self))
      @mate_text.getTextWidget.addModifyListener(ModifyListener.new(@model.document, self))
      @mate_text.get_control.add_verify_key_listener(VerifyKeyListener.new(self))
      @handlers << [@model.document, h1] << [@model, h2] << [@model, h3] << [@model, h4]
    end
    
    class VerifyKeyListener
      def initialize(edit_view_swt)
        @edit_view_swt = edit_view_swt
      end
      
      def verify_key(key_event)
        if key_event.character == Swt::SWT::TAB
          key_event.doit = !@edit_view_swt.model.tab_pressed
        elsif key_event.character == Swt::SWT::ESC
          key_event.doit = !@edit_view_swt.model.esc_pressed
        elsif key_event.keyCode == Swt::SWT::ARROW_LEFT
          key_event.doit = !@edit_view_swt.model.left_pressed
        elsif key_event.keyCode == Swt::SWT::ARROW_RIGHT
          key_event.doit = !@edit_view_swt.model.right_pressed
        end
      end
    end
    
    def swt_focus_gained
      EditView.focussed_edit_view = @model
      @model.focus
    end
    
    def swt_focus_lost
      EditView.focussed_edit_view = nil
    end
    
    def focus
      @mate_text.get_control.set_focus
    end
    
    def has_focus?
      focus_control = ApplicationSWT.display.get_focus_control
      focus_control == @mate_text.get_control
    end
  
    def attach_listeners
      # h = @document.add_listener(:set_text, &method(:reparse))
      # @handlers << [@document, h]
      @mate_text.get_text_widget.add_word_movement_listener(WordMoveListener.new(self))
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
      @mate_text.parser.last_visible_line_changed(line_index + 100)
      @mate_text.viewer.set_top_index(line_index)
    end
    
    def model_grammar_changed(name)
      @mate_text.set_grammar_by_name(name)
    end
    
    def smallest_visible_line
      @mate_text.viewer.get_top_index
    end
    
    def biggest_visible_line
      @mate_text.viewer.get_bottom_index
    end
    
    def update_grammar(new_mirror)
      title = new_mirror.title
      return if @mate_text.set_grammar_by_filename(title)
      contents = new_mirror.read
      first_line = contents.to_s.split("\n").first
      grammar = @mate_text.set_grammar_by_first_line(first_line) if first_line
      grammar ||= "Plain Text"
      @model.set_grammar(grammar)
    end
    
    STRIP_KEYS = {
      :cut   => 120|Swt::SWT::MOD1,
      :copy  => 99|Swt::SWT::MOD1,
      :paste => 118|Swt::SWT::MOD1
    }
    
    def remove_control_keybindings
      styled_text = @mate_text.get_text_widget
      STRIP_KEYS.each do |_, key|
        styled_text.set_key_binding(key, Swt::SWT::NULL)
      end
    end
    
    def dispose
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

      def focusLost(_)
        @obj.swt_focus_lost
      end
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
