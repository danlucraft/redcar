module Redcar
  class Tab
    include Redcar::Model
    include Redcar::Observable

    DEFAULT_ICON  = :document
    NO_WRITE_ICON = :exclamation_red
    MISSING_ICON  = :exclamation
    CONFIG_ICON   = :hammer_screwdriver
    HELP_ICON     = :question
    WEB_ICON      = :globe

    attr_reader :notebook

    def initialize(notebook)
      @notebook = notebook
      @title    = "unknown"
    end

    # Close the tab (remove it from the Notebook).
    #
    # Events: close
    def close
      Redcar.app.events.ignore(:tab_close, self) do
        notify_listeners(:close)
      end
    end

    # Focus the tab within the notebook, and gives the keyboard focus to the
    # contents of the tab, if appropriate.
    #
    # Events: focus
    def focus
      Redcar.app.events.ignore(:tab_focus, self) do
        notify_listeners(:focus)
      end
    end

    def title
      @title
    end

    def title=(title)
      @title = title
      notify_listeners(:changed_title, title)
    end

    def icon
      @icon || DEFAULT_ICON
    end

    def icon=(value)
      @icon = value
      notify_listeners(:changed_icon, icon)
    end

    def inspect
      "#<#{self.class.name} \"#{title}\">"
    end

    # Sets the notebook of the tab. Should not be called from user code.
    def set_notebook(notebook)
      @notebook = notebook
    end

    # Moves the tab to a new position in the notebook, if said position
    # is currently occupied. Defaults to the first position, if none
    # is passed.
    #
    # Events: moved (position)
    def move_to_position(position = 0)
      if (0..@notebook.tabs.size - 1).include?(position)
        notify_listeners(:moved, position)
      end
    end

    def edit_tab?
      is_a?(EditTab)
    end

    # Helper method to get the edit_view's document, if applicable.
    def document
      edit_view.document if edit_tab?
    end

    # Helper method to get this tab's Mirror object for the current
    # document, if applicable.
    def document_mirror
      document.mirror if document
    end
  end
end
