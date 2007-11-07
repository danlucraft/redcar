
Redcar.context_menu("Redcar::Pane") do |menu|
  menu.command("Move Right", :move_tab_right, :go_forward, "<ctl><shift>r") do |pane, tab|
    tab.position += 1
  end
  
  menu.command("Move Left", :move_tab_left, :go_back, "<ctl><shift>b") do |pane, tab|
    tab.position -= 1
  end
  
  menu.command("Close Other Tabs", :close_other_tabs, :close, "") do |pane, tab|
    pane.each do |thistab|
      unless thistab == tab
        thistab.close
      end
    end
  end
  
  menu.separator
  
  menu.command("Split Horizontal", :split_horizontal) do |pane, tab|
    pane.split_horizontal
  end
  
  menu.command("Split Vertical", :split_vertical) do |pane, tab|
    pane.split_vertical
  end

  menu.command("Unify", :pane_unify, nil, "") do |pane, tab|
    pane.unify
  end
  
  menu.separator
  
  menu.submenu "Tab Alignment" do |submenu|
    submenu.command("Top", :tabs_on_top, nil, "") do |pane, tab|
      pane.tab_position = :top
      pane.tab_angle    = :horizontal
    end
    submenu.command("Left", :tabs_on_left, nil, "") do |pane, tab|
      pane.tab_position = :left
      pane.tab_angle    = :bottom_to_top
    end
    submenu.command("Right", :tabs_on_right, nil, "") do |pane, tab|
      pane.tab_position = :right
      pane.tab_angle    = :top_to_bottom
    end
    submenu.command("Bottom", :tabs_on_bottom, nil, "") do |pane, tab|
      pane.tab_position = :bottom
      pane.tab_angle    = :horizontal
    end
  end
end
