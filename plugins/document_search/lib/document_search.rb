require 'strscan'
require "document_search/query_options"
require "document_search/commands"
require "document_search/find_speedbar"
require "document_search/incremental_search_speedbar"

module Redcar
  module DocumentSearch
    def self.menus
      Redcar::Menu::Builder.build do
        sub_menu "Edit" do
          sub_menu "Find", :priority => 50 do
            item "Incremental Search",        OpenIncrementalSearchSpeedbarCommand
            item "Find...",                   OpenFindSpeedbarCommand
            separator
            item "Find Next",                 DoFindNextCommand
            item "Find Previous",             DoFindPreviousCommand
            separator
            item "Replace All",               DoReplaceAllCommand
            item "Replace All in Selection",  DoReplaceAllInSelectionCommand
            item "Replace and Find",          DoReplaceAndFindCommand
            separator
            item "Use Selection for Find",    DoUseSelectionForFindCommand
            item "Use Selection for Replace", DoUseSelectionForReplaceCommand
          end
          separator
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Ctrl+S",      DocumentSearch::OpenIncrementalSearchSpeedbarCommand
        link "Cmd+F",       DocumentSearch::OpenFindSpeedbarCommand
        link "Cmd+G",       DocumentSearch::DoFindNextCommand
        link "Cmd+Shift+G", DocumentSearch::DoFindPreviousCommand
        link "Cmd+Ctrl+F",  DocumentSearch::DoReplaceAllCommand
        link "Cmd+Ctrl+Shift+F",  DocumentSearch::DoReplaceAllInSelectionCommand
        link "Cmd+Alt+F",   DocumentSearch::DoReplaceAndFindCommand
        link "Cmd+E",       DocumentSearch::DoUseSelectionForFindCommand
        link "Cmd+Shift+E", DocumentSearch::DoUseSelectionForReplaceCommand
      end

      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Alt+S",        DocumentSearch::OpenIncrementalSearchSpeedbarCommand
        link "Ctrl+F",       DocumentSearch::OpenFindSpeedbarCommand
        link "Ctrl+G",       DocumentSearch::DoFindNextCommand
        link "Ctrl+Shift+G", DocumentSearch::DoFindPreviousCommand
        link "Ctrl+Alt+F",   DocumentSearch::DoReplaceAndFindCommand
        link "Ctrl+E",       DocumentSearch::DoUseSelectionForFindCommand
        link "Alt+Shift+E",  DocumentSearch::DoUseSelectionForReplaceCommand
      end

      [linwin, osx]
    end

    def self.toolbars
      Redcar::ToolBar::Builder.build do
        item "Find", :command => DocumentSearch::OpenIncrementalSearchSpeedbarCommand, :icon => File.join(Redcar.icons_directory, "magnifier.png"), :barname => :edit
        item "Find Next", :command => DocumentSearch::DoFindNextCommand, :icon => File.join(Redcar.icons_directory, "magnifier--arrow.png"), :barname => :edit
      end
    end

    class OpenIncrementalSearchSpeedbarCommand < Redcar::EditTabCommand
      def execute
        already_open = win.speedbar.is_a? IncrementalSearchSpeedbar
        @speedbar = IncrementalSearchSpeedbar.new
        unless already_open
          # Clear out previous query for new speedbar.
          IncrementalSearchSpeedbar.previous_query = ''
          win.open_speedbar(@speedbar)
        else
          # If already open, find next match.
          win.open_speedbar(@speedbar)
          IncrementalSearchSpeedbar.find_next
        end
      end
    end

    class OpenFindSpeedbarCommand < Redcar::EditTabCommand
      def execute
        @speedbar = FindSpeedbar.new
        if doc.selection?
          @speedbar.initial_query = doc.selected_text
        end
        win.open_speedbar(@speedbar)
      end
    end

    class DoFindNextCommand < Redcar::EditTabCommand
      def execute
        if win.speedbar.is_a? IncrementalSearchSpeedbar
          IncrementalSearchSpeedbar.find_next
        else
          FindSpeedbar.find_next
        end
      end
    end

    class DoFindPreviousCommand < Redcar::EditTabCommand
      def execute
        if win.speedbar.is_a? IncrementalSearchSpeedbar
          IncrementalSearchSpeedbar.find_previous
        else
          FindSpeedbar.find_previous
        end
      end
    end

    class DoReplaceAndFindCommand < Redcar::EditTabCommand
      def execute
        FindSpeedbar.replace_and_find(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options)
      end
    end

    class DoReplaceAllCommand < Redcar::EditTabCommand
      def execute
        FindSpeedbar.replace_all(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options)
      end
    end

    class DoReplaceAllInSelectionCommand < Redcar::EditTabCommand
      def execute
        FindSpeedbar.replace_all_in_selection(
            FindSpeedbar.previous_query,
            FindSpeedbar.previous_replace,
            FindSpeedbar.previous_options)
      end
    end

    class DoUseSelectionForFindCommand  < Redcar::EditTabCommand
      def execute
        FindSpeedbar.use_selection_for_find(doc, win.speedbar)
      end
    end

    class DoUseSelectionForReplaceCommand  < Redcar::EditTabCommand
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
end
