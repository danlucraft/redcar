
module Redcar
  # EditTab is the default class of tab that is used for 
  # editing in Redcar. EditTab is a subclass of Tab that contains
  # one instance of EditView.
  class EditTab < Tab
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
  end
end

