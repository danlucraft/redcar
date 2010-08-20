module Redcar #TODO: Fix this!!!
  # This class implements the search-and-replace command
  class TextUtils
    # Create the search and replace menu item
    def self.menus
      # Here's how the plugin menus are drawn. Try adding more
      # items or sub_menus.
      Menu::Builder.build do
        sub_menu "Edit" do
          item "Toggle Block Comment", ToggleBlockCommentCommand
        end
      end
    end

    def self.keymaps
      osx = Redcar::Keymap.build("main", :osx) do
        link "Cmd+/", ToggleBlockCommentCommand
      end
      linwin = Redcar::Keymap.build("main", [:linux, :windows]) do
        link "Ctrl+/", ToggleBlockCommentCommand
      end
      [osx, linwin]
    end
    
    
    # Toggle block command.
    class ToggleBlockCommentCommand < Redcar::EditTabCommand
      # The execution reuses the same dialog.
	    def execute
          adoc = Redcar::app.focussed_notebook_tab.document
          comment = case Redcar::app.focussed_notebook_tab.edit_view.grammar
            when "Ruby" then "#"
            when "Ruby on Rails" then "#"
            when "Java" then "//"
            else "--"
          end
          end_pos = comment.length() -1
          range = adoc.selection_range
          start_line = adoc.line_at_offset(range.first)
          end_line = adoc.line_at_offset(range.last)
          (start_line..end_line).each do |line|
            text = adoc.get_line(line).chomp
            if text[0..end_pos] == comment then text = text[end_pos+1..-1] else text = comment + text end
            adoc.replace_line(line, text) #TODO: and fix this too!
          end
      end
    end
  end
end