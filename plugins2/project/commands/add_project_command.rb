
module Redcar
  class AddProjectCommand < Command
    menu "Project/Add Directory"
    
    def execute
      unless pt = ProjectPlugin.tab
	      new_tab = win.new_tab(ProjectTab)
	      new_tab.focus
			end
			dirname = Redcar::Dialog.open_folder
			pt.add_directory(dirname.split("/").last, dirname)
    end
  end
end
