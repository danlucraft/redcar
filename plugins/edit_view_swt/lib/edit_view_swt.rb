
require 'edit_view_swt/document'
require 'edit_view_swt/edit_tab'
require 'edit_view_swt/word_movement'

require 'joni'
require 'jcodings'
require 'jdom'

require "java-mateview-#{Redcar::VERSION}"
require File.dirname(__FILE__) + '/../vendor/java-mateview'

module Redcar
  class EditViewSWT
    NAVIGATION_COMMANDS = {
      :LINE_UP                => 16777217,
      :LINE_DOWN              => 16777218,
      :LINE_START             => 16777223,
      :LINE_END               => 16777224,
      :COLUMN_PREVIOUS        => 16777219,
      :COLUMN_NEXT            => 16777220,
      :PAGE_UP                => 16777221,
      :PAGE_DOWN              => 16777222,
      :WORD_PREVIOUS          => 17039363,
      :WORD_NEXT              => 17039364,
      :TEXT_START             => 17039367,
      :TEXT_END               => 17039368,
      :WINDOW_START           => 17039365,
      :WINDOW_END             => 17039366
    }

    SELECTION_COMMANDS = {
      :SELECT_ALL             => 262209,
      :SELECT_LINE_UP         => 16908289,
      :SELECT_LINE_DOWN       => 16908290,
      :SELECT_LINE_START      => 16908295,
      :SELECT_LINE_END        => 16908296,
      :SELECT_COLUMN_PREVIOUS => 16908291,
      :SELECT_COLUMN_NEXT     => 16908292,
      :SELECT_PAGE_UP         => 16908293,
      :SELECT_PAGE_DOWN       => 16908294,
      :SELECT_WORD_PREVIOUS   => 17170435,
      :SELECT_WORD_NEXT       => 17170436,
      :SELECT_TEXT_START      => 17170439,
      :SELECT_TEXT_END        => 17170440,
      :SELECT_WINDOW_START    => 17170437,
      :SELECT_WINDOW_END      => 17170438
    }

    MODIFICATION_COMMANDS = {
      :CUT                    => 131199,
      :COPY                   => 17039369,
      :PASTE                  => 16908297,
      :DELETE_PREVIOUS        => 8,
      :DELETE_NEXT            => 0x7F,
      :DELETE_WORD_PREVIOUS   => 262152,
      :DELETE_WORD_NEXT       => 262271
    }

    ALL_ACTIONS = NAVIGATION_COMMANDS.merge(SELECTION_COMMANDS).merge(MODIFICATION_COMMANDS)

    include Redcar::Observable
    include Redcar::Controller

    def self.start
      if gui = Redcar.gui
        gui.register_controllers(Redcar::EditTab => EditViewSWT::Tab)
      end
      load_textmate_assets
    end

    def self.load_textmate_assets
      s = Time.now
      load_textmate_assets_from_dir(Redcar.root + "/plugins/textmate/vendor/redcar-bundles")
      Redcar.plugin_manager.loaded_plugins.each do |plugin|
        load_textmate_assets_from_dir(File.dirname(plugin.definition_file) + "/")
      end
      load_textmate_assets_from_dir(Redcar.user_dir + "/")
      puts "took #{Time.now - s}s to load textmate assets"
      EditView.themes.unshift(*JavaMateView::ThemeManager.themes.to_a.map {|th| th.name })
    end

    def self.load_textmate_assets_from_dir(dir)
      JavaMateView::Bundle.load_bundles(dir)
      JavaMateView::ThemeManager.load_themes(dir)
    end

    attr_reader :mate_text, :widget, :model, :key_listener, :verify_key_listener

    def initialize(model, parent, options={})
      @options = options
      @model = model
      @parent = parent
      @handlers = []
      create_mate_text
      create_document
      Redcar.plugin_manager.objects_implementing(:edit_view_gui_update).each do |object|
        object.edit_view_gui_update(@mate_text)
      end
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

      create_model_listeners
    end

    def create_mate_text
      @mate_text = JavaMateView::MateText.new(@parent, !!@options[:single_line])
      @mate_text.set_font(EditView.font, EditView.font_size)

      @model.controller = self

      add_styled_text_command_key_listeners
    end

    class CommandKeyListener

      attr_reader :st

      def initialize(styled_text, edit_view)
        @edit_view = edit_view
        @st = styled_text
      end

      def key_pressed(event)
      end

      def key_released(event)
        record_action(event)
      end

      # This pile of crap is copied from StyledText#handleKey. Wouldn't
      # it be great if this logic was accessible on StyledText somehow?
      def record_action(event)
        if (event.keyCode != 0)
          # special key pressed (e.g., F1)
          action = st.getKeyBinding(event.keyCode | event.stateMask)
        else
          # character key pressed
          action = st.getKeyBinding(event.character | event.stateMask)
          if (action == Swt::SWT::NULL)
            # see if we have a control character
            if ((event.stateMask & Swt::SWT::CTRL) != 0 && event.character <= 31)
              # get the character from the CTRL+char sequence, the control
              # key subtracts 64 from the value of the key that it modifies
              c = event.character + 64
              action = st.getKeyBinding(c | event.stateMask)
            end
          end
        end

        if (action == Swt::SWT::NULL)
		      ignore = false

          if (Redcar.platform == :osx)
            # Ignore accelerator key combinations (we do not want to
            # insert a character in the text in this instance). Do not
            # ignore COMMAND+ALT combinations since that key sequence
            # produces characters on the mac.
            ignore = (event.stateMask & Swt::SWT::COMMAND) != 0 ||
              (event.stateMask & Swt::SWT::CTRL) != 0
          else
    			  # Ignore accelerator key combinations (we do not want to
            # insert a character in the text in this instance). Don't
            # ignore CTRL+ALT combinations since that is the Alt Gr
            # key on some keyboards.  See bug 20953.
            ignore = (event.stateMask ^ Swt::SWT::ALT) == 0 ||
              (event.stateMask ^ Swt::SWT::CTRL) == 0 ||
              (event.stateMask ^ (Swt::SWT::ALT | Swt::SWT::SHIFT)) == 0 ||
              (event.stateMask ^ (Swt::SWT::CTRL | Swt::SWT::SHIFT)) == 0
          end
          # -ignore anything below SPACE except for line delimiter keys and tab.
          # -ignore DEL
          if (!ignore && event.character > 31 && event.character != Swt::SWT::DEL ||
            event.character == Swt::SWT::CR || event.character == Swt::SWT::LF ||
                event.character == Swt::SWT::TAB)
            @edit_view.history.record(event.character)
          end
        else
          @edit_view.history.record(EditViewSWT::ALL_ACTIONS.invert[action])
        end
      end
    end

    def add_styled_text_command_key_listeners
      st = @mate_text.get_text_widget
      st.add_key_listener(CommandKeyListener.new(st, @model))
    end

    def create_undo_manager
      @undo_manager = JFace::Text::TextViewerUndoManager.new(5000)
      @undo_manager.connect(@mate_text.viewer)
    end

    def undo
      @undo_manager.undo
      unless @undo_manager.undoable?
        @undoable_override = false
      end
      EditView.undo_sensitivity.recompute
      EditView.redo_sensitivity.recompute
    end

    def undoable?
      # The override malarky is because the JFace::TextViewerUndoManager doesn't
      # recognize that typing while in Block Selection mode makes the edit view
      # undoable. (Even though it faithfully records the actions, and responds
      # correctly to "undo".) So we override the undo manager for this case.
      @undoable_override || @undo_manager.undoable
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
      @undoable_override = false
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

    def annotations(options = nil)
      return @mate_text.annotations unless options
      if options[:line]
        @mate_text.annotationsOnLine(options[:line] - 1)
      elsif options[:type]
        annotations_of_type(options[:type])
      end
    end

    def annotations_of_type(type)
      annotations.select {|a| a.type == type }
    end

    def add_annotation_type(name, image_path, rgb)
      rgb = Swt::Graphics::RGB.new(rgb[0], rgb[1], rgb[2])
      @mate_text.addAnnotationType(name, image_path, rgb)
    end

    def add_annotation(annotation_name, line, text, start, length)
      @mate_text.addAnnotation(annotation_name, line, text, start, length)
    end

    def remove_annotation(mate_annotation)
      @mate_text.removeAnnotation(mate_annotation)
    end

    def remove_all_annotations(options = nil)
      return @mate_text.remove_all_annotations unless options
      annotations(options).each do |ann|
        remove_annotation(ann)
      end
    end

    def reset_right_margin
      return if @options[:single_line]
      if @model.word_wrap?
        size = @mate_text.get_text_widget.get_size
        width = size.x
        @mate_text.get_text_widget.right_margin = width - char_width*(@model.margin_column||0) - 3*char_width
      else
        @mate_text.get_text_widget.right_margin = 0
      end
    end

    def char_width
      return 0 if !!@options[:single_line]
      @char_width ||= begin
        gc = Swt::Graphics::GC.new(@mate_text.get_text_widget)
        fm = gc.getFontMetrics
        width = fm.getAverageCharWidth
        gc.dispose
        width
      end
    end

    def clear_char_width
      @char_width = nil
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

      h6 = @model.add_listener(:word_wrap_changed) do |should_word_wrap|
        @mate_text.set_word_wrap(should_word_wrap)
        reset_right_margin
      end

      h11 = @model.add_listener(:margin_column_changed) do |new_column|
        @mate_text.set_margin_column(new_column)
        reset_right_margin
      end

      h12 = @model.add_listener(:show_margin_changed) do |new_bool|
        if new_bool
          @mate_text.set_margin_column(@model.margin_column)
        else
          @mate_text.set_margin_column(-1)
        end
      end

      h7 = @model.add_listener(:font_changed) do
        @mate_text.set_font(EditView.font, EditView.font_size)
        clear_char_width
        reset_right_margin
      end

      h8 = @model.add_listener(:theme_changed) do
        @mate_text.set_theme_by_name(EditView.theme)
      end
      h9 = @model.add_listener(:line_number_visibility_changed) do |new_bool|
        @mate_text.set_line_numbers_visible(new_bool)
      end
      h13 = @model.document.add_listener(:changed) do
        @undoable_override = true
      end
      @mate_text.getTextWidget.addMouseListener(MouseListener.new(self))
      @mate_text.getTextWidget.addFocusListener(FocusListener.new(self))
      @mate_text.getTextWidget.addVerifyListener(VerifyListener.new(@model.document, self))
      @mate_text.getTextWidget.addModifyListener(ModifyListener.new(@model.document, self))
      @verify_key_listener = VerifyKeyListener.new(self)
      @key_listener = KeyListener.new(self)
      @mate_text.get_control.add_verify_key_listener(@verify_key_listener)
      @mate_text.get_control.add_key_listener(@key_listener)
      @handlers << [@model.document, h1] << [@model, h2] << [@model, h3] << [@model, h4] <<
        [@model, h5] << [@model, h6] << [@model, h7] << [@model, h8] <<
        [@model, h9] << [@model, h11] << [@model.document, h13]
    end

    def right_click(mouse_event)
      if @model.document.controller and @model.document.controller.respond_to?(:right_click)
        location = ApplicationSWT.display.get_cursor_location
        #offset = @mate_text.parser.styledText.get_offset_at_location(location)
        Redcar.safely("right click on edit view") do
          @model.document.controller.right_click(@model)
        end
      end
    end

    def type_character(character)
      mate_text.get_text_widget.doContent(character)
      mate_text.get_text_widget.update
    end

    model_listener :type_character

    def invoke_action(action_symbol)
      const = EditViewSWT::ALL_ACTIONS[action_symbol]
      mate_text.get_text_widget.invokeAction(const)
    end

    model_listener :invoke_action

    class VerifyKeyListener
      def initialize(edit_view_swt)
        @edit_view_swt = edit_view_swt
      end

      def verify_key(key_event)
        #uncomment this line for key debugging
        #puts "got keyevent: #{key_event.character} #{key_event.stateMask}"
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
        elsif key_event.character == 13 and (key_event.stateMask == Swt::SWT::COMMAND or key_event.stateMask == Swt::SWT::CTRL)
          key_event.doit = !@edit_view_swt.model.cmd_enter_pressed(ApplicationSWT::Menu::BindingTranslator.modifiers(key_event))
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
      @mate_text.get_text_widget.add_control_listener(ControlListener.new(self))
    end

    class ControlListener
      def initialize(edit_view_swt)
        @edit_view_swt = edit_view_swt
      end

      def controlMoved(*_)
      end

      def controlResized(e)
        @edit_view_swt.reset_right_margin
      end
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

    def scroll_to_horizontal_offset(offset)
      @mate_text.get_text_widget.set_horizontal_index(offset)
    end

    def smallest_visible_horizontal_index
      @mate_text.get_text_widget.get_horizontal_index
    end

    def largest_visible_horizontal_index
      wpix = @mate_text.get_text_widget.get_client_area.width
      gc   = org.eclipse.swt.graphics.GC.new(@mate_text.get_text_widget)
      inc  = gc.getFontMetrics().getAverageCharWidth()
      gc.dispose
      @mate_text.get_text_widget.get_horizontal_index + (wpix/inc)
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

    class MouseListener
      def initialize(obj)
        @obj = obj
      end

      def mouse_double_click(_); end
      def mouse_up(_)
      end

      def mouse_down(e)
        if e.button == 3
          @obj.right_click(e)
        end
      end
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
