module Redcar
  class Notebook
    include Redcar::Model
    include Redcar::Observable
    
    attr_reader :window
    
    def initialize(window)
      @tabs         = []
      @focussed_tab = nil
      @tab_handlers = Hash.new {|h,k| h[k] = [] }
      @window       = window
    end
    
    def length
      @tabs.length
    end
    
    def focussed_tab
      @focussed_tab
    end
    
    def tabs
      @tabs.clone
    end
    
    # Creates a new tab in this Notebook, of class tab_class. Returns
    # the tab.
    #
    # Events: tab_added (tab)
    def new_tab(tab_class)
      tab = tab_class.new(self)
      attach_tab_listeners(tab)
      notify_listeners(:tab_added, tab) do
        @tabs << tab
      end
      Redcar.app.call_on_plugins(:tab_added, tab)
      tab
    end
    
    # Moves a tab from another notebook to this notebook.
    #
    # @param [Redcar::Notebook]
    # @param [Redcar::Tab]
    def grab_tab_from(other_notebook, tab)
      return if other_notebook == self
      other_notebook.remove_tab!(tab)
      @tabs << tab
      tab.set_notebook(self)
      notify_listeners(:tab_moved, other_notebook, self, tab)
      attach_tab_listeners(tab)
    end
    
    # Should not be called by user code. Call tab.close instead.
    def remove_tab!(tab)
      @tabs.delete(tab)
      @tab_handlers[tab].each {|h| tab.remove_listener(h) }
      @tab_handlers.delete(tab)
      select_tab!(nil) unless @tabs.any?
    end
    
    # Should not be called by user code. Call tab.focus instead.
    def select_tab!(tab)
      @focussed_tab = tab
      notify_listeners(:tab_focussed, tab)
    end
    
    def sort_tabs!(&block)
      @tabs.sort!(&block)
    end
    
    # Focus the next tab to the right from the currently focussed tab.
    # Wraps.
    def switch_up
      focussed do |current_ix|
        current_ix = wrap_index(current_ix + 1)
        @tabs[current_ix].focus
      end
    end
    
    # Focus the next tab to the left from the currently focussed tab.
    # Wraps.
    def switch_down
      focussed do |current_ix|
        current_ix = wrap_index(current_ix - 1)
        @tabs[current_ix].focus
      end
    end
    
    # Moves the currently focussed tab to the right.
    # Wraps.
    def move_up
      focussed do |current_ix|
        new_ix = wrap_index(current_ix + 1)
        swap_tab_with(@tabs[current_ix], new_ix)
      end
    end
    
    # Moves the currently focussed tab to the left.
    # Wraps.
    def move_down
      focussed do |current_ix|
        new_ix = wrap_index(current_ix - 1)
        swap_tab_with(@tabs[current_ix], new_ix)
      end
    end
    
    # Yields the current index of the foccussed tab, if it exists.
    def focussed(&block)
      current_ix = @tabs.index(@focussed_tab)
      unless current_ix.nil?
        yield(current_ix)
      end
    end
    
    # Swaps a tab with another one at a certain position.
    # If no position is specified, this will default to 0.
    #
    # @param [Redcar::Tab] the tab to be moved
    # @param [Integer] the position
    def swap_tab_with(move_tab, position = 0)
      swap_tab = @tabs[position]
      unless move_tab == swap_tab || [move_tab, swap_tab].include?(nil)
        move_tab.move_to_position(position)
      end
    end
    
    # Wraps an index according to the current number of tabs.
    def wrap_index(index)
      until (0..@tabs.size - 1).include?(index)
        index = index > 0 ? index - @tabs.size : @tabs.size + index
      end
      index
    end
    
    def inspect
      "#<Redcar::Notebook #{object_id}>"
    end
    
    private
    
    def attach_tab_listeners(tab)
      @tab_handlers[tab] << tab.add_listener(:focus) do
        select_tab!(tab)
      end
      @tab_handlers[tab] << tab.add_listener(:close) do
        Redcar.app.call_on_plugins(:tab_closed, tab)
        remove_tab!(tab)
        notify_listeners(:tab_closed)
      end
      @tab_handlers[tab] << tab.add_listener(:changed) do
        if tab == focussed_tab
          notify_listeners(:focussed_tab_changed, tab)
        end
      end
      @tab_handlers[tab] << tab.add_listener(:selection_changed) do
        if tab == focussed_tab
          notify_listeners(:focussed_tab_selection_changed, tab)
        end
      end
    end
  end
end
