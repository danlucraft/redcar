
module Redcar
  # EditTab is the default class of tab that is used for 
  # editing in Redcar. EditTab is a subclass of Tab that contains
  # one instance of EditView.
  class EditTab < Tab
    # Creates a label on the statusbar that can contain
    # the current line and column 
    def self.create_line_col_status
      unless slot = bus('/gtk/window/statusbar/line', true)
        gtk_hbox = bus('/gtk/window/statusbar').data
        gtk_label = Gtk::Label.new("")
        bus('/gtk/window/statusbar/line').data = gtk_label
        gtk_hbox.pack_end(gtk_label, false)
        gtk_label.set_padding 10, 0
        gtk_label.show
      end
    end

    # Creates a grammar combo on the status bar that
    # reflects the current tab's view's current grammar,
    # and can be used to change it.
    def self.create_grammar_combo
      # When an EditView is created in a window, this needs to go onto it.
      unless slot = bus('/gtk/window/statusbar/grammar_combo', true)
        gtk_hbox = bus('/gtk/window/statusbar').data
        gtk_combo_box = Gtk::ComboBox.new(true)
        bus('/gtk/window/statusbar/grammar_combo').data = gtk_combo_box
        Gtk::Mate.load_bundles
        list = Gtk::Mate::Buffer.bundles.map{|b| b.grammars }.flatten.map(&:name).sort
        list.each {|item| gtk_combo_box.append_text(item) }
        gtk_combo_box.signal_connect("changed") do |gtk_combo_box1|
          if Redcar.tab and Redcar.tab.is_a? EditTab
            Redcar.tab.view.buffer.set_grammar_by_name(list[gtk_combo_box1.active])
            Redcar.tab.view.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
          end
        end
        gtk_hbox.pack_end(gtk_combo_box, false)
        gtk_combo_box.sensitive = false
        gtk_combo_box.show
      end
    end
    
    # Creates all the keybindings for changing grammars. E.g Ctrl+Alt+R for Ruby
    def self.create_grammar_key_bindings
      grammars = Gtk::Mate::Buffer.bundles.map{|b| b.grammars}.flatten
      grammars.each do |grammar|
        redcar_key = Bundle.translate_key_equivalent(grammar.key_equivalent)
        next unless redcar_key
        command_class = Class.new(Redcar::EditTabCommand)
        command_class.range Redcar::EditTab
        command_class.key   redcar_key
        command_class.name = grammar.name
        command_class.class_eval %Q{
          def execute
            App.log.info "[EditTab] setting grammar #{grammar.name}"
            tab.view.buffer.set_grammar_by_name(#{grammar.name.inspect})
            tab.view.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
          end
        }
      end
    end

    # Gets the grammar combo box
    def self.gtk_grammar_combo_box
      bus('/gtk/window/statusbar/grammar_combo', true).data
    end

    # an EditView instance.
    attr_reader :view
    attr_accessor :filename
    attr_reader :modified
    
    # Do not call this directly. Use Window#new_tab or 
    # Pane#new_tab instead:
    # 
    #   win.new_tab(EditTab)
    #   pane.new_tab(EditTab)
    def initialize(pane)
      @view = EditView.new
      connect_signals
      super pane, @view, :scrolled? => true
    end
    
    # Returns the Redcar::Document for this EditTab.
    def document
      @view.buffer
    end
    
    def buffer
      @view.buffer
    end

    def modified=(val) #:nodoc:
      old = @modified
      @modified = val
      if val and !old
        self.title += "*"
      elsif !val and old
        self.title = self.label.text.gsub(/\*$/, "")
      end
    end
    
    def connect_signals #:nodoc:
      @view.buffer.signal_connect_after("changed") do |widget, event|
        self.modified = true
        Hook.trigger :tab_changed, self
        false
      end
      connect_view_signals
    end
    
    def connect_view_signals
      self.buffer.signal_connect("mark_set") do |widget, event, mark|
        if !buffer.ignore_marks and mark == buffer.cursor_mark
          update_line_and_column(mark)
        end
        false
      end

      self.buffer.signal_connect("changed") do |widget, event|
        mark = self.buffer.cursor_mark
        update_line_and_column(mark)
        false
      end
    end

    # Load a document into the tab from the filename given.
    def load(filename)
      Hook.trigger :tab_load, self do
        document.text = ""
        newtext = File.read(filename)
        grammar_name = view.buffer.set_grammar_by_filename(filename) || view.buffer.set_grammar_by_first_line(newtext.split("\n").first)
        if grammar_name
          view.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
        end
        document.begin_not_undoable_action
        document.text = newtext
        document.end_not_undoable_action
        self.title = filename.split(/\//).last
        document.cursor = 0
        @filename = filename
        @modified = false
      end
    end
    
    # Save the document in the tab to the filename that the 
    # file was loaded from.
    def save
      return unless @filename
      Hook.trigger :tab_save, self do
        File.open(@filename, "w") {|f| f.puts document.text}
        self.modified = false
      end
    end

    # Called by initialize to get the icon for the Tab's 'tab'
    def tab_icon
      :FILE
    end

    # Change the syntax of the tab. Takes a name like "Ruby"
    def syntax=(grammar_name)
      @view.buffer.set_grammar_by_name(grammar_name)
    end

    def update_line_and_column(mark) #:nodoc:
      insert_iter = self.buffer.get_iter_at_mark(mark)
      label = bus('/gtk/window/statusbar/line').data
      label.text = "Line: "+ (insert_iter.line+1).to_s +
        "   Col: "+(insert_iter.line_offset+1).to_s
    end

    def close #:nodoc:
      super
      buffer.parser.close if buffer.parser
    end
    
    def contents_as_string
      result = buffer.text
      result.insert(buffser.cursor_offset, "<c>")
    end
    
    def visible_contents_as_string
      start = buffer.line_start(view.first_visible_line)
      _end =  buffer.line_end(view.last_visible_line)
      result = buffer.get_slice(start, _end)
      if buffer.cursor_iter >= start and 
          (buffer.cursor_iter < _end or 
            (_end == buffer.end_iter and buffer.cursor_iter == buffer.end_iter))
        result.insert(buffer.cursor_offset - start.offset, "<c>")
      else
        result
      end
    end
  end
end

