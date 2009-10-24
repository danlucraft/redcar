RequireSupportFiles File.dirname(__FILE__) + "/../../../application/features/"

After do
  Redcar::ApplicationSWT.sync_exec do
    Redcar.app.windows.first.notebook.tabs.each {|tab| tab.close}
  end
end