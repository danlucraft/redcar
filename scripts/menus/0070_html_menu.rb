
Redcar.menu("HTML") do |menu|
  menu.command("Insert Tag (From Current Word)", :insert_tag_from_current_word, 
               nil, "shift-super <") do |pane, tab|
    tag_name = nil
    if tab.selected?
      # use selection as tag name
      pre_off = tab.cursor_offset
      tag_name = tab.selection
      tab.delete_selection
    else
      # use previous word
      p tab.get_line
      if tab.get_line[0..(tab.cursor_line_offset-1)].reverse =~ /^(\w+)\b/
        tag_name = $1.reverse
        tab.delete(tab.cursor_offset-tag_name.length, tab.cursor_offset)
        pre_off = tab.cursor_offset
      end
    end
    if tag_name
      pre_tag  = "<#{tag_name}>"
      post_tag = "</#{tag_name}>"
      tab.insert(pre_off, pre_tag+post_tag)
      tab.cursor = pre_off+pre_tag.length
    end
  end
end
