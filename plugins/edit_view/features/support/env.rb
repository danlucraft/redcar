
module SwtTabHelpers
  def hide_toolbar
    Redcar.app.show_toolbar = false
    Redcar.app.refresh_toolbar!
  end

  def get_tab_folders(shell=active_shell)
    hide_toolbar
    right_composite = shell.children.to_a.last
    notebook_sash_form = right_composite.children.to_a[0]
    tab_folders = notebook_sash_form.children.to_a.select do |c| 
      c.class == Java::OrgEclipseSwtCustom::CTabFolder
    end
  end
  
  def get_tab_folder
    get_tab_folders.length.should == 1
    get_tab_folders.first
  end

  def get_browser_contents
    live_document = "document.getElementsByTagName('html')[0].innerHTML"
    r = focussed_tab.html_view.controller.execute("return #{live_document};").join('')
  end

  def get_tab(tab_folder)
    item1 = tab_folder.getItems.to_a.first
    tab = Redcar.app.windows.first.notebooks.map{|n| n.tabs}.flatten.detect{|t| t.controller.item == item1}
  end
  
  def focussed_tab
    # In case the focussed tab on the focussed window's notebook is empty, try another window
    Redcar.app.focussed_window.focussed_notebook.focussed_tab or Redcar.app.windows.map {|w| w.focussed_notebook.focussed_tab}.first
  end
  
  def get_tabs
    items = get_tab_folders.map{|f| f.getItems.to_a}.flatten
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
