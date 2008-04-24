
module Redcar
  class TabCommand < Redcar::Command #:nodoc:
    range Redcar::Tab
  end

  class EditTabCommand < Redcar::Command #:nodoc:
    range Redcar::EditTab
  end

  class RubyCommand < Redcar::EditTabCommand
    scope "source.ruby"
  end

  class StandardMenus < Redcar::Plugin #:nodoc:all
    include Redcar::MenuBuilder
    extend Redcar::PreferenceBuilder

    class NewTab < Redcar::Command
      key   "Ctrl+N"
      icon  :NEW

      def execute
        win.new_tab(EditTab).focus
      end
    end

    class OpenTab < Redcar::Command
      key "Ctrl+O"
      icon :NEW

      def initialize(filename=nil)
        @filename = filename
      end

      def execute
        if !@filename
          @filename = Redcar::Dialog.open(win)
        end
        if @filename and File.file?(@filename)
          new_tab = win.new_tab(Redcar::EditTab)
          new_tab.load(@filename)
          new_tab.focus
        end
      end
    end

    class SaveTab < Redcar::EditTabCommand
      key "Ctrl+S"
      icon :SAVE
      sensitive :modified?

      def execute
        tab.save
      end
    end

    class RevertTab < Redcar::EditTabCommand
      icon :REVERT_TO_SAVED
      sensitive :modified_and_filename?

      def execute
        filename = tab.filename
        tab.close
        OpenTab.new(filename).do
      end
    end

    class CloseTab < Redcar::TabCommand
      key "Ctrl+W"
      icon :CLOSE

      def initialize(tab=nil)
        @tab = tab
      end

      def execute
        @tab ||= tab
        @tab.close if @tab
      end
    end

    class CloseAllTabs < Redcar::TabCommand
      key "Ctrl+Super+W"
      icon :CLOSE

      def execute
        win.tabs.each &:close
      end
    end

    class Quit < Redcar::Command
      key "Alt+F4"
      icon :QUIT

      def execute
        Redcar::App.quit
      end
    end

    class UnifyAll < Redcar::Command
      key "Ctrl+1"
