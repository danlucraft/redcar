
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
    class OpenNewEditTabCommand < Command

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

    class GenerateWindowsMenu < Command
      def initialize(builder)
        @builder = builder
      end

      def execute
        window = Redcar.app.focussed_window
        Redcar.app.windows.each do |win|
          @builder.item(win.title, :type => :radio, :active => (win == window)) do
            Application::FocusWindowCommand.new(win).run
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
              @builder.item("Tab #{num}: #{trim(tab.title)}",
                :type => :radio,
                :active => (tab == focussed_tab),
                :command => Redcar::Application.const_get("SelectTab#{num}Command")
              )
            else
              @builder.item("Tab #{num}: #{trim(tab.title)}",
                :type => :radio,
                :active => (tab == focussed_tab)) { tab.focus }
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

    class AboutCommand < Command
      def execute
        new_tab = Top::OpenNewEditTabCommand.new.run
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
        new_tab = Top::OpenNewEditTabCommand.new.run
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

    class MoveUpCommand < EditTabCommand
      def execute
        tab.edit_view.invoke_action(:LINE_UP)
      end
    end

    class MoveDownCommand < EditTabCommand
      def execute
        tab.edit_view.invoke_action(:LINE_DOWN)
      end
    end

    class ForwardCharCommand < DocumentCommand
      def execute
        doc.cursor_offset = [doc.cursor_offset + 1, doc.length].min
      end
    end

    class BackwardCharCommand < DocumentCommand
      def execute
        doc.cursor_offset = [doc.cursor_offset - 1, 0].max
      end
    end

    class OpenLineCommand < DocumentCommand
      def execute
        prev = doc.cursor_offset
        doc.insert_at_cursor("\n")
        doc.cursor_offset = prev
      end
    end

    class DeleteCharCommand < DocumentCommand
      def execute
        if doc.cursor_offset < doc.length
          doc.delete(doc.cursor_offset, 1)
        end
      end
    end

    class BackspaceCommand < DocumentCommand
      def execute
        if doc.cursor_offset > 0
          doc.delete(doc.cursor_offset - 1, 1)
        end
      end
    end
    
    class BackwardNavigationCommand < Command
      def execute
        Redcar.app.navigation_history.backward
      end
    end
    
    class ForwardNavigationCommand < Command
      def execute
        Redcar.app.navigation_history.forward
      end
    end

    class ChangeIndentCommand < DocumentCommand
      def execute
        doc.compound do
          doc.edit_view.delay_parsing do
            indenters = edit_view.document.controllers(Redcar::AutoIndenter::DocumentController).first
            indenters.disable do
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

    class TransposeCharactersCommand < Redcar::DocumentCommand
      def execute
        line        = doc.get_line(doc.cursor_line)
        line_offset = doc.cursor_line_offset

        if line_offset > 0 and line.length >= 2
          if line_offset < line.length - 1
            first_char  = line.chars[line_offset - 1].to_s
            second_char = line.chars[line_offset].to_s
            doc.replace(doc.cursor_offset - 1, 2, second_char + first_char)
          elsif line_offset == line.length - 1
            first_char  = line.chars[line_offset - 2].to_s
            second_char = line.chars[line_offset - 1].to_s
            doc.replace(doc.cursor_offset - 2, 2, second_char + first_char)
          end
        end
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
        link "Cmd+N",       OpenNewEditTabCommand
        link "Cmd+Shift+N", Application::OpenNewNotebookCommand
        link "Cmd+Alt+N",   Application::OpenNewWindowCommand
        link "Cmd+O",       Project::OpenFileCommand
        link "Cmd+U",       Project::FileReloadCommand
        link "Cmd+Shift+O", Project::DirectoryOpenCommand
        link "Cmd+Alt+Ctrl+P",   Project::FindRecentCommand
        #link "Cmd+Ctrl+O",  Project::OpenRemoteCommand
        link "Cmd+S",       Project::SaveFileCommand
        link "Cmd+Shift+S", Project::SaveFileAsCommand
        link "Cmd+W",       Application::CloseTabCommand
        link "Cmd+Shift+W", Application::CloseWindowCommand
        link "Alt+Shift+W", Application::CloseTreeCommand
        link "Cmd+Q",       Application::QuitCommand

        #link "Cmd+Return",   MoveNextLineCommand

        link "Ctrl+Shift+E", EditView::InfoSpeedbarCommand
        link "Cmd+Z",        UndoCommand
        link "Cmd+Shift+Z",  RedoCommand
        link "Cmd+X",        CutCommand
        link "Cmd+C",        CopyCommand
        link "Cmd+V",        PasteCommand
        link "Cmd+D",        DuplicateCommand
        link "Ctrl+T",       TransposeCharactersCommand

        link "Home",    MoveTopCommand
        link "Ctrl+A",  MoveHomeCommand
        link "Ctrl+E",  MoveEndCommand
        link "End",     MoveBottomCommand
        link "Ctrl+F",  ForwardCharCommand
        link "Ctrl+B",  BackwardCharCommand
        link "Ctrl+P",  MoveUpCommand
        link "Ctrl+N",  MoveDownCommand
        link "Ctrl+B",  BackwardCharCommand
        link "Ctrl+O",  OpenLineCommand
        link "Ctrl+D",  DeleteCharCommand
        link "Ctrl+H",  BackspaceCommand
        
        link "Ctrl+Alt+Left", BackwardNavigationCommand
        link "Ctrl+Alt+Right", ForwardNavigationCommand

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
        link "Cmd+Shift+Alt+O", Application::MoveTabToOtherNotebookCommand
        link "Cmd+Alt+O",       Application::SwitchNotebookCommand
        link "Alt+Shift+[",     Application::SwitchTreeUpCommand
        link "Alt+Shift+]",     Application::SwitchTreeDownCommand
        link "Cmd+Shift+[",     Application::SwitchTabDownCommand
        link "Cmd+Shift+]",     Application::SwitchTabUpCommand
        link "Ctrl+Shift+[",    Application::MoveTabDownCommand
        link "Ctrl+Shift+]",    Application::MoveTabUpCommand
        link "Cmd+Shift++",     Application::ToggleFullscreen
        link "Cmd+Shift+T",     Application::OpenTreeFinderCommand
        link "Alt+Shift+J",     Application::IncreaseTreebookWidthCommand
        link "Alt+Shift+H",     Application::DecreaseTreebookWidthCommand
        link "Cmd+Shift+>",     Application::EnlargeNotebookCommand
        link "Cmd+Shift+L",     Application::ResetNotebookWidthsCommand
        link "Cmd+Shift+:",     Application::RotateNotebooksCommand
        link "Alt+Shift+N",     Application::CloseNotebookCommand
        link "Cmd+Alt+I",       ToggleInvisibles
        link "Cmd++",           IncreaseFontSize
        link "Cmd+-",           DecreaseFontSize

        link "Ctrl+Shift+P", PrintScopeCommand
        link "Cmd+Shift+H",  Application::ToggleTreesCommand

        # link "Cmd+Shift+R",     PluginManagerUi::ReloadLastReloadedCommand

        link "Cmd+Alt+S", Snippets::OpenSnippetExplorer
        #Textmate.attach_keybindings(self, :osx)

        # map SelectTab<number>Command
        (1..9).each do |tab_num|
          link "Cmd+#{tab_num}", Application.const_get("SelectTab#{tab_num}Command")
        end

      end

      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+N",       OpenNewEditTabCommand
        link "Ctrl+Shift+N", Application::OpenNewNotebookCommand
        link "Ctrl+Alt+N",   Application::OpenNewWindowCommand
        link "Ctrl+O",       Project::OpenFileCommand
        link "Ctrl+Shift+O", Project::DirectoryOpenCommand
        link "Ctrl+Alt+Shift+P",   Project::FindRecentCommand
        #link "Alt+Shift+O",  Project::OpenRemoteCommand
        link "Ctrl+S",       Project::SaveFileCommand
        link "Ctrl+Shift+S", Project::SaveFileAsCommand
        link "Ctrl+W",       Application::CloseTabCommand
        link "Ctrl+Shift+W", Application::CloseWindowCommand
        link "Alt+Shift+W",  Application::CloseTreeCommand
        link "Ctrl+Q",       Application::QuitCommand

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
        
        link "Alt+[", BackwardNavigationCommand
        link "Alt+]", ForwardNavigationCommand

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
        link "Ctrl+Shift+Alt+O", Application::MoveTabToOtherNotebookCommand

        link "Ctrl+Shift+P", PrintScopeCommand

        link "Ctrl+Alt+O",           Application::SwitchNotebookCommand
        link "Ctrl+Shift+H",         Application::ToggleTreesCommand
        link "Alt+Page Up",          Application::SwitchTreeUpCommand
        link "Alt+Page Down",        Application::SwitchTreeDownCommand
        link "Ctrl+Page Up",         Application::SwitchTabDownCommand
        link "Ctrl+Page Down",       Application::SwitchTabUpCommand
        link "Ctrl+Shift+Page Up",   Application::MoveTabDownCommand
        link "Ctrl+Shift+Page Down", Application::MoveTabUpCommand
        link "Ctrl+Shift+T",         Application::OpenTreeFinderCommand
        link "Alt+Shift+J",          Application::IncreaseTreebookWidthCommand
        link "Alt+Shift+H",          Application::DecreaseTreebookWidthCommand
        link "Ctrl+Shift+>",         Application::EnlargeNotebookCommand
        link "Ctrl+Shift+L",         Application::ResetNotebookWidthsCommand
        link "Ctrl+Shift+:",         Application::RotateNotebooksCommand
        link "Alt+Shift+N",          Application::CloseNotebookCommand
        link "F11",                  Application::ToggleFullscreen
        link "Ctrl+Alt+I",           ToggleInvisibles
        link "Ctrl++",               IncreaseFontSize
        link "Ctrl+-",               DecreaseFontSize

        link "Ctrl+Alt+S", Snippets::OpenSnippetExplorer

        #Textmate.attach_keybindings(self, :linux)

        # map SelectTab<number>Command
        (1..9).each do |tab_num|
          link "Alt+#{tab_num}", Application.const_get("SelectTab#{tab_num}Command")
        end

      end

      [linwin, osx]
    end

    def self.toolbars
      ToolBar::Builder.build do
        item "New File", :command => OpenNewEditTabCommand, :icon => :new, :barname => :core
        item "Open File", :command => Project::OpenFileCommand, :icon => :open, :barname => :core
        item "Open Directory", :command => Project::DirectoryOpenCommand, :icon => :open_dir, :barname => :core
        item "Save File", :command => Project::SaveFileCommand, :icon => :save, :barname => :core
        item "Save File As", :command => Project::SaveFileAsCommand, :icon => :save_as, :barname => :core
        item "Undo", :command => UndoCommand, :icon => :undo, :barname => :core
        item "Redo", :command => RedoCommand, :icon => :redo, :barname => :core
        item "New Notebook", :command => Application::OpenNewNotebookCommand, :icon => File.join(Redcar.icons_directory, "book--plus.png"), :barname => :edit
        item "Close Notebook", :command => Application::CloseNotebookCommand, :icon => File.join(Redcar.icons_directory, "book--minus.png"), :barname => :edit
      end
    end


    def self.menus(window)
      Menu::Builder.build do
        sub_menu "File", :priority => :first do
          group(:priority => :first) do
            item "New", OpenNewEditTabCommand
            item "New Window", Application::OpenNewWindowCommand
          end

          group(:priority => 10) do
            separator
            item "Close Tab", Application::CloseTabCommand
            item "Close Tree", Application::CloseTreeCommand
            item "Close Window", Application::CloseWindowCommand
            item "Close Others", Application::CloseOthers
            item "Close All", Application::CloseAll
          end

          group(:priority => :last) do
            separator
            item "Quit", Application::QuitCommand
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

              separator

              item "Forward Character",  ForwardCharCommand
              item "Backward Character", BackwardCharCommand
              item "Previous Line",      MoveUpCommand
              item "Next Line",          MoveDownCommand
              item "Open Line",          OpenLineCommand

              separator

              item "Delete Character",   DeleteCharCommand
              item "Backspace",          BackspaceCommand
              item "Transpose",          TransposeCharactersCommand
              
              separator
              
              item "Backward Navigation", BackwardNavigationCommand
              item "Forward Navigation", ForwardNavigationCommand
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
            item "Print Scope Tree", PrintScopeTreeCommand
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
            item "Toggle Fullscreen", :command => Application::ToggleFullscreen, :type => :check, :active => window ? window.fullscreen : false
          end
          group(:priority => 15) do
            separator
            sub_menu "Trees" do
              item "Open Tree Finder", Application::OpenTreeFinderCommand
              item "Toggle Tree Visibility", Application::ToggleTreesCommand
              item "Increase Tree Width", Application::IncreaseTreebookWidthCommand
              item "Decrease Tree Width", Application::DecreaseTreebookWidthCommand
              separator
              item "Previous Tree", Application::SwitchTreeUpCommand
              item "Next Tree", Application::SwitchTreeDownCommand
            end
            lazy_sub_menu "Windows" do
              GenerateWindowsMenu.new(self).run
            end
            sub_menu "Notebooks" do
              item "New Notebook", Application::OpenNewNotebookCommand
              item "Close Notebook", Application::CloseNotebookCommand
              item "Rotate Notebooks", Application::RotateNotebooksCommand
              item "Move Tab To Other Notebook", Application::MoveTabToOtherNotebookCommand
              item "Switch Notebooks", Application::SwitchNotebookCommand
              separator
              item "Enlarge First Notebook", Application::EnlargeNotebookCommand
              item "Reset Notebook Widths",  Application::ResetNotebookWidthsCommand
            end
            sub_menu "Tabs" do
              item "Previous Tab",   Application::SwitchTabDownCommand
              item "Next Tab",       Application::SwitchTabUpCommand
              item "Move Tab Left",  Application::MoveTabDownCommand
              item "Move Tab Right", Application::MoveTabUpCommand
              separator
              # GenerateTabsMenu.new(self).run # TODO: find a way to maintain keybindings with lazy menus
              item "Focussed Notebook", ShowTitle
              (1..9).each do |num|
                item "Tab #{num}", Application.const_get("SelectTab#{num}Command")
              end
            end
          end
          group(:priority => :last) do
            separator
            item "Show Toolbar", :command => Application::ToggleToolbar, :type => :check, :active => Redcar.app.show_toolbar?
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
        Application::CloseTabCommand.new(tab).run
      end

      def window_close(win)
        Application::CloseWindowCommand.new(win).run
      end

      def application_close(app)
        Application::QuitCommand.new.run
      end

      def window_focus(win)
        Application::FocusWindowCommand.new(win).run
      end
    end

    def self.application_event_handler
      ApplicationEventHandler.new
    end

    def self.start(args=[])
      begin
        Redcar.log.info("startup milestone: loading plugins took #{Time.now - Redcar.process_start_time}")
        Redcar.update_gui do
          Application.start
          ApplicationSWT.start
          EditViewSWT.start
          SplashScreen.splash_screen.inc(1) if SplashScreen.splash_screen
          s = Time.now
          if Redcar.gui
            Redcar.app.controller = ApplicationSWT.new(Redcar.app)
          end
          Redcar.app.refresh_menu!
          Redcar.app.load_sensitivities
          Redcar.log.info("initializing gui took #{Time.now - s}s")
        end
        Redcar.update_gui do
          SplashScreen.splash_screen.close if SplashScreen.splash_screen
          win = Redcar.app.make_sure_at_least_one_window_there
          Redcar.log.info("startup milestone: window open #{Time.now - Redcar.process_start_time}")
          Redcar::Project::Manager.start(args)
          Redcar.log.info("startup milestone: project open #{Time.now - Redcar.process_start_time}")
          win.show if win and !args.include?("--no-window")
        end
        Redcar.load_useful_libraries
        Redcar.log.info("startup milestone: complete: #{Time.now - Redcar.process_start_time}")
        if args.include?("--compute-textmate-cache-and-quit")
          Redcar::Textmate.all_bundles
          exit
        end
      rescue => e
        Redcar.log.error("error in startup: #{e.inspect}")
        e.backtrace.each do |line|
          Redcar.log.error(line)
        end
      end
    end
  end
end
