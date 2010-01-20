
module Redcar
  module Top
    class NewCommand < Command
      key :osx     => "Cmd+N",
          :linux   => "Ctrl+N",
          :windows => "Ctrl+N"
      
      def execute
        tab = win.new_tab(Redcar::EditTab)
        tab.title = "untitled"
        tab.focus
        tab
      end
    end
    
    class NewNotebookCommand < Command
      sensitize :single_notebook
      
      key :osx     => "Cmd+Alt+N",
          :linux   => "Ctrl+Alt+N",
          :windows => "Ctrl+Alt+N"

      def execute
        unless win.notebooks.length > 1
          win.create_notebook
        end
      end
    end
    
    class NewWindowCommand < Command
      
      def initialize(title=nil)
        @title = title
      end
      
      def execute
        window = Redcar.app.new_window
        window.title = @title if @title
      end
    end
    
    class CloseWindowCommand < Command
      def initialize(window=nil)
        @window = window
      end
    
      def execute
        (@window||win).close
      end
    end
    
    class RotateNotebooksCommand < Command
      sensitize :multiple_notebooks
          
      def execute
        win.rotate_notebooks
      end
    end
    
    class CloseNotebookCommand < Command
      sensitize :multiple_notebooks
          
      def execute
        unless win.notebooks.length == 1
          win.close_notebook
        end
      end
    end
    
    class SwitchNotebookCommand < Command
      sensitize :multiple_notebooks, :other_notebook_has_tab
      key :osx     => "Cmd+Alt+O",  
          :linux   => "Ctrl+Alt+O",
          :windows => "Ctrl+Alt+O"
          
      def execute
        new_notebook = win.nonfocussed_notebook
        if new_notebook.focussed_tab
          new_notebook.focussed_tab.focus
        end
      end
    end
    
    class MoveTabToOtherNotebookCommand < Command
      sensitize :multiple_notebooks, :open_tab
          
      key :osx     => "Cmd+Shift+Alt+O",  
          :linux   => "Ctrl+Shift+Alt+O",
          :windows => "Ctrl+Shift+Alt+O"

      def execute
        current_notebook = tab.notebook
        target_notebook = win.notebooks.detect {|nb| nb != current_notebook}
        target_notebook.grab_tab_from(current_notebook, tab)
        tab.focus
      end
    end

    class PrintContents < EditTabCommand
      key "Cmd+P"
      
      def execute
        puts "printing contents"
        p tab.edit_view.document.to_s
      end
    end
    
    class PrintHistoryCommand < Command
      def execute
        Redcar.history.each do |c|
          puts c
        end
      end
    end
    
    class PrintScopeTreeCommand < Command
      def execute
        puts tab.edit_view.controller.mate_text.parser.root.pretty(0)
      end
    end

    class CloseTabCommand < TabCommand
      key :osx     => "Cmd+W",
          :linux   => "Ctrl+W",
          :windows => "Ctrl+W"
      
      def execute
        # TODO: should be win.focussed_notebook
        if tab = win.focussed_notebook.focussed_tab
          tab.close
        end
      end
    end
    
    class ListTabsCommand < Command
      def execute
        p win.focussed_notebook.tabs.map {|tab| tab.class}
      end
    end
    
    class SwitchTabDownCommand < Command
      key :osx     => "Cmd+Shift+[",
          :linux   => "Ctrl+Shift+[",
          :windows => "Ctrl+Shift+["
       
      def execute
        win.focussed_notebook.switch_down
      end
    end
    
    class SwitchTabUpCommand < Command
      key :osx     => "Cmd+Shift+]",
          :linux   => "Ctrl+Shift+]",
          :windows => "Ctrl+Shift+]"
       
      def execute
        win.focussed_notebook.switch_up
      end
    end
    
    class UndoCommand < EditTabCommand
      sensitize :undoable
      
      key :osx     => "Cmd+Z",
          :linux   => "Ctrl+Z",
          :windows => "Ctrl+Z"
      
      def execute
        tab.edit_view.undo
      end
    end
    
    class RedoCommand < EditTabCommand
      sensitize :redoable
      
      key :osx     => "Cmd+Shift+Z",
          :linux   => "Ctrl+Shift+Z",
          :windows => "Ctrl+Shift+Z"
      
      def execute
        tab.edit_view.redo
      end
    end
    
    class MoveHomeCommand < EditTabCommand
      key "Ctrl+A"
      
      def execute
        doc = tab.edit_view.document
        line_ix = doc.line_at_offset(doc.cursor_offset)
        doc.cursor_offset = doc.offset_at_line(line_ix)
      end
    end
    
    class MoveEndCommand < EditTabCommand
      key "Ctrl+E"
      
      def execute
        doc = tab.edit_view.document
        line_ix = doc.line_at_offset(doc.cursor_offset)
        if line_ix == doc.line_count - 1
          doc.cursor_offset = doc.length
        else
          doc.cursor_offset = doc.offset_at_line(line_ix + 1) - 1
        end
      end
    end
    
    class ChangeIndentCommand < EditTabCommand
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          if doc.selection_range.end == doc.offset_at_line(last_line_ix)
            last_line_ix -= 1
          end
          first_line_ix.upto(last_line_ix) do |line_ix|
            indent_line(doc, line_ix)
          end
          start_selection = doc.offset_at_line(first_line_ix)
          if last_line_ix == doc.line_count - 1
            end_selection = doc.length
          else
            end_selection = doc.offset_at_line(last_line_ix + 1)
          end
          doc.set_selection_range(start_selection..end_selection)
        else
          indent_line(doc, doc.cursor_line)
        end
      end
    end
    
    class DecreaseIndentCommand < ChangeIndentCommand
      key :osx     => "Cmd+[",
          :linux   => "Ctrl+[",
          :windows => "Ctrl+["
      
      def indent_line(doc, line_ix)
        use_spaces = true
        num_spaces = 2
        line = doc.get_line(line_ix)
        if line[0..0] == "\t"
          line_start = doc.offset_at_line(line_ix)
          to         = line_start + 1
        elsif line[0...num_spaces] == " "*num_spaces
          line_start = doc.offset_at_line(line_ix)
          to         = line_start + num_spaces
        end
        doc.delete(line_start, to - line_start) unless line_start == to
      end
    end

    class IncreaseIndentCommand < ChangeIndentCommand
      key :osx     => "Cmd+]",
          :linux   => "Ctrl+]",
          :windows => "Ctrl+]"
      
      def indent_line(doc, line_ix)
        line            = doc.get_line(line_ix)
        whitespace_type = line[/^(  |\t)/, 1] || "  "
        doc.insert(doc.offset_at_line(line_ix), whitespace_type)
      end
    end

    class StripWhitespaceCommand < Redcar::EditTabCommand
    
      def execute
        0.upto(doc.line_count - 1) do |line_ix|
          doc.replace_line(line_ix) {|line| line.strip }
        end
      end
    end
    
    class SelectAllCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+A",
          :linux   => "Ctrl+Shift+A",
          :windows => "Ctrl+Shift+A"
    
      def execute
        doc.set_selection_range(0..(doc.length))
      end
    end
    
    class SelectLineCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+Shift+L",
          :linux   => "Ctrl+Shift+L",
          :windows => "Ctrl+Shift+L"
    
      def execute
        doc.set_selection_range(
          doc.cursor_line_start_offset..doc.cursor_line_end_offset)
      end
    end
    
    class CutCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+X",
          :linux   => "Ctrl+X",
          :windows => "Ctrl+X"
    
      def execute
        if doc.selection?
          text = doc.selection_ranges.map do |range|
            doc.get_range(range.begin, range.count)
          end
          p text
          Redcar.app.clipboard << text
          diff = 0
          doc.selection_ranges.each do |range|
            doc.delete(range.begin - diff, range.count)
            diff += range.count
          end
        else
          Redcar.app.clipboard << doc.get_line(doc.cursor_line)
          doc.delete(doc.cursor_line_start_offset, 
                     doc.cursor_line_end_offset - doc.cursor_line_start_offset)
        end
      end
    end
    
    class CopyCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+C",
          :linux   => "Ctrl+C",
          :windows => "Ctrl+C"
    
      def execute
        if doc.selection?
          text = doc.selection_ranges.map do |range|
            doc.get_range(range.begin, range.count)
          end
          Redcar.app.clipboard << text
        else
          Redcar.app.clipboard << doc.get_line(doc.cursor_line)
        end
      end
    end
    
    class PasteCommand < Redcar::EditTabCommand
      sensitize :clipboard_not_empty
      
      key :osx     => "Cmd+V",
          :linux   => "Ctrl+V",
          :windows => "Ctrl+V"
    
      def execute
        start_offset = doc.selection_ranges.first.begin
        start_line   = doc.line_at_offset(start_offset)
        line_offset  = start_offset - doc.offset_at_line(start_line)
        cursor_line  = doc.cursor_line
        cursor_line_offset = doc.cursor_line_offset
        diff = 0
        doc.selection_ranges.each do |range|
          doc.delete(range.begin - diff, range.count)
          diff += range.count
        end
        texts = Redcar.app.clipboard.last.dup
        texts.each_with_index do |text, i|
          line_ix = start_line + i
          if line_ix == doc.line_count
            doc.insert(doc.length, "\n" + " "*line_offset)
          else
            line = doc.get_line(line_ix)
            if line.length - 1 < line_offset
              doc.insert(
                doc.offset_at_inner_end_of_line(line_ix),
                " "*(line_offset - line.length + 1)
              )
            end
          end
          doc.insert(
            doc.offset_at_line(line_ix) + line_offset,
            text
          )
        end
        new_offset = doc.offset_at_line(cursor_line) + cursor_line_offset + Redcar.app.clipboard.last.first.length
        doc.cursor_offset = new_offset
      end
    end
    
    class DialogExample < Redcar::Command
      def execute
      	builder = Menu::Builder.new do
      	  item("Foo") { p :foo }
      	  item("Bar") { p :bar }
      	  separator
      	  sub_menu "Baz" do
      	    item("Qux") { p :qx}
      	    item("Quux") { p :quux }
      	    item("Corge") { p :corge }
      	  end
      	end
      	win.popup_menu(builder.menu)
      end
    end
    
    class GotoLineCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+L",
          :linux   => "Ctrl+L",
          :windows => "Ctrl+L"
      
      class Speedbar < Redcar::Speedbar
        label "Goto line:"
        textbox :line
        button :go, "Return" do
          doc.scroll_to_line(@speedbar.line.to_i - 1)
          win.close_speedbar
        end
      end
      
      def execute
        @speedbar = GotoLineCommand::Speedbar.new(self)
        win.open_speedbar(@speedbar)
      end
    end
    
    class SearchForwardCommand < Redcar::EditTabCommand
      key :osx => "Cmd+F", :linux => "Ctrl+F", :windows => "Ctrl+F"
      
      class Speedbar < Redcar::Speedbar
        label "Regex"
        textbox :query
        button :search, "Return" do
          FindNextRegex.new(Regexp.new(@speedbar.query), false).run
        end
      end
      
      def execute
        @speedbar = SearchForwardCommand::Speedbar.new(self)
        win.open_speedbar(@speedbar)
      end
    end
    
    class FindNextRegex < Redcar::EditTabCommand
      def initialize(re, wrap=nil)
        @re = re
        @wrap = wrap
      end
  
      def to_s
        "<#{self.class}: @re:#{@re.inspect} wrap:#{!!@wrap}>"
      end
  
      def execute
        # first search the remainder of the current line
        curr_line = doc.get_line(doc.cursor_line)
        cursor_line_offset = doc.cursor_offset - doc.offset_at_line(doc.cursor_line)
        curr_line = curr_line[cursor_line_offset..-1]
        if curr_line =~ @re
          line_start = doc.offset_at_line(doc.cursor_line)
          startoff = line_start + $`.length + cursor_line_offset
          endoff   = startoff + $&.length
          doc.set_selection_range(startoff..endoff)
        else
          # next search the rest of the lines
          line_num = doc.cursor_line + 1
          curr_line = doc.get_line(line_num)
          until line_num == doc.line_count - 1 or 
                found = (curr_line.to_s =~ @re)
            line_num += 1
            curr_line = doc.get_line(line_num)
          end
          if found
            line_start = doc.offset_at_line(line_num)
            startoff = line_start + $`.length
            endoff   = startoff + $&.length
            doc.set_selection_range(startoff..endoff)
            doc.scroll_to_line(line_num)
          end
          if !doc.get_line(line_num) and @wrap
            doc.cursor_offset = 0
            execute
          end
        end
      end
    end
    
    class ToggleBlockSelectionCommand < Redcar::EditTabCommand
      key :osx     => "Cmd+B",
          :windows => "Ctrl+B",
          :linux   => "Ctrl+B"
      
      def execute
        doc.block_selection_mode = !doc.block_selection_mode?
      end
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "File" do
          item "New", NewCommand
          item "New Notebook", NewNotebookCommand
          item "New Window", NewWindowCommand
          item "Open", Project::FileOpenCommand
          item "Open Directory", Project::DirectoryOpenCommand
          separator
          item "Save", Project::FileSaveCommand
          item "Save As", Project::FileSaveAsCommand
          separator
          item "Close Tab", CloseTabCommand
          item "Close Notebook", CloseNotebookCommand
          item "Close Window", CloseWindowCommand
          item "Close Directory", Project::DirectoryCloseCommand
        end
        sub_menu "Edit" do
          item "Undo", UndoCommand
          item "Redo", RedoCommand
          separator
          item "Cut", CutCommand
          item "Copy", CopyCommand
          item "Paste", PasteCommand
          separator
          item "Home", MoveHomeCommand
          item "End", MoveEndCommand
          separator
          item "Increase Indent", IncreaseIndentCommand
          item "Decrease Indent", DecreaseIndentCommand
          separator
          item "Strip Whitespace", StripWhitespaceCommand
          separator
          item "Goto Line", GotoLineCommand
          item "Regex Search",    SearchForwardCommand
          separator
          sub_menu "Select" do
            item "All", SelectAllCommand
            item "Line", SelectLineCommand
          end
          item "Toggle Block Selection", ToggleBlockSelectionCommand
          item "Auto Complete", AutoCompleter::AutoCompleteCommand
        end
        sub_menu "Project" do
          item "Find File", Project::FindFileCommand
        end
        sub_menu "Debug" do
          item "Print Command History", PrintHistoryCommand
          item "Print Contents", PrintContents
          item "List Tabs", ListTabsCommand
          item "Print Scope Tree", PrintScopeTreeCommand
          item "Refresh Directory", Project::RefreshDirectoryCommand
          item "Dialog Tester", DialogExample
        end
        sub_menu "View" do
          item "Rotate Notebooks", RotateNotebooksCommand
          item "Move Tab To Other Notebook", MoveTabToOtherNotebookCommand
          item "Switch Notebooks", SwitchNotebookCommand
          separator
          item "Previous Tab", SwitchTabDownCommand
          item "Next Tab", SwitchTabUpCommand
        end
        sub_menu "Plugins" do
          item "Plugin Manager", PluginManagerUi::OpenCommand
          separator
        end
        sub_menu "Help" do
          item "Website", PrintHistoryCommand
        end
      end
    end
    
    def self.start
      Application.start
      ApplicationSWT.start
      AutoIndenter.start
      EditViewSWT.start
      AutoCompleter.start
      Redcar.gui = ApplicationSWT.gui
      Redcar.app.controller = ApplicationSWT.new(Redcar.app)
      
      Redcar.app.load_menus
      Redcar.app.load_sensitivities
      Redcar.app.new_window
    end
  end
end