#      sensitive :multiple_panes

      def execute
        win.unify_all
      end
    end

    class SplitHorizontal < Redcar::Command
      key "Ctrl+2"

      def execute
        if tab
          tab.pane.split_horizontal
        else
          win.panes.first.split_horizontal
        end
      end
    end

    class SplitVertical < Redcar::Command
      key "Ctrl+3"

      def execute
        if tab
          tab.pane.split_vertical
        else
          win.panes.first.split_vertical
        end
      end
    end

    class PreviousTab < Redcar::TabCommand
      key "Ctrl+Page_Down"

      def execute
        tab.pane.gtk_notebook.prev_page
      end
    end

    class NextTab < Redcar::TabCommand
      key "Ctrl+Page_Up"

      def execute
        tab.pane.gtk_notebook.next_page
      end
    end

    class MoveTabDown < Redcar::TabCommand
      key "Ctrl+Shift+Page_Down"

      def execute
        tab.move_down
      end
    end

    class MoveTabUp < Redcar::TabCommand
      key "Ctrl+Shift+Page_Up"

      def execute
        tab.move_up
      end
    end

    class Undo < Redcar::EditTabCommand
      key  "Ctrl+Z"
      icon :UNDO

      def execute
        tab.view.undo
      end
    end

    class Redo < Redcar::EditTabCommand
      key  "Shift+Ctrl+Z"
      icon :REDO

      def execute
        tab.view.redo
      end
    end

    class Cut < Redcar::EditTabCommand
      key  "Ctrl+X"
      icon :CUT

      def execute
        if doc.selection?
          tab.view.cut_clipboard
        else
          n = doc.cursor_line
          doc.select(doc.iter(doc.line_start(n)),
                     doc.iter(doc.line_end(n)))
          tab.view.cut_clipboard
        end
      end
    end

    class Copy < Redcar::EditTabCommand
      key  "Ctrl+C"
      icon :COPY

      def execute
        if doc.selection?
          tab.view.copy_clipboard
        else
          n = doc.cursor_line
          c = doc.cursor_offset
          doc.select(doc.iter(doc.line_start(n)),
                     doc.iter(doc.line_end(n)))
          tab.view.copy_clipboard
          doc.cursor = c
        end
      end
    end

    class Paste < Redcar::EditTabCommand
      key  "Ctrl+V"
      icon :PASTE

      def execute
        if (cl = Redcar::App.clipboard).wait_is_text_available?
          str = cl.wait_for_text
          n = str.scan("\n").length+1
          l = doc.cursor_line
          doc.insert_at_cursor(str)
          if n > 1 and Redcar::Preference.get("Editing/Indent pasted text").to_bool
            n.times do |i|
              tab.view.indent_line(l+i)
            end
          end
        end
      end
    end

    class SelectLine < Redcar::EditTabCommand
      key  "Super+Shift+L"

      def execute
        doc.select(doc.line_start(doc.cursor_line),
                   doc.line_end(doc.cursor_line))
      end
    end

    class ForwardWord < Redcar::EditTabCommand
      key  "Ctrl+F"
      icon :GO_FORWARD

      def execute
        doc.forward_word
      end
    end

    class BackwardWord < Redcar::EditTabCommand
      key  "Ctrl+B"
      icon :GO_BACK

      def execute
        doc.backward_word
      end
    end

    class LineStart < Redcar::EditTabCommand
      key  "Ctrl+A"
      icon :GO_BACK

      def execute
        doc.place_cursor(doc.line_start(doc.cursor_line))
      end
    end

    class LineEnd < Redcar::EditTabCommand
      key  "Ctrl+E"
      icon :GO_FORWARD

      def execute
        doc.place_cursor(doc.line_end1(doc.cursor_line))
      end
    end

    class KillLine < Redcar::EditTabCommand
      key  "Ctrl+K"
      icon :DELETE

      def execute
        doc.delete(doc.cursor_iter,
                   doc.line_end1(doc.cursor_line))
      end
    end

    class Find < Redcar::EditTabCommand
      key  "Ctrl+F"
      icon :FIND
      norecord

      class FindSpeedbar < Redcar::Speedbar
        label "Find:"
        textbox :query_string
        button "Go", nil, "Return" do |sb|
          FindNextRegex.new(Regexp.new(sb.query_string)).do
        end
      end

      def execute
        sp = FindSpeedbar.instance
        sp.show(win)
      end
    end

    class FindNextRegex < Redcar::EditTabCommand
      def initialize(re)
        @re = re
      end

      def to_s
        "#{self.class}: @re=#{@re.inspect}"
      end

      def execute
        # first search the remainder of the current line
        curr_line = doc.get_line.string
        curr_line = curr_line[doc.cursor_line_offset..-1]
        if curr_line =~ @re
          line_iter = doc.line_start(doc.cursor_line)
          startoff = line_iter.offset + $`.length+doc.cursor_line_offset
          endoff   = startoff + $&.length
          doc.select(startoff, endoff)
        else
          # next search the rest of the lines
          line_num = doc.cursor_line+1
          curr_line = doc.get_line(line_num)
          until !curr_line or found = (curr_line.string =~ @re)
            line_num += 1
            curr_line = doc.get_line(line_num)
          end
          if found
            line_iter = doc.line_start(line_num)
            startoff = line_iter.offset + $`.length
            endoff   = startoff + $&.length
            doc.select(startoff, endoff)
            unless tab.view.cursor_onscreen?
              tab.view.scroll_mark_onscreen(doc.cursor_mark)
            end
          end
        end
      end
    end

    class IndentLine < Redcar::EditTabCommand
      key "Ctrl+Alt+["

      def execute
        tab.view.indent_line(doc.cursor_line)
      end
    end

    class ShowScope < Redcar::EditTabCommand
      key "Super+Shift+P"

      def execute
        if root = tab.view.parser.root
          scope = root.scope_at(TextLoc(doc.cursor_line, doc.cursor_line_offset))
        end
#         puts "scope_at_cursor: #{scope.inspect}"
# #         scope.root.display(0)
        inner = scope.pattern and scope.pattern.content_name and
          (doc.cursor_line_offset >= scope.open_end.offset and
           (!scope.close_start or doc.cursor_line_offset < scope.close_start.offset))
