
module Redcar
  def self.safely(text=nil)
    begin
      yield
    rescue => e
      message = "Error in: " + (text || e.message)
      $stderr.puts message
      $stderr.puts e.class.to_s + ": " + e.message
      $stderr.puts e.backtrace
      return if Redcar.no_gui_mode?
      Application::Dialog.message_box(
        message,
        :type => :error, :buttons => :ok)
    end
  end

  def self.update_gui
    result = nil
    Swt.sync_exec do
      safely do
        result = yield
      end
    end
    result
  end

  class TimeoutError < StandardError; end

  def self.timeout(limit)
    x = Thread.current
    result = nil
    y = Thread.new do
      begin
        result = yield
      rescue Object => e
        x.raise e
      end
    end
    s = Time.now
    loop do
      if not y.alive?
        break
      elsif Time.now - s > limit
        y.kill
        raise Redcar::TimeoutError, "timed out after #{Time.now - s}s"
        break
      end
      sleep 0.1
    end
    result
  end

  module Top
    class QuitCommand < Command

      def execute
        check_for_modified_tabs_and_quit
      end

      private

      def check_for_modified_tabs_and_quit
        EditView::ModifiedTabsChecker.new(
          Redcar.app.all_tabs.select {|t| t.is_a?(EditTab)},
          "Save all before quitting?",
          :none     => lambda { check_for_running_processes_and_quit },
          :continue => lambda { check_for_running_processes_and_quit },
          :cancel   => nil
        ).check
      end

      def check_for_running_processes_and_quit
        Runnables::RunningProcessChecker.new(
          Redcar.app.all_tabs.select {|t| t.is_a?(HtmlTab)},
          "Kill all and quit?",
          :none     => lambda { quit },
          :continue => lambda { quit },
          :cancel   => nil
        ).check
      end
      
      def quit
        Project::Manager.open_projects.each {|pr| pr.close }
        Redcar.app.quit
      end
    end

    class NewCommand < Command

      def execute
        unless win.nil?
          tab = win.new_tab(Redcar::EditTab)
        else
          window = Redcar.app.new_window
          tab = window.new_tab(Redcar::EditTab)
        end
        tab.title = "untitled"
        tab.focus
        tab
      end
    end

    class NewNotebookCommand < Command
