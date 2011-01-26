# require all the gems in vendor
Dir.glob(File.dirname(__FILE__) + "/../vendor/*").each do |path|
  gem_name = File.basename(path.gsub(/-[\d\.]+$/, ''))
  $LOAD_PATH << path + "/lib/"
end

unless defined?(DRb)
  require 'drb/drb'
end

require 'openssl'

require "project/adapters/remote_protocols/protocol"
require "project/adapters/remote_protocols/sftp"
require "project/adapters/remote_protocols/ftp"

require "project/adapters/local"
require "project/adapters/remote"

require "project/support/trash"

require "project/commands"
require "project/dir_mirror"
require "project/dir_controller"
require "project/project_tree_controller"
require "project/drb_service"
require "project/file_list"
require "project/file_mirror"
require "project/find_file_dialog"
require "project/find_recent_dialog"
require "project/manager"
require "project/recent"
require "project/sub_project"

module Redcar
  class Project
    RECENT_FILES_LENGTH = 20

    def self.window_projects
      @window_projects ||= {}
    end

    attr_reader :window, :tree, :path, :adapter
    attr_accessor :listeners

    def initialize(path, adapter=Adapters::Local.new)
      @adapter = adapter
      @path   = File.expand_path(path)
      @listeners ||= {}
      dir_mirror = Project::DirMirror.new(@path, adapter)
      if dir_mirror.exists?
        @tree   = Tree.new(dir_mirror, Project::DirController.new)
        @window = nil
        file_list_resource.compute unless remote?
      else
        raise "#{path} doesn't seem to exist"
      end
    end

    def remote?
      adapter.is_a?(Adapters::Remote)
    end

    def ready?
      @tree && @path
    end

    def inspect
      "<Project #{path}>"
    end

    def open(win)
      lock
      @window = win
      if current_project = Project.window_projects[window]
        current_project.close
      end
      window.treebook.add_tree(@tree)
      attach_listeners
      window.title = File.basename(@tree.tree_mirror.path)
      Manager.open_project_sensitivity.recompute
      Redcar.plugin_manager.objects_implementing(:project_loaded).each do |i|
        i.project_loaded(self)
      end
      Recent.store_path(path)
      Manager.storage['last_open_dir'] = path
      Project.window_projects[window] = self
    end
    
    def lock
      File.open(lock_filename, "w") do |fout|
        fout.puts "#{$$}: Locked by #{$$} at #{Time.now}"
      end
    end
    
    def lock_filename
      File.join(config_dir, "redcar.lock")
    end
    
    def locked?
      File.exist?(lock_filename)
    end
    
    def unlock
      if locked?
        if locked_by_this_process?
          FileUtils.rm_rf(lock_filename)
        else
          raise "locked by another process"
        end
      else
        raise "project not locked"
      end
    end
    
    def locked_by_this_process?
      return false unless locked?
      locking_pid = File.read(lock_filename).split(":").first
      locking_pid == $$.to_s
    end

    def close
      return unless @window
      this_window = window
      @window = nil
      this_window.treebook.remove_tree(@tree)
      Project.window_projects.delete(this_window)
      this_window.title = Window::DEFAULT_TITLE
      Manager.open_project_sensitivity.recompute
      Redcar.plugin_manager.objects_implementing(:project_closed).each do |i|
        i.project_closed(self)
      end
      listeners = {}
      unlock
    end

    def attach_listeners
      attach_notebook_listeners
      window.treebook.add_listener(:tree_removed, &method(:tree_removed))
    end

    def attach_notebook_listeners
      window.add_listener(:notebook_focussed, &method(:notebook_focussed))
      window.add_listener(:notebook_removed, &method(:notebook_closed))
      window.add_listener(:new_notebook, &method(:notebook_added))
      if notebooks = window.notebooks
        notebooks.each do |nb|
          notebook_added(nb)
        end
      end
    end

    def notebook_focussed(notebook)
      RevealInProjectCommand.new.run if notebook.focussed_tab && tree
    end

    def notebook_added(notebook)
      @listeners.merge!(notebook => notebook.add_listener(:tab_focussed) do |tab|
        RevealInProjectCommand.new.run if tree
      end)
    end

    def notebook_closed(notebook)
      @listeners.delete(notebook)
    end

    def tree_removed(tree)
      close if tree == @tree
    end

    # Refresh the DirMirror Tree for the given Window, if
    # there is one.
    def refresh
      @tree.refresh
      file_list_resource.compute unless remote?
    end

    def contains_path?(path)
      File.expand_path(path) =~ /^#{Regexp.escape(@path)}($|\/|\\)/
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
      raise "can't access a file list for a remote project" if remote?
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
        task = object.project_refresh_task_type.new(self)
        if Redcar::Resource.compute_synchronously
          task.execute
        else
          Redcar::Resource.task_queue.submit(task)
        end
      end
    end

    def lost_application_focus
      @lost_application_focus = true
    end

    def gained_focus
      refresh
      @lost_application_focus = nil
    end

    def config_dir
      dir = File.join(path, ".redcar")
      FileUtils.mkdir_p(dir)
      dir
    end

    def home_dir
      @path
    end

    def config_files(glob)
      file_glob = File.join("{#{config_dir},#{Redcar.user_dir}}", glob)
      Dir[file_glob]
    end
  end
end
