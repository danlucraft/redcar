
Redcar.menu("_View") do |menu|
  menu.command("Project View", :projview, nil, "<Alt>p") do
    if Redcar.project_sw.visible?
      Redcar.project_sw.hide
    else
      Redcar.project_sw.show
    end
  end
  
  menu.command("Go to Line", :goto_line, nil, "control l") do |pane, tab|
    if $sb_gotoline
      $sb_gotoline.close
      $sb_gotoline = nil
    else
      speedbar = Redcar::Speedbar.build(:title => "Go to line",
                                        :buttons => [:cancel, :ok],
                                        :entry => [
                                                   {:name => :line_num, :type => :text}
                                                  ])
      $sb_gotoline = speedbar
      speedbar.on_button(:cancel) do 
        $sb_gotoline.close
        $sb_gotoline = nil
      end
      speedbar.on_button(:ok) do 
        tab.cursor = tab.line_start(speedbar.line_num.to_i-1)
        speedbar.close
        tab.focus
      end
      speedbar.show
    end
  end
end
