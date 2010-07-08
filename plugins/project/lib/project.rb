require 'drb/drb'

require "project/commands"
require "project/dir_mirror"
require "project/dir_controller"
require "project/drb_service"
require "project/file_list"
require "project/file_mirror"
require "project/find_file_dialog"
require "project/manager"
require "project/recent_directories"

module Redcar
  class Project
    RECENT_FILES_LENGTH = 20
  
    def self.window_projects
      @window_projects ||= {}
    end
    
    attr_reader :window, :tree, :path

    def initialize(path)
      @path   = File.expand_path(path)
      dir_mirror = Project::DirMirror.new(path)
      if dir_mirror.exists?
        @tree   = Tree.new(dir_mirror, Project::DirController.new)
        @window = nil
        file_list_resource.compute
      end
    end
    
    def ready?
      @tree && @path
    end

    def inspect
      "<Project #{path}>"
    end
    
    def open(win)
      @window = win
      if current_project = Project.window_projects[window]
        current_project.close
      end
      window.treebook.add_tree(@tree)
      window.title = File.basename(@tree.tree_mirror.path)
      Manager.open_project_sensitivity.recompute
      RecentDirectories.store_path(path)
      Manager.storage['last_open_dir'] = path
      Project.window_projects[window] = self
    end
    
    def close
      window.treebook.remove_tree(@tree)
      Project.window_projects.delete(window)
      window.title = Window::DEFAULT_TITLE
      Manager.open_project_sensitivity.recompute
    end
    
    # Refresh the DirMirror Tree for the given Window, if 
    # there is one.
    def refresh
      @tree.refresh
      file_list_resource.compute
    end
    
    def contains_path?(path)
      File.expand_path(path) =~ /^#{@path}/
    end
    
    # A list of files previously opened in this session for this project
    #
    # @return [Array<String>] an array of paths
    def recent_files
      @recent_files ||= []
    end
    
    def add_to_recent_files(new_file)
      new_file = File.expand_path(new_file)
      if recent_files.include?(new_file)
        recent_files.delete(new_file)
      end
      recent_files << new_file
      if recent_files.length > RECENT_FILES_LENGTH
        recent_files.shift
      end
    end
    
    def file_list
      @file_list ||= FileList.new(path)
    end
    
    def file_list_resource
      @resource ||= Resource.new("refresh file list for #{@path}") do
        file_list.update
        send_refresh_to_plugins
      end
    end
    
    def refresh_modified_file(path)
      file_list.update(path)
      @tree.refresh
      send_refresh_to_plugins
    end
      
    def all_files
      file_list.all_files
    end
    
    def send_refresh_to_plugins
      Redcar.plugin_manager.objects_implementing(:project_refresh_task_type).each do |object|
        Redcar.app.task_queue.submit(object.project_refresh_task_type.new(self))
      end
    end
    
    def lost_application_focus
      @lost_application_focus = true
    end
    
    def gained_focus
      if @lost_application_focus
        refresh
      end
      @lost_application_focus = nil
    end
    
    def config_dir
      File.join(path, ".redcar")
    end
    
    def config_files(glob)
      file_glob = File.join(config_dir, glob)
      Dir[file_glob]
    end
  end
end
