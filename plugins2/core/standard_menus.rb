
module Redcar
  class TabCommand < Redcar::Command #:nodoc:
    sensitive :tab
  end
  
  class EditTabCommand < Redcar::Command #:nodoc:
    sensitive :edit_tab
  end
  
  class StandardMenus < Redcar::Plugin #:nodoc:all
    include Redcar::MenuBuilder
    extend Redcar::PreferenceBuilder
    
    class NewTab < Redcar::Command
      key "Global/Ctrl+N"
      icon :NEW
      
      def execute
        win.new_tab(EditTab).focus
      end
    end
    
    class OpenTab < Redcar::Command
      key "Global/Ctrl+O"
      icon :NEW
      
      def initialize(filename=nil)
        @filename = filename
      end
      
      def execute
        if !@filename 
          @filename = Redcar::Dialog.open 
        end
        if @filename and File.file?(@filename)
          new_tab = win.new_tab(Redcar::EditTab)
          new_tab.load(@filename)
          new_tab.focus
        end
      end
    end
    
    class SaveTab < Redcar::EditTabCommand
      key "Global/Ctrl+S"
      icon :SAVE
      sensitive :modified?
      
      def execute(tab)
        tab.save
      end
    end
    
    class RevertTab < Redcar::EditTabCommand
      icon :REVERT_TO_SAVED
      sensitive :modified?
      
      def execute(tab)
        filename = tab.filename
        tab.close
        OpenTab.new(filename).do
      end
    end
    
    class CloseTab < Redcar::TabCommand
      key "Global/Ctrl+W"
      icon :CLOSE
      
      def initialize(tab=nil)
        @tab = tab
      end
      
      def execute(tab)
        @tab ||= tab
        @tab.close if @tab
      end
    end
    
    class CloseAllTabs < Redcar::TabCommand
      key "Global/Ctrl+Super+W"
      icon :CLOSE
      
      def execute
        win.tabs.each &:close
      end
    end
    
    class Quit < Redcar::Command
      key "Global/Alt+F4"
      icon :QUIT
      
      def execute
        Redcar::App.quit
      end
    end
    
    class UnifyAll < Redcar::Command
      key "Global/Ctrl+1"
#      sensitive :multiple_panes
      
      def execute
        win.unify_all
      end
    end
    
    class SplitHorizontal < Redcar::Command
      key "Global/Ctrl+2"
      
      def execute(tab)
        if tab
          tab.pane.split_horizontal
        else
          win.panes.first.split_horizontal
        end
      end
    end
    
    class SplitVertical < Redcar::Command
      key "Global/Ctrl+3"
      
      def execute(tab)
        if tab
          tab.pane.split_vertical
        else
          win.panes.first.split_vertical
        end
      end
    end
    
    class PreviousTab < Redcar::TabCommand
      key "Global/Ctrl+Page_Down"
      
      def execute(tab)
        tab.pane.gtk_notebook.prev_page
      end
    end
    
    class NextTab < Redcar::TabCommand
      key "Global/Ctrl+Page_Up"
      
      def execute(tab)
        tab.pane.gtk_notebook.next_page
      end
    end
    
    class MoveTabDown < Redcar::TabCommand
      key "Global/Ctrl+Shift+Page_Down"
      
      def execute(tab)
        tab.move_down
      end
    end
    
    class MoveTabUp < Redcar::TabCommand
      key "Global/Ctrl+Shift+Page_Up"
      
      def execute(tab)
        tab.move_up
      end
    end
    
    class Undo < Redcar::EditTabCommand
      key  "Global/Ctrl+Z"
      
      def execute(tab)
        tab.doc.undo
      end
    end
    
    class Redo < Redcar::EditTabCommand
      key  "Global/Shift+Ctrl+Z"
      
      def execute(tab)
        tab.doc.redo
      end
    end
    
    class Cut < Redcar::EditTabCommand
      key       "Global/Ctrl+X"
#       sensitive :selected_text
      
      def execute(tab)
        tab.view.cut_clipboard
      end
    end
    
    class Copy < Redcar::EditTabCommand
      key       "Global/Ctrl+C"
#       sensitive :selected_text
      
      def execute(tab)
        tab.view.copy_clipboard
      end
    end
    
    class Paste < Redcar::EditTabCommand
      key  "Global/Ctrl+V"
      
      def execute(tab)
        tab.view.paste_clipboard
      end
    end
    
    class SelectLine < Redcar::EditTabCommand
      key  "Global/Super+Shift+L"
      
      def execute(tab)
        doc = tab.doc
        doc.select(doc.line_start(doc.cursor_line), 
                   doc.line_end(doc.cursor_line))
      end
    end
    
    class ForwardWord < Redcar::EditTabCommand
      key  "Global/Ctrl+F"
      icon :GO_FORWARD
      
      def execute(tab)
        tab.doc.forward_word
      end
    end
    
    class BackwardWord < Redcar::EditTabCommand
      key  "Global/Ctrl+B"
      icon :GO_BACK
      
      def execute(tab)
        tab.doc.backward_word
      end
    end
    
    class Find < Redcar::EditTabCommand
      key  "Global/Ctrl+F"
      icon :FIND
      norecord
      
      class FindSpeedbar < Redcar::Speedbar
        label "Find:"
        textbox :query_string
        button "Go", nil, "Return" do |sb|
          FindNextRegex.new(Regexp.new(sb.query_string)).do
        end
      end
  
      def execute(tab)
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
      
      def execute(tab)
        # first search the remainder of the current line
        curr_line = tab.doc.get_line.string
        curr_line = curr_line[tab.doc.cursor_line_offset..-1]
        if curr_line =~ @re
          line_iter = tab.doc.line_start(tab.doc.cursor_line)
          startoff = line_iter.offset + $`.length+tab.doc.cursor_line_offset
          endoff   = startoff + $&.length
          tab.doc.select(startoff, endoff)
        else
          # next search the rest of the lines
          line_num = tab.doc.cursor_line+1
          curr_line = tab.doc.get_line(line_num)
          until !curr_line or found = (curr_line.string =~ @re)
            line_num += 1
            curr_line = tab.doc.get_line(line_num)
          end
          if found
            line_iter = tab.doc.line_start(line_num)
            startoff = line_iter.offset + $`.length
            endoff   = startoff + $&.length
            tab.doc.select(startoff, endoff)
            unless tab.view.cursor_onscreen?
              tab.view.scroll_mark_onscreen(tab.doc.cursor_mark)
            end
          end
        end
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
      end
      submenu "Select" do
        item "Line",            SelectLine
      end
    end
      
    context_menu "Pane" do
      item "Split Horizontal",  SplitHorizontal
      item "Split Vertical",    SplitVertical
      item "Unify All",         UnifyAll
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
      values { EditView::Theme.theme_names }
      change do 
        win.tabs.each do |tab|
          if tab.respond_to? :view
            theme_name = Redcar::Preference.get("Appearance/Tab Theme")
            tab.view.change_theme(theme_name)
          end
        end
      end
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
    
    preference "Editing/Wrap words" do
      default true
      type    :toggle
      change do
        win.tabs.each do |tab|
          if tab.is_a? EditTab
            if Redcar::Preference.get("Editing/Wrap words")
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
