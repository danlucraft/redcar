
module Gtk
  class TextIter
    def forward_cursor_position!
      self.forward_cursor_position
      self
    end
    
    def backward_cursor_position!
      self.backward_cursor_position
      self
    end
    
    def forward_word_end!
      self.forward_word_end
      self
    end
    
    def backward_word_start!
      self.backward_word_start
      self
    end
  end
end

Redcar.hook :after_startup do
  Redcar.MainToolbar.append_combo(
      Redcar.SyntaxSourceView.grammar_names.sort) do |_, tab, grammar|
    if tab.respond_to? :sourceview
      tab.sourceview.set_grammar(Redcar.SyntaxSourceView.grammar(:name => grammar))
    end
  end
end

module Redcar  

  class TextTab < Tab
    include UserCommands
    extend Redcar::PreferencesBuilder
    extend Redcar::CommandBuilder
    extend Redcar::ContextMenuBuilder
    
    context_menu "TextTab/Cut" do |m|
      m.icon = :COPY
      m.command = "Core/Edit/Cut"
    end
    
    command "TextTab/Print Foo" do |m|
      m.icon = :INFO
      m.keybinding = "alt f"
      m.command %q{
        puts :"Foo!"
      }
      m.context_menu = "TextTab/Foo!"
    end
    
    def to_undo(*args, &block)
      true
    end
    
    preference "Appearance/Tab Font" do |p|
      p.default = "Monospace 12"
      p.widget = fn { TextTab.font_chooser_button("Appearance/Tab Font") }
      p.change do
        Redcar.current_window.all_tabs.each do |tab|
          if tab.respond_to? :set_font
            tab.set_font($BUS["/redcar/preferences/Appearance/Tab Font"].data)
          end
        end
      end
    end
    
    preference "Appearance/Entry Font" do |p|
      p.default = "Monospace 12"
      p.widget = fn { TextTab.font_chooser_button("Appearance/Entry Font") }
    end
    
    def self.font_chooser_button(name)
      gtk_image = Gtk.Image.new(Gtk.Stock.SELECT_FONT, 
                                 Gtk.IconSize.MENU)
      gtk_hbox = Gtk.HBox.new
      gtk_label = Gtk.Label.new($BUS["/redcar/preferences/"+name].data)
      gtk_hbox.pack_start(gtk_image, false)
      gtk_hbox.pack_start(gtk_label)
      widget = Gtk.Button.new
      widget.add(gtk_hbox)
      class << widget
        attr_accessor :preference_value
      end
      widget.preference_value = $BUS["/redcar/preferences/"+name].data
      widget.signal_connect('clicked') do
        dialog = Gtk.FontSelectionDialog.new("Select Application Font")
        dialog.font_name = widget.preference_value
        dialog.preview_text = "Redcar is for Ruby"
        if dialog.run == Gtk.Dialog.RESPONSE_OK
          puts font = dialog.font_name
          font = dialog.font_name
          widget.preference_value = font
          gtk_label.text = font
        end
        dialog.destroy
      end
      widget
    end
    
    attr_accessor :filename, :buffer
    
    # ------ User commands
    
    user_commands do
      def cursor=(offset)
        if offset.is_a? Gtk.TextIter
          self.buffer.place_cursor(offset)
        else
          case offset
          when :line_start
            offset = self.buffer.get_iter_at_line(iter(cursor_mark).line).offset
          when :line_end
            line_num = iter(cursor_mark).line
            length = get_line(line_num).to_s.chomp.chars.length
            offset = self.buffer.get_iter_at_line_offset(line_num, length)
          when :tab_start
            offset = 0
          when :tab_end
            offset = length
          else
            true
          end
          self.buffer.place_cursor(iter(offset))
        end
        @textview.scroll_mark_onscreen(cursor_mark)
      end
      
      # the undo actions for these are not quite right
      def left
        self.cursor = [cursor_offset - 1, 0].max
      end
      
      def right
        self.cursor = [cursor_offset + 1, length].min
      end
      
      def up
        self.cursor = above_offset(cursor_offset)
      end
      
      def down
        self.cursor = below_offset(cursor_offset)
      end
      
      def shift_left
        self.buffer.move_mark(cursor_mark, iter(cursor_mark).backward_cursor_position!)
      end
      
      def shift_right
        self.buffer.move_mark(cursor_mark, iter(cursor_mark).forward_cursor_position!)
      end
      
      def shift_up
        self.buffer.move_mark(cursor_mark, iter(above_offset(cursor_offset)))
      end
      
      def shift_down
        self.buffer.move_mark(cursor_mark, iter(below_offset(cursor_offset)))
      end
      
      def page_down
        new_line = [cursor_line+20, line_count].min
        self.cursor = TextLoc.new(new_line, 0)
      end
      
      def page_up
        new_line = [cursor_line-20, 0].max
        self.cursor = TextLoc.new(new_line, 0)
      end
      
      def cut
        Clipboard << selection unless selection == ""
        delete_selection
      end
      
      def copy
        Clipboard << selection unless selection == ""
      end
      
      def paste
        delete_selection
        insert_at_cursor Clipboard.top
      end
      
      def backspace
        if selected?
          delete_selection
        else
          delete(cursor_offset-1, cursor_offset)
        end
      end
      
      def del
        if selected?
          delete_selection
        else
          delete(cursor_offset, cursor_offset+1)
        end
      end
      
      def delete_selection
        if selected?
          delete(cursor_offset, selection_offset)
        end
      end
      
      def insert_at_cursor(str)
        insert(cursor_offset, str)
      end
      
      def return
        current_indent = get_line.match(/^\s+/).to_s.gsub("\n", "").length
        p current_indent
        insert_at_cursor("\n"+" "*current_indent)
      end
      
      def length
        self.buffer.char_count
      end
      
      def to_s
        self.buffer.text
      end
      
      def modified=(val)
        to_undo :modified=, modified?
        self.buffer.modified = val
        Redcar.event :tab_modified, self
        @was_modified = val
      end
      
      def select(from, to)
        Redcar.event :select, self
        to_undo :cursor=, cursor_offset
        self.buffer.move_mark(cursor_mark, iter(to))
        self.buffer.move_mark(selection_mark, iter(from))
        @textview.scroll_mark_onscreen(cursor_mark)
      end
      
      def set_text(obj, str)
        case obj.class.to_s
        when "Fixnum", "Bignum", "Integer"
          old = self[obj]
          delete(obj, obj+1)
          insert(obj, str)
        when "Range"
          delete(obj.first, obj.last+1)
          insert(obj.first, str)
        end
      end
      
      def contents=(str)
        replace(str)
      end
      
      def replace(str)
        delete(0, self.length)
        insert(0, str)
      end
      
      def insert(offset, str)
        offset = iter(offset).offset
        to_undo :delete, offset, str.length+offset, str
        self.buffer.insert(iter(offset), str)