#         p scope.hierarchy_names(inner).join("\n")
        tab.view.tooltip_at_cursor(scope.hierarchy_names(inner).join("\n"))
      end
    end

    main_menu "File" do
      item "New",        NewTab
      item "Open",       OpenTab
      separator
      item "Save",       SaveTab
      item "Revert",     RevertTab
      separator
      item "Close",      CloseTab
      item "Close All",  CloseAllTabs
      item "Quit",       Quit
    end

    main_menu "Edit" do
      item "Undo",     Undo
      item "Redo",     Redo
      separator
      item "Cut",      Cut
      item "Copy",     Copy
      item "Paste",    Paste
      separator
      item "Find",     Find
      submenu "Move" do
        item "Forward Word",    ForwardWord
        item "Backward Word",   BackwardWord
        item "Line Start",    LineStart
        item "Line End",   LineEnd
      end
      item "Kill Line", KillLine
      separator
      item "Indent Line",    IndentLine
      item "Show Scope",     ShowScope
      separator
      submenu "Select" do
        item "Line",            SelectLine
      end
      separator
    end

    context_menu "Pane" do
      item "Split Horizontal",  SplitHorizontal
      item "Split Vertical",    SplitVertical
      item "Unify All",         UnifyAll
    end

    class EndLineReturn < Redcar::EditTabCommand
      key "Ctrl+Return"

      def execute
        doc.place_cursor(doc.line_end1(doc.cursor_line))
#        doc.insert_at_cursor("\n")
      end
    end

    class Tab < Redcar::EditTabCommand
      key "Global/Tab"

      def initialize(si=nil, buf=nil)
        @si = si
        @buf = buf
      end

      def execute
        @si ||= view.snippet_inserter
        @buf ||= doc
        if @si.tab_pressed
          # inserted a snippet
        else
          @buf.insert_at_cursor("\t")
        end
      end
    end

    class ShiftTab < Redcar::EditTabCommand
      key "Shift+Tab"

      def initialize(si=nil, buf=nil)
        @si = si
        @buf = buf
      end

      def execute
        @si ||= view.snippet_inserter
        @buf ||= doc
        if @si.shift_tab_pressed
          # within a snippet
        else
          @buf.insert_at_cursor("\t")
        end
      end
    end

    class RubyEnd < Redcar::RubyCommand
      key   "Ctrl+Alt+E"
      menu "Edit/Ruby End"
      def execute
        doc.insert_at_cursor("en")
        doc.type("d\n")
      end
    end

    preference "Appearance/Tab Font" do
      default "Monospace 12"
      widget  { StandardMenus.font_chooser_button("Appearance/Tab Font") }
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            tab.view.set_font(Redcar::Preference.get("Appearance/Tab Font"))
          end
        end
      end
    end

    preference "Appearance/Tab Theme" do |p|
      type :combo
      default "Mac Classic"
      values { EditView::Theme.theme_names.sort_by(&:downcase) }
#       change do
#         win.tabs.each do |tab|
#           if tab.respond_to? :view
#             theme_name = Redcar::Preference.get("Appearance/Tab Theme")
#             tab.view.change_theme(theme_name)
#           end
#         end
#       end
    end

    preference "Editing/Indent size" do |p|
      type    :integer
      bounds  [0, 20]
      step    1
      default 2
    end

    preference "Editing/Use spaces instead of tabs" do |p|
      default true
      type    :toggle
    end

    preference "Editing/Indent pasted text" do |p|
      default true
      type    :toggle
    end

    preference "Editing/Wrap words" do
      default true
      type    :toggle
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            if Redcar::Preference.get("Editing/Wrap words").to_bool
              tab.view.wrap_mode = Gtk::TextTag::WRAP_WORD
            else
              tab.view.wrap_mode = Gtk::TextTag::WRAP_NONE
            end
          end
        end
      end
    end

    preference "Editing/Show line numbers" do
      default true
      type    :toggle
      change do
        value = Redcar::Preference.get("Editing/Show line numbers").to_bool
        win.collect_tabs(EditTab).each do |tab|
          tab.view.show_line_numbers = value
        end
      end
    end

    def self.font_chooser_button(name)
      gtk_image = Gtk::Image.new(Gtk::Stock::SELECT_FONT,
                                 Gtk::IconSize::MENU)
      gtk_hbox = Gtk::HBox.new
      gtk_label = Gtk::Label.new(Redcar::Preference.get(name))
      gtk_hbox.pack_start(gtk_image, false)
      gtk_hbox.pack_start(gtk_label)
      widget = Gtk::Button.new
      widget.add(gtk_hbox)
      class << widget
        attr_accessor :preference_value
      end
      widget.preference_value = Redcar::Preference.get(name)
      widget.signal_connect('clicked') do
        dialog = Gtk::FontSelectionDialog.new("Select Application Font")
        dialog.font_name = widget.preference_value
        dialog.preview_text = "So say we all!"
        if dialog.run == Gtk::Dialog::RESPONSE_OK
          puts font = dialog.font_name
          font = dialog.font_name
          widget.preference_value = font
          gtk_label.text = font
        end
        dialog.destroy
      end
      widget
    end

  end
end

Coms = Redcar::StandardMenus
