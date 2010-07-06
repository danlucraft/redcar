
module Redcar
  def self.safely(text=nil)
    if text == nil
      text = caller[1]
    end
    begin
      yield
    rescue => e
      message = "Error in: " + text
      Application::Dialog.message_box(
        message,
        :type => :error, :buttons => :ok)
      puts message
      puts e.class.to_s + ": " + e.message
      puts e.backtrace
    end
  end
  
  def self.update_gui
    ApplicationSWT.sync_exec do
      safely do
        yield
      end
    end
  end
  
  module Top
    class QuitCommand < Command
      
      def execute
        EditView::ModifiedTabsChecker.new(
          Redcar.app.all_tabs.select {|t| t.is_a?(EditTab)},
          "Save all before quitting?",
          :none     => lambda { Redcar.app.quit },
          :continue => lambda { Redcar.app.quit },
          :cancel   => nil
        ).check
      end
    end
    
    class NewCommand < Command
      
      def execute
        tab = win.new_tab(Redcar::EditTab)
        tab.title = "untitled"
        tab.focus
        tab
      end
    end
    
    class NewNotebookCommand < Command
      sensitize :single_notebook
      
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
        check_for_modified_tabs_and_close_window
        quit_if_no_windows if [:linux, :windows].include?(Redcar.platform)
        @window = nil
      end
      
      private
      
      def quit_if_no_windows
        if Redcar.app.windows.length == 0
          if Application.storage['stay_resident_after_last_window_closed'] && !(ARGV.include?("--multiple-instance"))
            puts 'continuing to run to wait for incoming drb connections later'
          else
            QuitCommand.new.run
          end
        end
      end
      
      def check_for_modified_tabs_and_close_window
        EditView::ModifiedTabsChecker.new(
          win.notebooks.map(&:tabs).flatten.select {|t| t.is_a?(EditTab)}, 
          "Save all before closing the window?",
          :none     => lambda { win.close },
          :continue => lambda { win.close },
          :cancel   => nil
        ).check
      end
      
      def win
        @window || super
      end
    end
    
    class FocusWindowCommand < Command
      def initialize(window=nil)
        @window = window
      end
    
      def execute
        win.focus
        @window = nil
      end
      
      def win
        @window || super
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
          
      def execute
        new_notebook = win.nonfocussed_notebook
        if new_notebook.focussed_tab
          new_notebook.focussed_tab.focus
        end
      end
    end
    
    class MoveTabToOtherNotebookCommand < Command
      sensitize :multiple_notebooks, :open_tab
          
      def execute
        current_notebook = tab.notebook
        target_notebook = win.notebooks.detect {|nb| nb != current_notebook}
        target_notebook.grab_tab_from(current_notebook, tab)
        tab.focus
      end
    end
    
    class CloseTreeCommand < Command
      def execute
        treebook = Redcar.app.focussed_window.treebook
        tree = treebook.focussed_tree
        treebook.remove_tree(tree)
      end
    end
    
    class AboutCommand < Command
      def execute
        new_tab = Top::NewCommand.new.run          
        new_tab.document.text = "About: Redcar\nVersion: #{Redcar::VERSION}\n" +
          "Ruby Version: #{RUBY_VERSION}\n" + 
          "Jruby version: #{JRUBY_VERSION}\n" + 
          "Redcar.environment: #{Redcar.environment}\n" + 
          "http://redcareditor.com"
        new_tab.title= 'About'
        new_tab.edit_view.reset_undo
        new_tab.document.set_modified(false)
      end
    end

    class ChangelogCommand < Command
      def execute
        new_tab = Top::NewCommand.new.run          
        new_tab.document.text = File.read(File.join(File.dirname(__FILE__), "..", "..", "CHANGES"))
        new_tab.title = 'Changes'
        new_tab.edit_view.reset_undo
        new_tab.edit_view.document.set_modified(false)
      end
    end

    class PrintScopeTreeCommand < Command
      def execute
        puts tab.edit_view.controller.mate_text.parser.root.pretty(0)
      end
    end

    class PrintScopeCommand < Command
      def execute
        Application::Dialog.tool_tip(tab.edit_view.document.cursor_scope.gsub(" ", "\n"), :cursor)
      end
    end
    
    class CloseTabCommand < TabCommand
      def initialize(tab=nil)
        @tab = tab
      end
      
      def tab
        @tab || super
      end
      
      def execute
        if tab.is_a?(EditTab)
          if tab.edit_view.document.modified?
            result = Application::Dialog.message_box(
              "This tab has unsaved changes. \n\nSave before closing?",
              :buttons => :yes_no_cancel
            )
            case result
            when :yes
              tab.edit_view.document.save!
              close_tab
            when :no
              close_tab
            when :cancel
            end
          else
            close_tab
          end
        else
          close_tab
        end
        @tab = nil
      end
      
      private
      
      def close_tab
        win = tab.notebook.window
        tab.close
        # this will break a lot of features:
        #if win.all_tabs.empty? and not Project::Manager.in_window(win)
        #  win.close
        #end
      end
    end
    
    class SwitchTabDownCommand < Command
       
      def execute
        win.focussed_notebook.switch_down
      end
    end
    
    class SwitchTabUpCommand < Command
       
      def execute
        win.focussed_notebook.switch_up
      end
    end
    
    class UndoCommand < EditTabCommand
      sensitize :undoable
      
      def execute
        tab.edit_view.undo
      end
    end
    
    class RedoCommand < EditTabCommand
      sensitize :redoable
      
      def execute
        tab.edit_view.redo
      end
    end
    
    class MoveHomeCommand < EditTabCommand
      
      def execute
        doc     = tab.edit_view.document
        line_ix = doc.line_at_offset(doc.cursor_offset)
        line    = doc.get_line(line_ix)
        prefix  = line[0...doc.cursor_line_offset]
        
        if prefix =~ /^\s*$/
          # move to start of line
          new_offset = doc.offset_at_line(line_ix)
        else
          # move to start of text
          new_offset = doc.offset_at_line(line_ix)
          prefix =~ /^(\s*)[^\s].*$/
          whitespace_prefix_length = $1 ? $1.length : 0
          new_offset += whitespace_prefix_length
        end
        doc.cursor_offset = new_offset
        doc.ensure_visible(doc.cursor_offset)
      end
    end
    
    class MoveTopCommand < EditTabCommand
      
      def execute
        doc = tab.edit_view.document
        doc.cursor_offset = 0
        doc.ensure_visible(0)
      end
    end
    
    class MoveEndCommand < EditTabCommand
      
      def execute
        doc = tab.edit_view.document
        line_ix = doc.line_at_offset(doc.cursor_offset)
        if line_ix == doc.line_count - 1
          doc.cursor_offset = doc.length
        else
          doc.cursor_offset = doc.offset_at_line(line_ix + 1) - doc.delim.length
        end
        doc.ensure_visible(doc.cursor_offset)
      end
    end
    
    class MoveBottomCommand < EditTabCommand
      
      def execute
        doc = tab.edit_view.document
        doc.cursor_offset = doc.length
        doc.ensure_visible(doc.length)
      end
    end
    
    class ChangeIndentCommand < EditTabCommand
      def execute
        doc = tab.edit_view.document
        doc.compound do
          doc.edit_view.delay_parsing do
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
              doc.set_selection_range(start_selection, end_selection)
            else
              indent_line(doc, doc.cursor_line)
            end
          end
        end
      end
    end
    
    class DecreaseIndentCommand < ChangeIndentCommand
      
      def indent_line(doc, line_ix)
        use_spaces = true
        num_spaces = 2
        line = doc.get_line(line_ix)
        if doc.edit_view.soft_tabs?
          line_start = doc.offset_at_line(line_ix)
          re = /^ {0,#{doc.edit_view.tab_width}}/
          if md = line.match(re)
            to = line_start + md[0].length
          else
            to = line_start
          end
        else
          line_start = doc.offset_at_line(line_ix)
          if line =~ /^\t/
            to = line_start + 1
          else
            to = line_start
          end
        end
        doc.delete(line_start, to - line_start) unless line_start == to
      end
    end

    class IncreaseIndentCommand < ChangeIndentCommand
      
      def indent_line(doc, line_ix)
        line            = doc.get_line(line_ix)
        if doc.edit_view.soft_tabs?
          whitespace = " "*doc.edit_view.tab_width
        else
          whitespace = "\t"
        end
        doc.insert(doc.offset_at_line(line_ix), whitespace)
      end
    end

    class SelectAllCommand < Redcar::EditTabCommand
    
      def execute
        doc.set_selection_range(doc.length, 0)
      end
    end
    
    class SelectLineCommand < Redcar::EditTabCommand
    
      def execute
        doc.set_selection_range(
          doc.cursor_line_start_offset, doc.cursor_line_end_offset)
      end
    end
    
    class CutCommand < Redcar::DocumentCommand
    
      def execute
        if doc.selection?
          text = doc.selection_ranges.map do |range|
            doc.get_range(range.begin, range.count)
          end
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
    
    class CopyCommand < Redcar::DocumentCommand
    
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
    
    class PasteCommand < Redcar::DocumentCommand
      sensitize :clipboard_not_empty
      
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
            line = doc.get_line(line_ix).chomp
            if line.length < line_offset
              doc.insert(
                doc.offset_at_inner_end_of_line(line_ix),
                " "*(line_offset - line.length)
              )
            end
          end
          doc.insert(
            doc.offset_at_line(line_ix) + line_offset,
            text
          )
          doc.cursor_offset = doc.offset_at_line(line_ix) + line_offset + text.length
        end
      end
    end
    
    class DuplicateCommand < Redcar::DocumentCommand
    
      def execute
        doc = tab.edit_view.document
        if doc.selection?
          first_line_ix = doc.line_at_offset(doc.selection_range.begin)
          last_line_ix  = doc.line_at_offset(doc.selection_range.end)
          text = doc.get_slice(doc.offset_at_line(first_line_ix),
                               doc.offset_at_line_end(last_line_ix))
        else
          last_line_ix = doc.cursor_line
          text = doc.get_line(doc.cursor_line)
        end          
        if last_line_ix == (doc.line_count - 1)
          text = "\n#{text}"
        end
        doc.insert(doc.offset_at_line_end(last_line_ix), text)
        doc.scroll_to_line(last_line_ix + 1)
      end        
    end
    
    class DialogExample < Redcar::Command
      def execute
      	builder = Menu::Builder.new do
      	  item("Foo") { p :foo }
      	  item("Bar") { p :bar }
      	  separator
      	  sub_menu "Baz" do
      	    item("Qux") { p :qx }
      	    item("Quux") { p :quux }
      	    item("Corge") { p :corge }
      	  end
      	end
      	win.popup_menu(builder.menu)
      end
    end
    
    class GotoLineCommand < Redcar::EditTabCommand
      
      class Speedbar < Redcar::Speedbar
        label :goto_label, "Goto line:"
        
        textbox :line
        
        button :go, "Go", "Return" do
          new_line_ix = line.value.to_i - 1
          if new_line_ix < doc.line_count and new_line_ix >= 0
            doc.cursor_offset = doc.offset_at_line(new_line_ix)
            doc.scroll_to_line(new_line_ix)
            win.close_speedbar
          end
        end
        
        def initialize(command)
          @command = command
        end
        
        def doc; @command.doc; end
        def win; @command.send(:win); end
      end
      
      def execute
        @speedbar = GotoLineCommand::Speedbar.new(self)
        win.open_speedbar(@speedbar)
      end
    end
    
    class ToggleBlockSelectionCommand < Redcar::EditTabCommand
      
      def execute
        doc.block_selection_mode = !doc.block_selection_mode?
      end
    end
    
    # define commands from SelectTab1Command to SelectTab9Command
    (1..9).each do |tab_num|
      const_set("SelectTab#{tab_num}Command", Class.new(Redcar::Command)).class_eval do
        define_method :execute do
          notebook = Redcar.app.focussed_window_notebook
          notebook.tabs[tab_num-1].focus if notebook.tabs[tab_num-1]
        end
      end
    end
    
    class ToggleInvisibles < Redcar::EditTabCommand
      def execute
        EditView.show_invisibles = !EditView.show_invisibles?
      end
    end
    
    class ToggleLineNumbers < Redcar::EditTabCommand
      def execute
        EditView.show_line_numbers = !EditView.show_line_numbers?
      end
    end
    
    class ToggleAnnotations < Redcar::EditTabCommand
      def execute
        EditView.show_annotations = !EditView.show_annotations?
      end
    end
    
    class SelectNewFont < Command
      def execute
        Redcar::EditView::SelectFontDialog.new.open
      end
    end

    class SelectTheme < Command
      def execute
        Redcar::EditView::SelectThemeDialog.new.open
      end
    end
    
    class SelectFontSize < Command
      def execute
        result = Application::Dialog.input("Font Size", "Please enter new font size", Redcar::EditView.font_size.to_s) do |text|
          if text.to_i  > 1 and text.to_i < 25
            nil
          else
            "the font size must be > 1 and < 25"
          end
      	end
        Redcar::EditView.font_size = result[:value].to_i if result[:button ] == :ok
      end
    end
    
    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+N",       NewCommand
        link "Cmd+Shift+N", NewNotebookCommand
        link "Cmd+Alt+N",   NewWindowCommand
        link "Cmd+O",       Project::FileOpenCommand
        link "Cmd+Shift+O", Project::DirectoryOpenCommand
        link "Cmd+S",       Project::FileSaveCommand
        link "Cmd+Shift+S", Project::FileSaveAsCommand
        link "Cmd+W",       CloseTabCommand
        link "Cmd+Shift+W", CloseWindowCommand
        link "Cmd+Q",       QuitCommand

        link "Cmd+Shift+E", EditView::InfoSpeedbarCommand
        link "Cmd+Z",       UndoCommand
        link "Cmd+Shift+Z", RedoCommand
        link "Cmd+X",       CutCommand
        link "Cmd+C",       CopyCommand
        link "Cmd+V",       PasteCommand
        link "Cmd+D",       DuplicateCommand        
        
        link "Home",        MoveTopCommand
        link "Ctrl+A",      MoveHomeCommand
        link "Ctrl+E",      MoveEndCommand
        link "End",         MoveBottomCommand
        
        link "Cmd+[",       DecreaseIndentCommand
        link "Cmd+]",       IncreaseIndentCommand
        link "Cmd+Shift+I", AutoIndenter::IndentCommand
        link "Cmd+L",       GotoLineCommand
        link "Cmd+F",       DocumentSearch::SearchForwardCommand
        link "Cmd+A",       SelectAllCommand
        link "Cmd+B",       ToggleBlockSelectionCommand
        #link "Escape", AutoCompleter::AutoCompleteCommand
        link "Ctrl+Escape",  AutoCompleter::MenuAutoCompleterCommand
        
        link "Cmd+T",           Project::FindFileCommand
        link "Cmd+Shift+Alt+O", MoveTabToOtherNotebookCommand
        link "Cmd+Alt+O",       SwitchNotebookCommand
        link "Cmd+Shift+[",     SwitchTabDownCommand
        link "Cmd+Shift+]",     SwitchTabUpCommand

        link "Ctrl+Shift+P",    PrintScopeCommand
        
        link "Cmd+Shift+R",     PluginManagerUi::ReloadLastReloadedCommand
        
        link "Cmd+Alt+S", Snippets::OpenSnippetExplorer
        #Textmate.attach_keybindings(self, :osx)

        # map SelectTab<number>Command
        (1..9).each do |tab_num|
          link "Cmd+#{tab_num}", Top.const_get("SelectTab#{tab_num}Command")
        end

      end

      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+N",       NewCommand
        link "Ctrl+Shift+N", NewNotebookCommand
        link "Ctrl+Alt+N",   NewWindowCommand
        link "Ctrl+O",       Project::FileOpenCommand
        link "Ctrl+Shift+O", Project::DirectoryOpenCommand
        link "Ctrl+S",       Project::FileSaveCommand
        link "Ctrl+Shift+S", Project::FileSaveAsCommand
        link "Ctrl+W",       CloseTabCommand
        link "Ctrl+Shift+W", CloseWindowCommand
        link "Ctrl+Q",       QuitCommand

        link "Ctrl+Shift+E", EditView::InfoSpeedbarCommand
        link "Ctrl+Z",       UndoCommand
        link "Ctrl+Y",       RedoCommand
        link "Ctrl+X",       CutCommand
        link "Ctrl+C",       CopyCommand
        link "Ctrl+V",       PasteCommand
        link "Ctrl+D",       DuplicateCommand
        
        link "Ctrl+Home",    MoveTopCommand
        link "Home",         MoveHomeCommand
        link "End",          MoveEndCommand
        link "Ctrl+End",     MoveBottomCommand
        
        link "Ctrl+[",       DecreaseIndentCommand
        link "Ctrl+]",       IncreaseIndentCommand
        link "Ctrl+Shift+[", AutoIndenter::IndentCommand
        link "Ctrl+L",       GotoLineCommand
        link "Ctrl+F",       DocumentSearch::SearchForwardCommand
        link "F3",           DocumentSearch::RepeatPreviousSearchForwardCommand
        link "Ctrl+A",       SelectAllCommand
        link "Ctrl+B",       ToggleBlockSelectionCommand
        link "Ctrl+Space",       AutoCompleter::AutoCompleteCommand
        link "Ctrl+Shift+Space", AutoCompleter::MenuAutoCompleterCommand
        
        link "Ctrl+T",           Project::FindFileCommand
        link "Ctrl+Shift+Alt+O", MoveTabToOtherNotebookCommand
        
        link "Ctrl+Shift+P",    PrintScopeCommand

        link "Ctrl+Alt+O",       SwitchNotebookCommand
        
        link "Ctrl+Page Up",       SwitchTabDownCommand
        link "Ctrl+Page Down",     SwitchTabUpCommand
        link "Ctrl+Shift+R",     PluginManagerUi::ReloadLastReloadedCommand
        
        link "Ctrl+Alt+S", Snippets::OpenSnippetExplorer
        #Textmate.attach_keybindings(self, :linux)

        # map SelectTab<number>Command
        (1..9).each do |tab_num|
          link "Alt+#{tab_num}", Top.const_get("SelectTab#{tab_num}Command")
        end

      end
      
      [linwin, osx]
    end
    
    def self.menus
      Menu::Builder.build do
        sub_menu "File" do
          item "New", NewCommand
          item "New Window", NewWindowCommand
          item "Open", Project::FileOpenCommand
          item "Open Directory", Project::DirectoryOpenCommand
          lazy_sub_menu "Open Recent" do
            Project::RecentDirectories.generate_menu(self)
          end
          
          separator
          item "Save", Project::FileSaveCommand
          item "Save As", Project::FileSaveAsCommand
          separator
          item "Close Tab", CloseTabCommand
          item "Close Tree", CloseTreeCommand
          item "Close Window", CloseWindowCommand
          item "Close Directory", Project::DirectoryCloseCommand
          separator
          item "Quit", QuitCommand
        end
        sub_menu "Edit" do
          item "Tab Info",  EditView::InfoSpeedbarCommand
          separator
          item "Undo", UndoCommand
          item "Redo", RedoCommand
          separator
          item "Cut", CutCommand
          item "Copy", CopyCommand
          item "Paste", PasteCommand
          item "Duplicate Region", DuplicateCommand
          separator
          item "Top",     MoveTopCommand
          item "Home",    MoveHomeCommand
          item "End",     MoveEndCommand
          item "Bottom",  MoveBottomCommand
          separator
          item "Increase Indent", IncreaseIndentCommand
          item "Decrease Indent", DecreaseIndentCommand
          item "Indent",          AutoIndenter::IndentCommand
          separator
          item "Goto Line", GotoLineCommand
          item "Regex Search",    DocumentSearch::SearchForwardCommand
          item "Repeat Last Search", DocumentSearch::RepeatPreviousSearchForwardCommand
          separator
          sub_menu "Select" do
            item "All", SelectAllCommand
            item "Line", SelectLineCommand
          end
          item "Toggle Block Selection", ToggleBlockSelectionCommand
          item "Auto Complete",          AutoCompleter::AutoCompleteCommand
          item "Menu Auto Complete",     AutoCompleter::MenuAutoCompleterCommand
        end
        sub_menu "Project" do
          item "Find File", Project::FindFileCommand
          item "Refresh Directory", Project::RefreshDirectoryCommand
          separator
          item "Runnables", Runnables::ShowRunnables
        end
        sub_menu "Debug" do
          item "Task Manager", TaskManager::OpenCommand
          separator
          #item "Print Scope Tree", PrintScopeTreeCommand
          item "Print Scope at Cursor", PrintScopeCommand
        end
        sub_menu "View" do
          sub_menu "Appearance" do
            item "Font", SelectNewFont
            item "Font Size", SelectFontSize
            item "Theme", SelectTheme
          end
          separator
          item "New Notebook", NewNotebookCommand
          item "Close Notebook", CloseNotebookCommand
          item "Rotate Notebooks", RotateNotebooksCommand
          item "Move Tab To Other Notebook", MoveTabToOtherNotebookCommand
          item "Switch Notebooks", SwitchNotebookCommand
          separator
          item "Previous Tab", SwitchTabDownCommand
          item "Next Tab", SwitchTabUpCommand
          sub_menu "Switch Tab" do
             (1..9).each do |num|
               item "Tab #{num}", Top.const_get("SelectTab#{num}Command")
             end
          end
          separator
          item "Toggle Invisibles", ToggleInvisibles
          item "Toggle Line Numbers", ToggleLineNumbers
          item "Toggle Annotations", ToggleAnnotations
        end
        sub_menu "Plugins" do
          item "Plugin Manager", PluginManagerUi::OpenCommand
          item "Reload Again", PluginManagerUi::ReloadLastReloadedCommand
          item("Edit Preferences") { Project::Manager.open_project_for_path(Redcar::Plugin::Storage.storage_dir) }
          separator
        end
        sub_menu "Bundles" do
          item "Find Snippet", Snippets::OpenSnippetExplorer
          separator
          Textmate.attach_menus(self)
        end
        sub_menu "Help" do
          item "About", AboutCommand
          item "New In This Version", ChangelogCommand
        end
      end
    end
    
    class ApplicationEventHandler
      def tab_focus(tab)
        tab.focus
      end
    
      def tab_close(tab)
        CloseTabCommand.new(tab).run
      end
      
      def window_close(win)
        CloseWindowCommand.new(win).run
      end
      
      def application_close(app)
        QuitCommand.new.run
      end
      
      def window_focus(win)
        FocusWindowCommand.new(win).run
      end
    end
    
    def self.application_event_handler
      ApplicationEventHandler.new
    end
    
    def self.start(args=[])
      puts "loading plugins took #{Time.now - PROCESS_START_TIME}"
      Application.start
      ApplicationSWT.start
      s = Time.now
      EditViewSWT.start
      puts "EditViewSWT.start took #{Time.now - s}s"
      s = Time.now
      Redcar.gui = ApplicationSWT.gui
      Redcar.app.controller = ApplicationSWT.new(Redcar.app)
      Redcar.app.refresh_menu!
      Redcar.app.load_sensitivities
      puts "initializing gui took #{Time.now - s}s"
      s = Time.now
      Redcar::Project::Manager.start(args)
      puts "project start took #{Time.now - s}s"
      Redcar.app.make_sure_at_least_one_window_open
    end
  end
end
