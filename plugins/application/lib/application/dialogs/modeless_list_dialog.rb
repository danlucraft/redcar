
module Redcar
  # A type of dialog for displaying a list inside a tab. Example uses include
  # selection dialogs for code completion or dynamically opening files based on
  # tab content.
  # Modeless List dialogs can also add sub-lists, by implementing the 'previous_list'
  # and/or 'next_list' methods, which are called when a ARROW_LEFT or ARROW_RIGHT
  # key event is generated.
  #
  # Subclasses should implement the 'selected' method,
  # and optionally 'previous_list' and 'next_list' if applicable.
  class ModelessListDialog
    include Redcar::Model
    include Redcar::Observable

    def initialize(close_on_lost_focus=true)
      @close_on_lost_focus = close_on_lost_focus
      self.controller = Redcar.gui.controller_for(self).new(self)
    end

    # Set the size of the list dialog. The width is measured in pixels
    # and the height in rows of text
    def set_size(width,height)
      notify_listeners(:set_size, width,height)
    end
    # Set the location of the list dialog relative to an offset in a tab
    def set_location(offset)
      notify_listeners(:set_location,offset)
    end

    def open
      notify_listeners(:open)
    end

    def close
      notify_listeners(:close)
    end

    # Whether to close the list dialog when focus is lost
    def close_on_lost_focus
      @close_on_lost_focus
    end

    # Get a 'previous' list, where applicable, based on the
    # currently selected item in the list
    #
    # @return [Array<String>] list items
    def previous_list
    end

    # Get a 'next' list, where applicable, based on the
    # currently selected item in the list
    #
    # @return [Array<String>] list items
    def next_list
    end

    # Update the items in the dialog list
    #
    # @param [Array<String>] items
    def update_list(items)
      notify_listeners :update_list, items
    end

    # Do an action, based on the index of the selected item
    def selected(index)
      p "'#{select(index)}' (at index #{index}) was selected!"
      close
    end

    # Get the text of an item at an index
    #
    # @return [String]
    def select(index)
      self.controller.select index
    end

    # The index of the currently selected text
    #
    # @return [Integer]
    def selection_index
      self.controller.selection_index
    end
  end
end