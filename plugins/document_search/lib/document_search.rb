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
          item "Find", :command => FindCommand, :priority => 1
          item "Find and Replace", :command => FindAndReplaceCommand, :priority => 2
          separator
          item "Next Result", RepeatFindNextCommand
          item "Previous Result", RepeatFindPreviousCommand
        end
        separator
      end
    end
  end

  def self.toolbars
    Redcar::ToolBar::Builder.build do
      item "Search Document", :command => DocumentSearch::FindCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier.png"), :barname => :edit
      item "Next Search Result", :command => DocumentSearch::RepeatFindNextCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "magnifier--arrow.png"), :barname => :edit
    end
  end

  class FindCommand < Redcar::EditTabCommand
    def execute
      @speedbar = FindSpeedbar.new
      if doc.selection?
        @speedbar.initial_query = doc.selected_text
      end
      win.open_speedbar(@speedbar)
    end
  end

  class FindAndReplaceCommand < Redcar::EditTabCommand
    def execute
      @speedbar = FindAndReplaceSpeedbar.new
      if doc.selection?
        @speedbar.initial_query = doc.selected_text
      end
      win.open_speedbar(@speedbar)
    end
  end

  class RepeatFindNextCommand < Redcar::EditTabCommand
    def execute
      FindAndReplaceSpeedbar.repeat_find_next
    end
  end

  class RepeatFindPreviousCommand < Redcar::EditTabCommand
    def execute
      FindAndReplaceSpeedbar.repeat_find_previous
    end
  end

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
