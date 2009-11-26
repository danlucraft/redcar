RequireSupportFiles File.dirname(__FILE__) + "/../../../application/features/"

module SwtTabHelpers
  def get_tab_folder
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    sash_form = shell.getChildren.to_a.first
    tab_folders = sash_form.children.to_a
    tab_folders.length.should == 1
    tab_folders.first
  end

  def get_tab(tab_folder)
    item1 = tab_folder.getItems.to_a.first
    tab = Redcar.app.windows.first.notebooks.map{|n| n.tabs}.flatten.detect{|t| t.controller.item == item1}
  end
  
  def get_tabs
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    sash_form = shell.getChildren.to_a.first
    tab_folders = sash_form.children.to_a.select{|c| c.is_a? Swt::Custom::CTabFolder}
    items = tab_folders.map{|f| f.getItems.to_a}.flatten
    items.map {|i| model_tab_for_item(i)}
  end
  
  def model_tab_for_item(item)
    model_tabs.detect {|t| t.controller.item == item}
  end
  
  def model_tabs
    Redcar.app.windows.first.notebooks.map{|n| n.tabs}.flatten
  end
  
end

World(SwtTabHelpers)

def putsall
  p :all
  p Redcar.app.windows.first.notebooks
  p Redcar.app.windows.first.notebooks.first.tabs
  p Redcar.app.windows.first.notebooks.last.tabs
end

After do
  win = Redcar.app.windows.first
  win.notebooks.each do |notebook|
    while tab = notebook.tabs.first
      Redcar::ApplicationSWT.sync_exec do
        tab.close
      end
    end
  end
  if win.notebooks.length == 2
    Redcar::ApplicationSWT.sync_exec do
      win.close_notebook
    end
  end
end