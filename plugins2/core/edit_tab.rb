
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
        win and tab and tab.is_a? EditTab
      end
      
      Sensitive.register(:modified?, 
                         [:open_window, :new_tab, :close_tab, 
                          :after_focus_tab, :tab_changed, 
                          :after_tab_save]) do
        tab and tab.is_a? EditTab and tab.modified
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
    
    def modified=(val)
      old = @modified
      @modified = val
      if val and !old
        self.label.text += "*"
      elsif !val and old
        self.label.text = self.label.text.gsub(/\*$/, "")
      end
    end
    
    def connect_signals
      @view.buffer.signal_connect_after("changed") do |widget, event|
        self.modified = true
        Hook.trigger :tab_changed, self
        false
      end
    end
    
    def load(filename)
      Hook.trigger :tab_load, self do
        document.text = File.read(filename)
        label.text = filename.split(/\//).last
        document.cursor = 0
        @filename = filename
        @modified = false
      end
    end
    
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
  end
end
