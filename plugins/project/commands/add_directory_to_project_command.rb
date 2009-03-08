
module Redcar
  class AddDirectoryToProjectCommand < Command
    menu "Project/Foo/Add Directory"
    
    def initialize(dir=nil)
      @dirname = dir
    end
    
    def execute
      unless pt = ProjectPlugin.tab
	      new_tab = win.new_tab(ProjectTab)
	      new_tab.focus
			end
      @dirname ||= Redcar::Dialog.open_folder
      if @dirname
        pt.add_directory(@dirname.split("/").last, @dirname)
      end
    end
  end
end
