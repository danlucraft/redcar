module SwtHelper
  def main_menu
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    menu_bar = shell.get_menu_bar
    menu_bar
  end
  
  def first_shell
    Redcar::ApplicationSWT.display.get_shells.to_a.first
  end
  
  def sash_form 
    first_shell.getChildren.to_a.first
  end
  
  def tree_book
    sash_form.getChildren.to_a.first
  end
  
  def top_tree
    r = tree_book.getLayout.topControl
    r.extend(TreeHelpers)
    r
  end
  
  module TreeHelpers
    def items
      getItems.to_a
    end
    
    def item_texts
      getItems.to_a.map {|item| item.getText}
    end
  end
end
    
class FakeDialogAdapter
  def initialize
    @responses = {}
  end
  
  def set(method, value)
    @responses[method] = value
  end
  
  def open_file(*args)
    @responses[:open_file]
  end
  
  def open_directory(*args)
    @responses[:open_directory]
  end
  
  def save_file(*args)
    @responses[:save_file]
  end
end

World(SwtHelper)

def close_everything
  Redcar.app.windows.each do |win|
    while tree = win.treebook.trees.first
      Redcar::ApplicationSWT.sync_exec do
        win.treebook.remove_tree(tree)
      end
    end
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
  while Redcar.app.windows.length > 1
    Redcar::ApplicationSWT.sync_exec do
      Redcar.app.windows.last.close
    end
  end
end

Before do
  close_everything
end

After do
  close_everything
end







