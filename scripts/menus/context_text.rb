
Redcar.context_menu("Redcar::TextTab") do |menu|
  menu.command("_Undo", :context_undo, :undo, "") do
    Redcar.command(:undo)
  end
  
  menu.separator
  
  menu.command("Cu_t", :context_cut, :cut, "") do
    Redcar.command(:cut)
  end
  
  menu.command("_Copy", :context_copy, :copy, "") do
    Redcar.command(:copy)
  end
  
  menu.command("_Paste", :context_paste, :paste, "") do
    Redcar.command(:paste)
  end
  
  menu.separator
  
  menu.command("Select _All", :context_select_all, nil, "") do
    Redcar.command(:select_all)
  end  

end
