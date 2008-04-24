
module Redcar
  # EditTab is the default class of tab that is used for 
  # editing in Redcar. EditTab is a subclass of Tab that contains
  # one instance of EditView.
  class EditTab < Tab
    
    def self.load(plugin) #:nodoc:
      Hook.register :tab_changed
      Hook.register :tab_save
      Hook.register :tab_load
      
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
      @view = Redcar::EditView.new
      @modified = false
      connect_signals
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
        Hook.trigger :tab_changed, self
        false
      end
    end
    
    # Load a document into the tab from the filename given.
    def load(filename)
      Hook.trigger :tab_load, self do
        document.text = ""
        ext = File.extname(filename)
        if ext != "" and gr = Redcar::EditView::Grammar.grammar(:extension => ext)
          view.change_root_scope(gr.name)
        end
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
      @view.change_root_scope(grammar_name)
    end
  end
end
