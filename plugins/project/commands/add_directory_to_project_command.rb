
module Redcar
  class AddDirectoryToProjectCommand < Command
    menu "Project/Add Directory"
    
    def initialize(dir=nil)
      @dirname = dir
    end
    
    def execute
      unless project_tab = ProjectTab.instance
	      project_tab = win.new_tab(ProjectTab)
	      project_tab.focus
			end
			project_dir = project_tab.directories.last
		 
      @dirname ||=  project_dir ? Redcar::Dialog.open_folder(project_dir) : Redcar::Dialog.open_folder
      if @dirname
        project_tab.add_directory(@dirname.split("/").last, @dirname)
      end
    end
  end
end