#      sensitize :single_notebook

      def execute
        #unless win.notebooks.length > 1
          win.create_notebook
       # end
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
          :none     => lambda { check_for_running_processes_and_close_window },
          :continue => lambda { check_for_running_processes_and_close_window },
          :cancel   => nil
        ).check
      end

      def check_for_running_processes_and_close_window
        Runnables::RunningProcessChecker.new(
          win.notebooks.map(&:tabs).flatten.select {|t| t.is_a?(HtmlTab)},
          "Kill them and close the window?",
          :none     => lambda { win.close },
          :continue => lambda { win.close },
          :cancel   => nil
        ).check
      end

      def win
        @window || super
      end
    end

    class GenerateWindowsMenu < Command
      def initialize(builder)
        @builder = builder
      end

      def execute
        window = Redcar.app.focussed_window
        Redcar.app.windows.each do |win|
          @builder.item(win.title, :type => :radio, :active => (win == window)) do
            FocusWindowCommand.new(win).run
          end
        end
      end
    end

    class GenerateTabsMenu < Command
      def initialize(builder)
        @builder = builder
      end

      def trim(title)
        title = title[0,13]+'...' if title.length > 13
        title
      end

      def execute
        if win = Redcar.app.focussed_window and
          book = win.focussed_notebook and book.tabs.any?
          focussed_tab = book.focussed_tab
          @builder.separator
          @builder.item "Focussed Notebook", ShowTitle
          book.tabs.each_with_index do |tab,i|
            num = i + 1
            if num < 10
              @builder.item "Tab #{num}: #{trim(tab.title)}", :type => :radio, :active => (tab == focussed_tab), :command => Top.const_get("SelectTab#{num}Command")
            else
              @builder.item("Tab #{num}: #{trim(tab.title)}", :type => :radio, :active => (tab == focussed_tab)) {tab.focus}
            end
          end
          if book = win.nonfocussed_notebook and book.tabs.any?
            @builder.separator
            @builder.item "Nonfocussed Notebook", ShowTitle
            book.tabs.each_with_index do |tab,i|
              @builder.item("Tab #{i+1}: #{trim(tab.title)}") {tab.focus}
            end
          end
        end
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
        i = win.notebooks.index current_notebook

        target_notebook = win.notebooks[ (i + 1) % win.notebooks.length ]
        target_notebook.grab_tab_from(current_notebook, tab)
        tab.focus
      end
    end

    class OpenTreeFinderCommand < TreeCommand

      def execute
        if win = Redcar.app.focussed_window
          if trees = win.treebook.trees and trees.any?
            titles = []
            trees.each {|t| titles << t.tree_mirror.title}
            dialog = TreeFuzzyFilter.new(win,titles)
            dialog.open
          end
        end
      end

      class TreeFuzzyFilter < FilterListDialog

        def initialize(win,titles)
          super()
          @win = win
          @titles = titles
        end

        def selected(text,ix)
          if tree = @win.treebook.trees.detect do |tree|
              tree.tree_mirror.title == text
            end
            if @win.treebook.focussed_tree == tree
              @win.set_trees_visible(true) if not @win.trees_visible?
            else
              @win.treebook.focus_tree(tree)
            end
            tree.focus
            close
          end
        end

        def update_list(filter)
          @titles.select do |t|
            t.downcase.include?(filter.downcase)
          end
        end
      end
    end

    class CloseTreeCommand < TreeCommand
      def execute
        win = Redcar.app.focussed_window
        if win and treebook = win.treebook
          if tree = treebook.focussed_tree
            treebook.remove_tree(tree)
          end
        end
      end
    end

    class ToggleTreesCommand < TreeCommand
      def execute
        win = Redcar.app.focussed_window
        if win and treebook = win.treebook
          if win.trees_visible?
            win.set_trees_visible(false)
          else
            win.set_trees_visible(true)
          end
        end
      end
    end

    class AboutCommand < Command
      def execute
        new_tab = Top::NewCommand.new.run
        new_tab.document.text = <<-TXT