#         self.buffer.signal_emit("inserted_text", iter(offset), 
#                             str, str.length)
      end
      
      def delete(from, to, text="")
        from = iter(from).offset
        to = iter(to).offset
        to_undo :cursor=, cursor_offset
        text = self.buffer.get_slice(iter(from), iter(to))
        self.buffer.delete(iter(from), iter(to))
        to_undo :insert, from, text
        text
      end
      
      def find_next(str)
        rest = self.contents[(cursor_offset+1)..-1]
        return nil unless rest
        if md = rest.match(/#{str}/)
          p md.offset(0).map{|e| e+cursor_offset+1}
          select(*(md.offset(0).map{|e| e+cursor_offset+1}))
          true
        else
          nil
        end
      end
    end
    
    # tab.text[1..10]
    # tab.text[1..10] = "foobar"
    define_method_bracket_with_equals :text,
    :get => fn { |obj|      get_text(obj) },
    :set => fn { |obj, str| set_text(obj, str) }
    
    def get_text(obj)
      case obj.class.to_s
      when "Fixnum", "Bignum", "Integer"
        self.buffer.text.at(obj)
      when "Range"
        self.buffer.text[obj]
      end
    end
    
    def undo
      self.buffer.undo!
    end
    
    def redo
      self.buffer.redo!
    end
    
    def forward_word
      self.cursor = cursor_iter.forward_word_end!
    end
    
    def backward_word
      self.cursor = cursor_iter.backward_word_start!
    end
    
    def replace_selection(text=nil)
      current_text = self.selection
      startsel, endsel  = self.selection_bounds
      self.delete_selection
      if text==nil
        if block_given?
          new_text = yield(current_text.chars)
        end
      else
        new_text = text
      end
      self.insert_at_cursor(new_text)
      self.select(startsel, startsel+new_text.length)
    end
    
    def replace_line(text=nil)
      current_text = self.get_line
      current_cursor = cursor_offset
      startsel, endsel = self.selection_bounds
      self.delete(line_start(cursor_line), 
                  line_end(cursor_line))
      if text==nil
        if block_given?
          new_text = yield(current_text.chars)
        end
      else
        new_text = text
      end
      self.insert(line_start(cursor_line).offset, new_text)
      self.cursor = current_cursor
      self.select(startsel, endsel)
    end
    
    def modified?
      self.buffer.modified?
    end
      
    def buffer
      @textview.buffer
    end
    
    def iter(thing)
      case thing
      when Integer
        thing = [0, thing].max
        thing = [length, thing].min
        self.buffer.get_iter_at_offset(thing)
      when Gtk.TextMark
        self.buffer.get_iter_at_mark(thing)
      when Gtk.TextIter
        thing
      when TextLoc
        line_start = self.buffer.get_iter_at_line(thing.line)
        iter(line_start.offset+thing.offset)
      end
    end
    
    def iter_at_line(num)
      return iter(end_mark) if num == line_count
      self.buffer.get_iter_at_line(num)
    end
    
    def line_start(num)
      iter_at_line(num)
    end
    
    def line_end(num)
      if num >= line_count - 1
        iter(end_mark)
      else
        iter_at_line(num+1)
      end
    end
    
    def get_line(num=nil)
      if num == nil
        return get_line(cursor_line)
      end
      if num == self.buffer.line_count-1
        end_iter = iter(end_mark)
      elsif num > self.buffer.line_count-1
        return nil
      elsif num < 0
        if num >= -self.buffer.line_count
          return get_line(self.buffer.line_count+num).chars
        else
          return nil
        end
      else
        end_iter = iter_at_line(num+1)
      end
      self.buffer.get_slice(iter_at_line(num), end_iter).chars
    end
    
    def get_lines(selector)
      if selector.is_a? Range
        st = selector.begin
        en = selector.end
        if st < 0
          nst = self.buffer.line_count+st
        else
          nst = st
        end
        if en < 0
          nen = self.buffer.line_count+en
        else
          nen = en
        end
        a = [nst, nen].sort
        selector = a[0]..a[1]
      end
      selector.map{|num| get_line(num)}
    end
    
    def line_count
      self.buffer.line_count
    end
    
    def char_count
      self.buffer.char_count
    end
    
    def cursor_mark
      self.buffer.get_mark("insert")
    end
    
    def cursor_iter
      iter(self.buffer.get_mark("insert"))
    end
    
    def cursor_line
      iter(cursor_mark).line
    end
    
    def cursor_offset
      iter(cursor_mark).offset
    end
    
    def cursor_line_offset
      iter(cursor_mark).line_offset
    end
    
    def selection_mark
      self.buffer.get_mark("selection_bound")
    end
    
    def selection_offset
      iter(selection_mark).offset
    end
    
    def start_mark
      self.buffer.get_mark("start-mark") or
        self.buffer.create_mark("start-mark", iter(0), true)
    end
    
    def end_mark
      self.buffer.get_mark("end-mark") or
        self.buffer.create_mark("end-mark", iter(self.length), false)
    end
    
    def above_offset(offset)
      above_line_num = [iter(offset).line-1, 0].max
      return 0 if above_line_num == 0
      [
       self.buffer.get_iter_at_line(above_line_num).offset + 
         [iter(offset).line_offset, get_line(above_line_num).length-1].min,
       0
      ].max
    end
    
    def below_offset(offset)
      below_line_num = iter(offset).line+1
      return char_count-1 if below_line_num == line_count
      [
       self.buffer.get_iter_at_line(below_line_num).offset + 
         [iter(offset).line_offset, get_line(below_line_num).length-1].min,
       length
      ].min
    end
    
    def selected?
      start_iter, end_iter, bool = self.buffer.selection_bounds
      bool
    end
    
    def selection_bounds
      start_iter, end_iter, bool = self.buffer.selection_bounds
      return start_iter.offset, end_iter.offset
    end
    
    def selection
      self.buffer.get_text(iter(selection_mark), iter(cursor_mark))
    end
    
    def contents
      self.buffer.text
    end
    
    def insert_as_snippet(str)
      puts "do not know how to insert snippets yet"
    end
    
    # --------
    
    attr_accessor :textview
    alias sourceview textview
    
    def initialize(pane)
      Gtk.RC.parse_string(<<-EOR)
  style "green-cursor" {
    GtkTextView::cursor-color = "grey"
  }
  class "GtkWidget" style "green-cursor"
  EOR
      @textview = SyntaxSourceView.new
#      @textview.wrap_mode = Gtk.TextTag.WRAP_WORD
#       @textview = Redcar.GUI.Text.new(buffer, textview)
      self.set_font(Redcar.preferences("Appearance/Tab Font"))
      super(pane, @textview, :scrolled => true)
      Redcar.tab_length ||= 2
      connect_signals
    end
  
    
    def focus
      super
      @textview.grab_focus
    end

    def connect_signals
      @textview.signal_connect('focus-in-event') do |widget, event|
        Redcar.current_pane = self.pane
        Redcar.current_tab = self
        Redcar.event :tab_focus, self
        false
      end

      @was_modified = false
      self.buffer.signal_connect("changed") do |widget, event|
        Redcar.event :tab_modified, self unless @was_modified
        Redcar.event :tab_changed
        @was_modified = true
        false
      end
      
      self.buffer.signal_connect("mark_set") do |widget, event, mark|
        if mark.name == "insert"
          insert_iter = self.buffer.get_iter_at_mark(mark)
          Redcar.StatusBar.sub = "line "+ (insert_iter.line+1).to_s + 
            "   col "+(insert_iter.line_offset+1).to_s
        end
        Redcar.StatusBar.main = "" unless Time.now - Redcar.StatusBar.main_time < 5
        Redcar.event :tab_changed
        false
      end
      
      # eat right button clicks:
      @textview.signal_connect("button_press_event") do |widget, event|
        Redcar.current_tab = self
        Redcar.current_pane = self.pane
        if event.kind_of? Gdk.EventButton 
          Redcar.event :tab_clicked, self
          if event.button == 3
            $BUS['/redcar/services/context_menu_popup'].call("TextTab", event.button, event.time)
          end
        end
      end
    end
    
    def set_font(font)
      @textview.modify_font(Pango.FontDescription.new(font))
    end
    
    def load(filename=nil)
      @filename = filename if filename
      Redcar.event :load, self do
        if @filename
          self.replace(Redcar.RedcarFile.load(@filename))
        else
          p :no_filename_to_load_into_tab
        end
      end
      if @filename
        ext = File.extname(@filename)
        @textview.set_grammar(gr = SyntaxSourceView.grammar(:extension => ext))
        if gr
          @textview.colour
        end
      end
      if 
        @textview.set_grammar(gr = SyntaxSourceView.grammar(:first_line => self.get_line(0)))
        if gr
          @textview.colour
        end
      end
    end
    
    def save
      Redcar.event :save, self do
        self.save!
      end
    end
    
    def save!
      if @filename
        Redcar.RedcarFile.save(@filename, self.to_s)
      end
      self.buffer.modified = false
    end
    
    attr_accessor :discard_changes
    
    def close
      pane = self.pane
      if self.modified?
        ask_and_save_tab(self)
      else
        self.close!
      end
    end
  end
end

def ask_and_save_tab(tab)
  dialog = Redcar.Dialog.build(:title => "Save?",
                                :buttons => [:Save, :Discard, :Cancel],
                                :message => "Tab modified. Save or discard?")
  dialog.on_button(:Save) do
    dialog.close
    tab.save
    tab.close!
  end
  dialog.on_button(:Discard) do
    dialog.close
    tab.close!
  end
  dialog.on_button(:Cancel) do
    dialog.close
  end
  dialog.show :modal => true
end
  
