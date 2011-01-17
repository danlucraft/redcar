require 'strscan'
require "document_search/query_options"
require "document_search/commands"
require "document_search/find_speedbar"
require "document_search/find_and_replace_speedbar"

module DocumentSearch
  def self.menus
    Redcar::Menu::Builder.build do
      sub_menu "Edit" do
        sub_menu "Find", :priority => 50 do
          item "Find", :command => FindMenuCommand
          item "Find and Replace", :command => FindAndReplaceMenuCommand
          separator
          item "Next Result", FindNextMenuCommand
          item "Previous Result", FindPreviousMenuCommand
          separator
          item "Use Selection for Find", UseSelectionForFindMenuCommand
          item "Use Selection for Replace", UseSelectionForReplaceMenuCommand
        end
        separator
      end
    end
  end

  def self.toolbars
    Redcar::ToolBar::Builder.build do
      item "Find", :command => DocumentSearch::FindMenuCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier.png"), :barname => :edit
      item "Find Next", :command => DocumentSearch::FindNextMenuCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier--arrow.png"), :barname => :edit
    end
  end

  class FindMenuCommand < Redcar::EditTabCommand
    def execute
      @speedbar = FindSpeedbar.new
      if doc.selection?
        @speedbar.initial_query = doc.selected_text
      end
      win.open_speedbar(@speedbar)
    end
  end

  class FindAndReplaceMenuCommand < Redcar::EditTabCommand
    def execute
      @speedbar = FindAndReplaceSpeedbar.new
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

  class UseSelectionForFindMenuCommand  < Redcar::EditTabCommand
    def execute
      FindSpeedbar.use_selection_for_find(doc, win.speedbar)
    end
  end

  class UseSelectionForReplaceMenuCommand  < Redcar::EditTabCommand
    def execute
      FindAndReplaceSpeedbar.use_selection_for_replace(doc, win.speedbar)
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
