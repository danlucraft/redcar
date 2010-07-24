
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
      load_textmate_assets_from_dir(Redcar.root + "/plugins/textmate/vendor/redcar-bundles")
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        load_textmate_assets_from_dir(File.dirname(plugin.definition_file) + "/")
      end
      load_textmate_assets_from_dir(Redcar.user_dir + "/")
      
      EditView.themes.unshift(*JavaMateView::ThemeManager.themes.to_a.map {|th| th.name })
    end
    
    def self.load_textmate_assets_from_dir(dir)
      JavaMateView::Bundle.load_bundles(dir)
      JavaMateView::ThemeManager.load_themes(dir)
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
    
    def compound
      begin_compound
      yield
      end_compound
    end
    
    def begin_compound
      @undo_manager.begin_compound_change
    end
    
    def end_compound
      @undo_manager.end_compound_change
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
      h5 = @model.add_listener(:invisibles_changed) do |new_bool|
        @mate_text.showInvisibles(new_bool)
      end
      h6 = @model.add_listener(:word_wrap_changed) do |new_bool|
        @mate_text.set_word_wrap(new_bool)
      end
      h7 = @model.add_listener(:font_changed) do
        @mate_text.set_font(EditView.font, EditView.font_size)
      end
      h8 = @model.add_listener(:theme_changed) do
        @mate_text.set_theme_by_name(EditView.theme)
      end
      h9 = @model.add_listener(:line_number_visibility_changed) do |new_bool|
        @mate_text.set_line_numbers_visible(new_bool)
      end
      h10 = @model.add_listener(:annotations_visibility_changed) do |new_bool|
        @mate_text.set_annotations_visible(new_bool)
      end
      h11 = @model.add_listener(:margin_column_changed) do |new_column|
        @mate_text.set_margin_column(new_column)
      end
      h12 = @model.add_listener(:show_margin_changed) do |new_bool|
        if new_bool
          @mate_text.set_margin_column(@model.margin_column)
        else
          @mate_text.set_margin_column(-1)
        end
      end
      @mate_text.getTextWidget.addFocusListener(FocusListener.new(self))
      @mate_text.getTextWidget.addVerifyListener(VerifyListener.new(@model.document, self))
      @mate_text.getTextWidget.addModifyListener(ModifyListener.new(@model.document, self))
      @mate_text.get_control.add_verify_key_listener(VerifyKeyListener.new(self))
      @mate_text.get_control.add_key_listener(KeyListener.new(self))
      @handlers << [@model.document, h1] << [@model, h2] << [@model, h3] << [@model, h4] << 
        [@model, h5] << [@model, h6] << [@model, h7] << [@model, h8] <<
        [@model, h9] << [@model, h10] << [@model, h11]
    end
    
    class VerifyKeyListener
      def initialize(edit_view_swt)
        @edit_view_swt = edit_view_swt
      end
      
      def verify_key(key_event)
        if @edit_view_swt.model.document.block_selection_mode?
          @edit_view_swt.begin_compound
        end
        if key_event.character == Swt::SWT::TAB
          key_event.doit = !@edit_view_swt.model.tab_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        elsif key_event.character == Swt::SWT::ESC
          key_event.doit = !@edit_view_swt.model.esc_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        elsif key_event.keyCode == Swt::SWT::ARROW_LEFT
          key_event.doit = !@edit_view_swt.model.left_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        elsif key_event.keyCode == Swt::SWT::ARROW_RIGHT
          key_event.doit = !@edit_view_swt.model.right_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        elsif key_event.character == Swt::SWT::DEL
          key_event.doit = !@edit_view_swt.model.delete_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        elsif key_event.character == Swt::SWT::BS
          key_event.doit = !@edit_view_swt.model.backspace_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
        end
      end
    end
    
    class KeyListener
      def initialize(edit_view_swt)
        @edit_view_swt = edit_view_swt
      end
      
      def key_pressed(_)
        @was_in_block_selection = @edit_view_swt.model.document.block_selection_mode?
      end
      
      def key_released(_)
        if @was_in_block_selection
          @edit_view_swt.end_compound
        end
      end
    end
    
    def delay_parsing
      mate_text.delay_parsing { yield }
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
    
    def is_current?
      EditView.current == @mate_text.get_control
    end
    
    def has_focus?
      focus_control = ApplicationSWT.display.get_focus_control
      focus_control == @mate_text.get_control
    end
    
    def exists?
      @mate_text.get_control and !@mate_text.get_control.disposed
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
      @mate_text.parser.parserScheduler.last_visible_line_changed(line_index + 100)
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
    
    def ensure_visible(offset)
      line = @document.line_at_offset(offset)
      line_start_offset = @document.offset_at_line(line)
      if offset == line_start_offset
        # This doesn't work. Bug in JFace.SourceViewer?
        @mate_text.viewer.reveal_range(offset, 1)
        # so we do this too:
        @mate_text.get_control.set_horizontal_pixel(0)
      else
        @mate_text.viewer.reveal_range(offset, 1)
      end
    end
    
    def update_grammar(new_mirror)
      title = new_mirror.title
      contents = new_mirror.read
      first_line = contents.to_s.split("\n").first
      grammar_name = @mate_text.set_grammar_by_first_line(first_line) if first_line
      unless grammar_name
        grammar_name = @mate_text.set_grammar_by_filename(title)
      end
      grammar_name ||= "Plain Text"
      @model.set_grammar(grammar_name)
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
