require 'strscan'
require "document_search/query_options"
require "document_search/commands"
require "document_search/find_speedbar"
require "document_search/incremental_search_speedbar"

module DocumentSearch
  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Edit" do
        sub_menu "Find", :priority => 50 do
          item "Incremental Search",        IncrementalSearchSpeedbarCommand
          item "Find...",                   FindSpeedbarCommand
          separator
          item "Find Next",                 FindNextMenuCommand
          item "Find Previous",             FindPreviousMenuCommand
          item "Replace and Find",          ReplaceAndFindMenuCommand
          separator
          item "Use Selection for Find",    UseSelectionForFindMenuCommand
          item "Use Selection for Replace", UseSelectionForReplaceMenuCommand
        end
        separator
      end
    end
  end

  def self.keymaps
    osx = Redcar::Keymap.build("main", :osx) do
      link "Ctrl+S",      DocumentSearch::IncrementalSearchSpeedbarCommand
      link "Cmd+F",       DocumentSearch::FindSpeedbarCommand
      link "Cmd+G",       DocumentSearch::FindNextMenuCommand
      link "Cmd+Shift+G", DocumentSearch::FindPreviousMenuCommand
      link "Cmd+Alt+F",   DocumentSearch::ReplaceAndFindMenuCommand
      link "Cmd+E",       DocumentSearch::UseSelectionForFindMenuCommand
      link "Cmd+Shift+E", DocumentSearch::UseSelectionForReplaceMenuCommand
    end

    linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
      link "Alt+S",        DocumentSearch::IncrementalSearchSpeedbarCommand
      link "Ctrl+F",       DocumentSearch::FindSpeedbarCommand
      link "Ctrl+G",       DocumentSearch::FindNextMenuCommand
      link "Ctrl+Shift+G", DocumentSearch::FindPreviousMenuCommand
      link "Ctrl+E",       DocumentSearch::UseSelectionForFindMenuCommand
      link "Alt+E",        DocumentSearch::UseSelectionForReplaceMenuCommand
    end

    [linwin, osx]
  end

  def self.toolbars
    # TODO(yozhipozhi): What should be on the toolbar?
    Redcar::ToolBar::Builder.build do
      item "Find", 
          :command => DocumentSearch::IncrementalSearchMenuCommand, 
          :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier.png"), 
          :barname => :edit
      item "Find Next", :command => DocumentSearch::FindNextMenuCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier--arrow.png"), :barname => :edit
    end
  end

  class IncrementalSearchSpeedbarCommand < Redcar::EditTabCommand
    def execute
      already_open = win.speedbar && (win.speedbar.is_a? IncrementalSearchSpeedbar)
      @speedbar = IncrementalSearchSpeedbar.new
      win.open_speedbar(@speedbar)
      if already_open
        IncrementalSearchSpeedbar.find_next
      end
    end
  end

  class FindSpeedbarCommand < Redcar::EditTabCommand
    def execute
      @speedbar = FindSpeedbar.new
      if doc.selection?
        @speedbar.initial_query = doc.selected_text
      end
      win.open_speedbar(@speedbar)
    end
  end

  class FindNextMenuCommand < Redcar::EditTabCommand
    def execute
      FindSpeedbar.find_next
    end
  end

  class FindPreviousMenuCommand < Redcar::EditTabCommand
    def execute
      FindSpeedbar.find_previous
    end
  end

  class ReplaceAndFindMenuCommand < Redcar::EditTabCommand
    def execute
      FindSpeedbar.replace_and_find(
        FindSpeedbar.previous_query,
        FindSpeedbar.previous_replace,
        FindSpeedbar.previous_options)
    end
  end

  class UseSelectionForFindMenuCommand  < Redcar::EditTabCommand
    def execute
      FindSpeedbar.use_selection_for_find(doc, win.speedbar)
    end
  end

  class UseSelectionForReplaceMenuCommand  < Redcar::EditTabCommand
    def execute
      FindSpeedbar.use_selection_for_replace(doc, win.speedbar)
    end
  end

  # TODO(yozhipozhi): Figure out if this is still needed.
  class FindNextRegex < Redcar::DocumentCommand
    def initialize(re, wrap=nil)
      @re = re
      @wrap = wrap
    end

    def to_s
      "<#{self.class}: @re:#{@re.inspect} wrap:#{!!@wrap}>"
    end

    def execute
      position = doc.cursor_offset
      sc       = StringScanner.new(doc.get_all_text)
      sc.pos   = position
      sc.scan_until(@re)

      if @wrap and !sc.matched?
        # No match was found in the remainder of the document, search from beginning
        sc.reset
        sc.scan_until(@re)
      end

      if sc.matched?
        endoff   = sc.pos
        startoff = sc.pos - sc.matched_size
        line     = doc.line_at_offset(startoff)
        lineoff  = startoff - doc.offset_at_line(line)
        if lineoff < doc.smallest_visible_horizontal_index
          horiz = lineoff
        else
          horiz = endoff - doc.offset_at_line(line)
        end
        doc.set_selection_range(sc.pos, sc.pos - sc.matched_size)
        doc.scroll_to_line(line)
        doc.scroll_to_horizontal_offset(horiz) if horiz
        return true
      end
      false
    end
  end
end