About: Redcar\nVersion: #{Redcar::VERSION}
Ruby Version: #{RUBY_VERSION}
Jruby version: #{JRUBY_VERSION}
Redcar.environment: #{Redcar.environment}
        TXT
        new_tab.edit_view.reset_undo
        new_tab.document.set_modified(false)
        new_tab.title= 'About'
      end
    end

    class ChangelogCommand < Command
      def execute
        new_tab = Top::NewCommand.new.run
        new_tab.document.text = File.read(File.join(File.dirname(__FILE__), "..", "..", "CHANGES"))
        new_tab.edit_view.reset_undo
        new_tab.edit_view.document.set_modified(false)
        new_tab.title = 'Changes'
      end
    end

    class PrintScopeTreeCommand < Command
      def execute
        puts tab.edit_view.controller.mate_text.parser.root.pretty(0)
      end
    end

    class PrintScopeCommand < DocumentCommand
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
            tab.focus
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
        elsif tab.is_a?(HtmlTab)
          if tab.html_view.controller and message = tab.html_view.controller.ask_before_closing
            tab.focus
            result = Application::Dialog.message_box(
              message,
              :buttons => :yes_no_cancel
            )
            case result
            when :yes
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

    class CloseAll < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        tabs = window.all_tabs
        tabs.each do |t|
          Redcar::Top::CloseTabCommand.new(t).run
        end
      end
    end

    class CloseOthers < Redcar::Command
      def execute
        window = Redcar.app.focussed_window
        current_tab = Redcar.app.focussed_notebook_tab
        tabs = window.all_tabs
        tabs.each do |t|
          unless t == current_tab
            Redcar::Top::CloseTabCommand.new(t).run
          end
        end
      end
    end

    class SwitchTreeDownCommand < TreeCommand

      def execute
        win = Redcar.app.focussed_window
        win.treebook.switch_down
      end
    end

    class SwitchTreeUpCommand < TreeCommand

      def execute
        win = Redcar.app.focussed_window
        win.treebook.switch_up
      end
    end

    class SwitchTabDownCommand < TabCommand

      def execute
        win.focussed_notebook.switch_down
      end
    end

    class SwitchTabUpCommand < TabCommand

      def execute
        win.focussed_notebook.switch_up
      end
    end

    class MoveTabUpCommand < TabCommand

      def execute
        win.focussed_notebook.move_up
      end
    end

    class MoveTabDownCommand < TabCommand

      def execute
        win.focussed_notebook.move_down
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

    class MoveHomeCommand < DocumentCommand

      def execute
        if doc.mirror.is_a?(Redcar::REPL::ReplMirror)
          # do not do the default home command on a line with a prompt
          return unless tab.go_to_home?
        end
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

    class MoveTopCommand < DocumentCommand

      def execute
        doc.cursor_offset = 0
        doc.ensure_visible(0)
      end
    end

    class MoveEndCommand < DocumentCommand

      def execute
        line_ix = doc.line_at_offset(doc.cursor_offset)
        if line_ix == doc.line_count - 1
          doc.cursor_offset = doc.length
        else
          doc.cursor_offset = doc.offset_at_line(line_ix + 1) - doc.delim.length
        end
        doc.ensure_visible(doc.cursor_offset)
      end
    end

    class MoveNextLineCommand < DocumentCommand
      def execute
        doc = tab.edit_view.document
        line_ix = doc.line_at_offset(doc.cursor_offset)
        if line_ix == doc.line_count - 1
          doc.cursor_offset = doc.length
        else
          doc.cursor_offset = doc.offset_at_line(line_ix + 1) - doc.delim.length
        end
        doc.ensure_visible(doc.cursor_offset)
        doc.insert(doc.cursor_offset, "\n")

      end
    end

    class MoveBottomCommand < DocumentCommand
      def execute
        doc.cursor_offset = doc.length
        doc.ensure_visible(doc.length)
      end
    end

    class ChangeIndentCommand < DocumentCommand
      def execute
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

    class SelectAllCommand < Redcar::DocumentCommand

      def execute
        doc.select_all
      end
    end

    class SelectLineCommand < Redcar::DocumentCommand

      def execute
        doc.set_selection_range(
          doc.cursor_line_start_offset, doc.cursor_line_end_offset)
      end
    end

    class SelectWordCommand < Redcar::DocumentCommand

      def execute
        range = doc.current_word_range
        doc.set_selection_range(range.first, range.last)
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
        doc.controllers(AutoPairer::DocumentController).first.disable do
          doc.controllers(AutoIndenter::DocumentController).first.disable do
            doc.controllers(AutoCompleter::DocumentController).first.start_modification
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
            doc.controllers(AutoCompleter::DocumentController).first.end_modification
          end
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

    class SortLinesCommand < Redcar::DocumentCommand

      def execute
        doc = tab.edit_view.document
        cursor_ix = doc.cursor_offset
        if doc.selection?
          start_ix = doc.selection_range.begin
          text = doc.selected_text

          sorted_text = text.split("\n").sort().join("\n")
          doc.replace_selection(sorted_text)
          doc.cursor_offset = cursor_ix
        end
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
          if new_line_ix < @doc.line_count and new_line_ix >= 0
            @doc.cursor_offset = @doc.offset_at_line(new_line_ix)
            @doc.scroll_to_line(new_line_ix)
            @win.close_speedbar
          end
        end

        def initialize(command, win)
          @command = command
          @doc     = command.doc
          @win     = win
        end
      end

      def execute
        @speedbar = GotoLineCommand::Speedbar.new(self, win)
        win.open_speedbar(@speedbar)
      end
    end

    class ToggleBlockSelectionCommand < Redcar::DocumentCommand

      def execute
        unless doc.single_line?
          doc.block_selection_mode = !doc.block_selection_mode?
        end
      end
    end

    class TreebookWidthCommand < Command
      sensitize :open_trees

      def increment
        raise "Please implement me!"
      end

      def execute
        if win = Redcar.app.focussed_window
          if increment > 0
            win.adjust_treebook_width(true)
          else
            win.adjust_treebook_width(false)
          end
        end
      end
    end

    ["In","De"].each do |prefix|
      const_set("#{prefix}creaseTreebookWidthCommand", Class.new(TreebookWidthCommand)).class_eval do
        define_method :increment do
          prefix == "In" ? 1 : -1
        end
      end
    end

    class EnlargeNotebookCommand < Command
      sensitize :multiple_notebooks
      def index
        raise "Please define me!"
      end

      def execute
        if win = Redcar.app.focussed_window
          win.enlarge_notebook(index)
        end
      end
    end

    ["First","Second"].each do |book|
      const_set("Enlarge#{book}NotebookCommand", Class.new(EnlargeNotebookCommand)).class_eval do
        define_method :index do
          book == "First" ? 0 : 1
        end
      end
    end

    # define commands from SelectTab1Command to SelectTab9Command
    (1..9).each do |tab_num|
      const_set("SelectTab#{tab_num}Command", Class.new(Redcar::TabCommand)).class_eval do
        define_method :execute do
          notebook = Redcar.app.focussed_window_notebook
          notebook.tabs[tab_num-1].focus if notebook.tabs[tab_num-1]
        end
      end
    end

    class ResetNotebookWidthsCommand < Command
      sensitize :multiple_notebooks

      def execute
        if win = Redcar.app.focussed_window
          win.reset_notebook_widths
        end
      end
    end

    class ToggleFullscreen < Command
      def execute
        Redcar.app.focussed_window.fullscreen = !Redcar.app.focussed_window.fullscreen
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

    class ToggleToolbar < Command

      def execute
        Redcar.app.toggle_show_toolbar
        Redcar.app.refresh_toolbar!
      end
    end

    class SelectNewFont < EditTabCommand
      def execute
        Redcar::EditView::SelectFontDialog.new.open
      end
    end

    class SelectTheme < EditTabCommand
      def execute
        Redcar::EditView::SelectThemeDialog.new.open
      end
    end

    class ShowTheme < Command
      def execute

      end
    end

    class ShowTitle < Command
      sensitize :always_disabled
      def execute; end
    end

    class SelectFontSize < EditTabCommand
      def execute
        max    = Redcar::EditView::MAX_FONT_SIZE
        min    = Redcar::EditView::MIN_FONT_SIZE
        result = Application::Dialog.input(
          "Font Size",
          "Please enter new font size",
          Redcar::EditView.font_size.to_s)
        if result[:button] == :ok
          value = result[:value].to_i
          if value >= min and value <= max
            Redcar::EditView.font_size = value
          else
            Application::Dialog.message_box(
              "The font size must be between #{min} and #{max}")
          end
        end
      end
    end

    class IncreaseFontSize < EditTabCommand
      def execute
        unless (current = Redcar::EditView.font_size) >= Redcar::EditView::MAX_FONT_SIZE
          Redcar::EditView.font_size = current+1
        end
      end
    end

    class DecreaseFontSize < EditTabCommand
      def execute
        unless (current = Redcar::EditView.font_size) <= Redcar::EditView::MIN_FONT_SIZE
          Redcar::EditView.font_size = current-1
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+N",       NewCommand
        link "Cmd+Shift+N", NewNotebookCommand
        link "Cmd+Alt+N",   NewWindowCommand
        link "Cmd+O",       Project::FileOpenCommand
        link "Cmd+U",       Project::FileReloadCommand
        link "Cmd+Shift+O", Project::DirectoryOpenCommand
        link "Cmd+Alt+Ctrl+P",   Project::FindRecentCommand
        #link "Cmd+Ctrl+O",  Project::OpenRemoteCommand
        link "Cmd+S",       Project::FileSaveCommand
        link "Cmd+Shift+S", Project::FileSaveAsCommand
        link "Cmd+W",       CloseTabCommand
        link "Cmd+Shift+W", CloseWindowCommand
        link "Alt+Shift+W", CloseTreeCommand
        link "Cmd+Q",       QuitCommand

        #link "Cmd+Return",   MoveNextLineCommand

        link "Ctrl+Shift+E", EditView::InfoSpeedbarCommand
        link "Cmd+Z",        UndoCommand
        link "Cmd+Shift+Z",  RedoCommand
        link "Cmd+X",        CutCommand
        link "Cmd+C",        CopyCommand
        link "Cmd+V",        PasteCommand
        link "Cmd+D",        DuplicateCommand

        link "Home",   MoveTopCommand
        link "Ctrl+A", MoveHomeCommand
        link "Ctrl+E", MoveEndCommand
        link "End",    MoveBottomCommand

        link "Cmd+[",            DecreaseIndentCommand
        link "Cmd+]",            IncreaseIndentCommand
        link "Cmd+Shift+I",      AutoIndenter::IndentCommand
        link "Cmd+L",            GotoLineCommand
        link "Cmd+A",            SelectAllCommand
        link "Ctrl+W",           SelectWordCommand
        link "Ctrl+L",           SelectLineCommand
        link "Cmd+B",            ToggleBlockSelectionCommand
        link "Escape",           AutoCompleter::AutoCompleteCommand
        link "Ctrl+Escape",      AutoCompleter::MenuAutoCompleterCommand
        link "Ctrl+Space",       AutoCompleter::AutoCompleteCommand
        link "Ctrl+Shift+Space", AutoCompleter::MenuAutoCompleterCommand

        link "Ctrl+U",       EditView::UpcaseTextCommand
        link "Ctrl+Shift+U", EditView::DowncaseTextCommand
        link "Ctrl+Alt+U",   EditView::TitlizeTextCommand
        link "Ctrl+G",       EditView::OppositeCaseTextCommand
        link "Ctrl+_",       EditView::CamelSnakePascalRotateTextCommand
        link "Ctrl+=",       EditView::AlignAssignmentCommand
        link "Ctrl+Shift+^", SortLinesCommand

        link "Cmd+T",           Project::FindFileCommand
        link "Cmd+Shift+Alt+O", MoveTabToOtherNotebookCommand
        link "Cmd+Alt+O",       SwitchNotebookCommand
        link "Alt+Shift+[",     SwitchTreeUpCommand
        link "Alt+Shift+]",     SwitchTreeDownCommand
        link "Cmd+Shift+[",     SwitchTabDownCommand
        link "Cmd+Shift+]",     SwitchTabUpCommand
        link "Ctrl+Shift+[",    MoveTabDownCommand
        link "Ctrl+Shift+]",    MoveTabUpCommand
        link "Cmd+Shift++",     ToggleFullscreen
        link "Cmd+Shift+T",     OpenTreeFinderCommand
        link "Alt+Shift+J",     IncreaseTreebookWidthCommand
        link "Alt+Shift+H",     DecreaseTreebookWidthCommand
        link "Cmd+Shift+>",     EnlargeFirstNotebookCommand
        link "Cmd+Shift+<",     EnlargeSecondNotebookCommand
        link "Cmd+Shift+L",     ResetNotebookWidthsCommand
        link "Cmd+Shift+:",     RotateNotebooksCommand
        link "Alt+Shift+N",     CloseNotebookCommand
        link "Cmd+Alt+I",       ToggleInvisibles
        link "Cmd++",           IncreaseFontSize
        link "Cmd+-",           DecreaseFontSize

        link "Ctrl+Shift+P", PrintScopeCommand
        link "Cmd+Shift+H",  ToggleTreesCommand

        # link "Cmd+Shift+R",     PluginManagerUi::ReloadLastReloadedCommand

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
        link "Ctrl+Alt+Shift+P",   Project::FindRecentCommand
        #link "Alt+Shift+O",  Project::OpenRemoteCommand
        link "Ctrl+S",       Project::FileSaveCommand
        link "Ctrl+Shift+S", Project::FileSaveAsCommand
        link "Ctrl+W",       CloseTabCommand
        link "Ctrl+Shift+W", CloseWindowCommand
        link "Alt+Shift+W",  CloseTreeCommand
        link "Ctrl+Q",       QuitCommand

        link "Ctrl+Enter",   MoveNextLineCommand

        link "Ctrl+Shift+E", EditView::InfoSpeedbarCommand
        link "Ctrl+Z",       UndoCommand
        link "Ctrl+Y",       RedoCommand
        link "Ctrl+X",       CutCommand
        link "Ctrl+C",       CopyCommand
        link "Ctrl+V",       PasteCommand
        link "Ctrl+D",       DuplicateCommand

        link "Ctrl+Home",  MoveTopCommand
        link "Home",       MoveHomeCommand
        link "Ctrl+Alt+A", MoveHomeCommand
        link "End",        MoveEndCommand
        link "Ctrl+Alt+E", MoveEndCommand
        link "Ctrl+End",   MoveBottomCommand

        link "Ctrl+[",           DecreaseIndentCommand
        link "Ctrl+]",           IncreaseIndentCommand
        link "Ctrl+Shift+[",     AutoIndenter::IndentCommand
        link "Ctrl+L",           GotoLineCommand
        link "Ctrl+A",           SelectAllCommand
        link "Ctrl+Alt+W",       SelectWordCommand
        link "Ctrl+Alt+L",       SelectLineCommand
        link "Ctrl+B",           ToggleBlockSelectionCommand
        link "Escape",           AutoCompleter::AutoCompleteCommand
        link "Ctrl+Escape",      AutoCompleter::MenuAutoCompleterCommand
        link "Ctrl+Space",       AutoCompleter::AutoCompleteCommand
        
        link "Ctrl+Shift+Space", AutoCompleter::MenuAutoCompleterCommand

        link "Ctrl+U",           EditView::UpcaseTextCommand
        link "Ctrl+Shift+U",     EditView::DowncaseTextCommand
        link "Ctrl+Alt+U",       EditView::TitlizeTextCommand
        link "Ctrl+Alt+Shift+U", EditView::OppositeCaseTextCommand
        link "Ctrl+_",           EditView::CamelSnakePascalRotateTextCommand
        link "Ctrl+=",           EditView::AlignAssignmentCommand
        link "Ctrl+Shift+^",     SortLinesCommand

        link "Ctrl+T",           Project::FindFileCommand
        link "Ctrl+Shift+Alt+O", MoveTabToOtherNotebookCommand

        link "Ctrl+Shift+P", PrintScopeCommand

        link "Ctrl+Alt+O",           SwitchNotebookCommand
        link "Ctrl+Shift+H",         ToggleTreesCommand
        link "Alt+Page Up",          SwitchTreeUpCommand
        link "Alt+Page Down",        SwitchTreeDownCommand
        link "Ctrl+Page Up",         SwitchTabDownCommand
        link "Ctrl+Page Down",       SwitchTabUpCommand
        link "Ctrl+Shift+Page Up",   MoveTabDownCommand
        link "Ctrl+Shift+Page Down", MoveTabUpCommand
        link "Ctrl+Shift+T",         OpenTreeFinderCommand
        link "Alt+Shift+J",          IncreaseTreebookWidthCommand
        link "Alt+Shift+H",          DecreaseTreebookWidthCommand
        link "Ctrl+Shift+>",         EnlargeFirstNotebookCommand
        link "Ctrl+Shift+<",         EnlargeSecondNotebookCommand
        link "Ctrl+Shift+L",         ResetNotebookWidthsCommand
        link "Ctrl+Shift+:",         RotateNotebooksCommand
        link "Alt+Shift+N",          CloseNotebookCommand
        # link "Ctrl+Shift+R",     PluginManagerUi::ReloadLastReloadedCommand
        link "F11",                  ToggleFullscreen
        link "Ctrl+Alt+I",           ToggleInvisibles
        link "Ctrl++",               IncreaseFontSize
        link "Ctrl+-",               DecreaseFontSize

        link "Ctrl+Alt+S", Snippets::OpenSnippetExplorer

        #Textmate.attach_keybindings(self, :linux)

        # map SelectTab<number>Command
        (1..9).each do |tab_num|
          link "Alt+#{tab_num}", Top.const_get("SelectTab#{tab_num}Command")
        end

      end

      [linwin, osx]
    end

    def self.toolbars
      ToolBar::Builder.build do
        item "New File", :command => NewCommand, :icon => :new, :barname => :core
        item "Open File", :command => Project::FileOpenCommand, :icon => :open, :barname => :core
        item "Open Directory", :command => Project::DirectoryOpenCommand, :icon => :open_dir, :barname => :core
        item "Save File", :command => Project::FileSaveCommand, :icon => :save, :barname => :core
        item "Save File As", :command => Project::FileSaveAsCommand, :icon => :save_as, :barname => :core
        item "Undo", :command => UndoCommand, :icon => :undo, :barname => :core
        item "Redo", :command => RedoCommand, :icon => :redo, :barname => :core
        item "New Notebook", :command => NewNotebookCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "book--plus.png"), :barname => :edit
        item "Close Notebook", :command => CloseNotebookCommand, :icon => File.join(Redcar::ICONS_DIRECTORY, "book--minus.png"), :barname => :edit
      end
    end

    def self.menus(window)
      Menu::Builder.build do
        sub_menu "File", :priority => :first do
          group(:priority => :first) do
            item "New", NewCommand
            item "New Window", NewWindowCommand
          end

          group(:priority => 10) do
            separator
            item "Close Tab", CloseTabCommand
            item "Close Tree", CloseTreeCommand
            item "Close Window", CloseWindowCommand
            item "Close Others", CloseOthers
            item "Close All", CloseAll
          end

          group(:priority => :last) do
            separator
            item "Quit", QuitCommand
          end
        end
        sub_menu "Edit", :priority => 5 do
          group(:priority => :first) do
            item "Tab Info",  EditView::InfoSpeedbarCommand
          end
          group(:priority => 10) do
            separator
            item "Undo", UndoCommand
            item "Redo", RedoCommand
          end

          group(:priority => 15) do
            separator
            item "Cut", CutCommand
            item "Copy", CopyCommand
            item "Paste", PasteCommand
            sub_menu "Line Tools", :priority => 20 do
              item "Duplicate Region", DuplicateCommand
              item "Sort Lines in Region", SortLinesCommand
            end
          end

          group(:priority => 30) do
            separator
            sub_menu "Selection" do
              item "All", SelectAllCommand
              item "Line", SelectLineCommand
              item "Current Word", SelectWordCommand
              item "Toggle Block Selection", ToggleBlockSelectionCommand
            end
          end

          group(:priority => 40) do
            sub_menu "Document Navigation" do
              item "Goto Line", GotoLineCommand
              item "Top",     MoveTopCommand
              item "Home",    MoveHomeCommand
              item "End",     MoveEndCommand
              item "Bottom",  MoveBottomCommand
            end
          end

          group(:priority => 50) do
            sub_menu "Formatting" do
              item "Increase Indent", IncreaseIndentCommand
              item "Decrease Indent", DecreaseIndentCommand
            end
          end

        end
        sub_menu "Debug", :priority => 20 do
          group(:priority => 10) do
            item "Task Manager", TaskManager::OpenCommand
            separator
            #item "Print Scope Tree", PrintScopeTreeCommand
            item "Print Scope at Cursor", PrintScopeCommand
          end
        end
        sub_menu "View", :priority => 30 do
          sub_menu "Appearance", :priority => 5 do
            item "Select Theme", SelectTheme
            separator
            item "Select Font" , SelectNewFont
            item "Select Font Size"  , SelectFontSize
            item "Increase Font Size", IncreaseFontSize
            item "Decrease Font Size", DecreaseFontSize
          end
          group(:priority => 10) do
            separator
            item "Toggle Fullscreen", :command => ToggleFullscreen, :type => :check, :active => window ? window.fullscreen : false
          end
          group(:priority => 15) do
            separator
            sub_menu "Trees" do
              item "Open Tree Finder", OpenTreeFinderCommand
              item "Toggle Tree Visibility", ToggleTreesCommand
              item "Increase Tree Width", IncreaseTreebookWidthCommand
              item "Decrease Tree Width", DecreaseTreebookWidthCommand
              separator
              item "Previous Tree", SwitchTreeUpCommand
              item "Next Tree", SwitchTreeDownCommand
            end
            lazy_sub_menu "Windows" do
              GenerateWindowsMenu.new(self).run
            end
            sub_menu "Notebooks" do
              item "New Notebook", NewNotebookCommand
              item "Close Notebook", CloseNotebookCommand
              item "Rotate Notebooks", RotateNotebooksCommand
              item "Move Tab To Other Notebook", MoveTabToOtherNotebookCommand
              item "Switch Notebooks", SwitchNotebookCommand
              separator
              item "Enlarge First Notebook", EnlargeFirstNotebookCommand
              item "Enlarge Second Notebook", EnlargeSecondNotebookCommand
              item "Reset Notebook Widths", ResetNotebookWidthsCommand
            end
            sub_menu "Tabs" do
              item "Previous Tab", SwitchTabDownCommand
              item "Next Tab", SwitchTabUpCommand
              item "Move Tab Left", MoveTabDownCommand
              item "Move Tab Right", MoveTabUpCommand
              separator
              # GenerateTabsMenu.new(self).run # TODO: find a way to maintain keybindings with lazy menus
              item "Focussed Notebook", ShowTitle
              (1..9).each do |num|
                item "Tab #{num}", Top.const_get("SelectTab#{num}Command")
              end
            end
          end
          group(:priority => :last) do
            separator
            item "Show Toolbar", :command => ToggleToolbar, :type => :check, :active => Redcar.app.show_toolbar?
            item "Show Invisibles", :command => ToggleInvisibles, :type => :check, :active => EditView.show_invisibles?
            item "Show Line Numbers", :command => ToggleLineNumbers, :type => :check, :active => EditView.show_line_numbers?
          end
        end
        sub_menu "Bundles", :priority => 45 do
          group(:priority => :first) do
            item "Find Snippet", Snippets::OpenSnippetExplorer
            item "Installed Bundles", Textmate::InstalledBundles
            item "Browse Snippets", Textmate::ShowSnippetTree
          end
          group(:priority => 15) do
            separator
            Textmate.attach_menus(self)
          end
        end
        sub_menu "Help", :priority => :last do
          group(:priority => :last) do
            item "About", AboutCommand
            item "New In This Version", ChangelogCommand
          end
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
      Redcar.update_gui do
        Application.start
        ApplicationSWT.start
        Swt.splash_screen.inc(1) if Swt.splash_screen
        EditViewSWT.start
        Swt.splash_screen.inc(7) if Swt.splash_screen
        s = Time.now
        if Redcar.gui
          Redcar.app.controller = ApplicationSWT.new(Redcar.app)
        end
        Redcar.app.refresh_menu!
        Redcar.app.load_sensitivities
        puts "initializing gui took #{Time.now - s}s"
      end
      Redcar.update_gui do
        Swt.splash_screen.inc(2) if Swt.splash_screen
        s = Time.now
        Redcar::Project::Manager.start(args)
        puts "project start took #{Time.now - s}s"
        win = Redcar.app.make_sure_at_least_one_window_open
        win.close if win and args.include?("--no-window")
      end
      Redcar.update_gui do
        Swt.splash_screen.close if Swt.splash_screen
      end
      puts "start time: #{Time.now - $redcar_process_start_time}"
      if args.include?("--compute-textmate-cache-and-quit")
        Redcar::Textmate.all_bundles
        exit
      end
    end
  end
end
