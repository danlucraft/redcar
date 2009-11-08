RequireSupportFiles File.dirname(__FILE__) + "/../../../application/features/"

module SwtTabHelpers
  def get_tab_folder
    display = Redcar::ApplicationSWT.display
    shell   = display.get_shells.to_a.first
    tab_folder = shell.getChildren.to_a.first
  end

  def get_tab(tab_folder)
    item1 = tab_folder.getItems.to_a.first
    tab = Redcar.app.windows.first.notebook.tabs.detect{|t| t.controller.item == item1}
  end
end

World(SwtTabHelpers)

After do
  Redcar::ApplicationSWT.sync_exec do
    Redcar.app.windows.first.notebook.tabs.each {|tab| tab.close}
  end
end