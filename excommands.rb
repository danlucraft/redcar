
# Command Types

# ____ Straightforward
command "MyCommands/DoStuff" do 
  tab.insert(0, "foofoo")
end

# ____ Uses Speedbar
#
# Speedbar commands
#   label - displays a label
#   textbox - displays a named textbox
#   toggle - displays a named checkbox
#   button - displays a button
# Any of these (except label) can take a block, and will call that block
# when an appropriate event occurs.

command "MyCommands/Find" do
  speedbar do
    label   "Find:"
    textbox :find_text
    label   "Match _case"
    toggle  :match_case?, "Alt+C"
    label   "Match _word"
    toggle  :match_word?, "Alt+W"
    
    button  "Find _Next", "Alt+N || Return" do |sb|
      tab.find_next construct_regexp(sb)
    end
    
    button  "Find _Previous", "Alt+P" do |sb|
      tab.find_previous construct_regexp(sb)
    end
    
    def construct_regexp(sb)
      text = sb.find_text
      if sb.match_word?
        text = "\\b" + text + "\\b"
      end
      if sb.match_case?
        re = /#{text}/
      else
        re = /#{text}/i
      end
    end
  end
end


# ____ Uses Dialog

command "MyCommands/Go To File" do
  dialog.make_dialog_here

end

command :keymap => "Ctrl+Shift+P", :scope => "source" do
  (0..tab.num_lines).each do |n|
    tab.replace_line(n) do |line|
      line.gsub(/\s+$/, "")
    end
  end
end

keymap         :strip_trailing_whitespace, "Ctrl+Shift+P"
scope_selector :strip_trailing_whitespace, "source"
def strip_trailing_whitespace
  (0..tab.num_lines).each do |n|
    tab.replace_line(n) do |line|
      line.gsub(/\s+$/, "")
    end
  end
end
