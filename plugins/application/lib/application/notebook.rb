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
      select_tab!(nil) unless @tabs.any?
    end
    
    # Should not be called by user code. Call tab.focus instead.
    def select_tab!(tab)
      @focussed_tab = tab
      notify_listeners(:tab_focussed, tab)
    end
    
    def sort_tabs!(&block)
      @tabs.sort! &block
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
        new_index = wrap_index(current_ix + 1)
        swap_tab_with(@tabs[current_ix], new_index)
      end
    end
    
    # Moves the currently focussed tab to the left.
    # Wraps.
    def move_down
      focussed do |current_ix|
        new_index = wrap_index(current_ix - 1)
        swap_tab_with(@tabs[current_ix], new_index)
      end
    end
    
    # Yields the current index of the foccussed tab, if it exists.
    def focussed(&block)
      current_ix = @tabs.index(@focussed_tab)
      unless current_ix.nil?
        yield(current_ix)
      end
    end
    
    # Swaps a tab with another one at a given position.
    def swap_tab_with(tab_to_move, position = 0)
      tab_to_swap = @tabs[position]
      unless tab_to_move == tab_to_swap ||
        [tab_to_move, tab_to_swap].include?(nil)
        tab_to_move.move_to_position(position)
      end
    end
    
    # Wraps an index according to the current number of tabs.
    def wrap_index(position)
      until (0..@tabs.size - 1).include?(position)
        position = position > 0 ? position - @tabs.size : @tabs.size + position
      end
      position
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
