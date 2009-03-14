
module Redcar
  class AddDirectoryToProjectCommand < Command
    menu "Project/Add Directory"
    
    def initialize(dir=nil)
      @dirname = dir
    end
    
    def execute
      unless project_tab = ProjectPlugin.tab
	      project_tab = win.new_tab(ProjectTab)
	      project_tab.focus
			end
      @dirname ||= Redcar::Dialog.open_folder
      if @dirname
        project_tab.add_directory(@dirname.split("/").last, @dirname)
      end
    end
  end
end
