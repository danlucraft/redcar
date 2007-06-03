
Redcar.menu("_Text") do |menu|
  menu.command("Duplicate", :duplicate, nil, "ctrl d") do |pane, tab|
    if tab.selected?
      tab.insert(tab.selection_bounds[0], tab.selection)
    else
      text = tab.get_line
      num  = tab.cursor_line
      tab.insert(tab.iter_at_line(num+1).offset, text)
    end
  end
  
  menu.submenu("Convert") do |submenu|
    submenu.command("UPPERCASE", :to_uppercase, nil, "ctrl t") do |pane, tab|
      if tab.selected?
        tab.replace_selection {|text| text.upcase}
      else
        tab.replace_line {|text| text.upcase}
      end
    end
    
    submenu.command("lowercase", :to_uppercase, nil, "ctrl t") do |pane, tab|
      if tab.selected?
        tab.replace_selection {|text| text.downcase}
      else
        tab.replace_line {|text| text.downcase}
      end
    end
    
    submenu.command("Title Case", :to_uppercase, nil, "ctrl t") do |pane, tab|
      if tab.selected?
        tab.replace_selection {|text| text.gsub(/\b([^\s]+)\b/) {|c| c[0..0].upcase+c[1..-1].downcase}}
      else
        tab.replace_line {|text| text.gsub(/\b([^\s]+)\b/) {|c| c[0..0].upcase+c[1..-1].downcase}}
      end
    end
    
    submenu.command("invert case", :to_uppercase, nil, "ctrl t") do |pane, tab|
      if tab.selected?
        tab.replace_selection {|text| text.swapcase}
      else
        tab.replace_line {|text| text.swapcase}
      end
    end
  end
  
end
  
