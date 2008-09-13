
module Redcar
  # EditTab is the default class of tab that is used for 
  # editing in Redcar. EditTab is a subclass of Tab that contains
  # one instance of EditView.
  class EditTab < Tab
    
    class SnippetCommand < Redcar::Command
      range Redcar::EditTab
    end
    
    def self.load(plugin) #:nodoc:
      Hook.register :tab_changed
      Hook.register :tab_save
      Hook.register :tab_load
      
      Redcar::EditTab::Indenter.lookup_indent_rules
      Sensitive.register(:edit_tab, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab]) do
        Redcar.win and Redcar.tab and Redcar.tab.is_a? EditTab
      end
      
      Sensitive.register(:modified?, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab, :tab_changed, 
                          :after_tab_save]) do
        Redcar.tab and Redcar.tab.is_a? EditTab and Redcar.tab.modified
      end
      
      Sensitive.register(:modified_and_filename?, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab, :tab_changed, 
                          :after_tab_save]) do
        Redcar.tab and Redcar.tab.is_a? EditTab and Redcar.tab.modified and Redcar.tab.filename
      end
      
#       Sensitive.register(:selected_text, 
#                          [:open_window, :new_tab, :close_tab, 
#                           :after_focus_tab]) do
#         win and tab and tab.is_a? EditTab
#       end
      plugin.transition(FreeBASE::LOADED)
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
      @view = Gtk::Mate::View.new
      @view.buffer = Gtk::Mate::Buffer.new
      @view.modify_font(Pango::FontDescription.new(Redcar::Preference.get("Appearance/Tab Font")))
      @view.buffer.set_grammar_by_name("Ruby")
      h = @view.signal_connect_after("expose-event") do |_, ev|
        if ev.window == @view.window
          @view.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
          @view.signal_handler_disconnect(h)
        end
      end
      @modified = false
      if Redcar::Preference.get("Editing/Wrap words").to_bool
        @view.wrap_mode = Gtk::TextTag::WRAP_WORD
      else
        @view.wrap_mode = Gtk::TextTag::WRAP_NONE
      end
      @view.left_margin = 5
      @view.show_line_numbers = Redcar::Preference.get("Editing/Show line numbers").to_bool
      connect_signals
      create_indenter
      create_autopairer
      create_snippet_inserter
      super pane, @view, :scrolled? => true
    end
    
    # Returns the Redcar::Document for this EditTab.
    def document
      @view.buffer
    end
    
    def modified=(val) #:nodoc:
      old = @modified
      @modified = val
      if val and !old
        self.label.text += "*"
      elsif !val and old
        self.label.text = self.label.text.gsub(/\*$/, "")
      end
    end
    
    def connect_signals #:nodoc:
      @view.buffer.signal_connect_after("changed") do |widget, event|
        self.modified = true
#        Hook.trigger :tab_changed, self
        false
      end
    end
    
    # Load a document into the tab from the filename given.
    def load(filename)
      Hook.trigger :tab_load, self do
        document.text = ""
        ext = File.extname(filename)
        view.buffer.set_grammar_by_extension(ext)
        view.set_theme_by_name(Redcar::Preference.get("Appearance/Tab Theme"))
        document.begin_not_undoable_action
        document.text = File.read(filename)
        document.end_not_undoable_action
        label.text = filename.split(/\//).last
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

    def create_indenter
      @indenter = Indenter.new(@view.buffer)
    end

    def create_autopairer
      @autopairer = AutoPairer.new(@view.buffer)
    end

    def create_snippet_inserter
      @snippet_inserter = SnippetInserter.new(@view.buffer)
    end

    def snippet_inserter
      @snippet_inserter
    end
  end
end

require File.dirname(__FILE__) + '/indenter'
require File.dirname(__FILE__) + '/autopairer'
require File.dirname(__FILE__) + '/snippet_inserter'
