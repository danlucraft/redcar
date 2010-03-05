require 'drb/drb'

require "project/project_command"
require "project/file_mirror"
require "project/find_file_dialog"
require "project/dir_mirror"
require "project/dir_controller"
require "project/drb_service"

module Redcar
  class Project

    # this will restore open files unless other files or dirs were passed
    # as command line parameters
    def self.start
      restore_last_session unless handle_startup_arguments
      init_current_files_hooks
      init_window_closed_hooks
      init_drb_listener
    end
    
    def self.init_window_closed_hooks
      Redcar.app.add_listener(:window_about_to_close) do |win|
        self.save_file_list win
      end
    end
    
    def self.init_drb_listener
      return if ARGV.include?("--multiple-instance")
      @drb_service = DrbService.new
    end
    
    def self.storage
      @storage ||= Plugin::Storage.new('project_plugin')
    end
    
    def self.sensitivities
      [ @open_project_sensitivity = 
          Sensitivity.new(:open_project, Redcar.app, false, [:focussed_window]) do
            if win = Redcar.app.focussed_window
              win.treebook.trees.detect {|t| t.tree_mirror.is_a?(DirMirror) }
            end
          end
      ]
    end
    
    class << self
      attr_reader :open_project_sensitivity
    end
  
    def self.filter_path
      if Redcar.app.focussed_notebook_tab
       if path = Redcar.app.focussed_notebook_tab.document.path
          dir = File.dirname(path)
          return dir
        end
      end      
      Project.storage['last_dir'] || File.expand_path(Dir.pwd)
    end
  
    def self.window_trees
      @window_trees ||= {}
    end
  
    def self.open_tree(win, tree)
      if window_trees[win]
        old_tree = window_trees[win]
        set_tree(win, tree)
        win.treebook.remove_tree(old_tree)
      else
        set_tree(win, tree)
      end
      Project.open_project_sensitivity.recompute
    end

    # Close the Directory Tree for the given window, if there 
    # is one.
    def self.close_tree(win)
      win.treebook.remove_tree(window_trees[win])
      Project.open_project_sensitivity.recompute
    end
    
    # Refresh the DirMirror Tree for the given Window, if 
    # there is one.
    def self.refresh_tree(win)
      if tree = window_trees[win]
        tree.refresh
      end
    end
    
    # Finds an EditTab with a mirror for the given path.
    #
    # @param [String] path  the path of the file being edited
    # @return [EditTab, nil] the EditTab that is editing it, or nil
    def self.open_file_tab(path)
      path = File.expand_path(path)
      all_tabs = Redcar.app.windows.map {|win| win.notebooks}.flatten.map {|nb| nb.tabs }.flatten
      all_tabs.find do |t| 
        t.is_a?(Redcar::EditTab) and 
        t.edit_view.document.mirror and 
        t.edit_view.document.mirror.is_a?(FileMirror) and 
        File.expand_path(t.edit_view.document.mirror.path) == path 
      end
    end
    
    # Opens a new EditTab with a FileMirror for the given path.
    #
    # @path  [String] path  the path of the file to be edited
    # @param [Window] win  the Window to open the File in
    def self.open_file(path, win = Redcar.app.focussed_window)
      win ||= Redcar.app.new_window # in case there's not one open
      tab = win.new_tab(Redcar::EditTab)
      mirror = FileMirror.new(path)
      tab.edit_view.document.mirror = mirror
      tab.edit_view.reset_undo
      tab.focus
    end
    
    # Opens a new Tree with a DirMirror and DirController for the given
    # path.
    #
    # @param [String] path  the path of the directory to view
    # @param [Window] win  the Window to open the Tree in
    def self.open_dir(path, win = Redcar.app.focussed_window)
      win ||= Redcar.app.new_window # case none open
      tree = Tree.new(Project::DirMirror.new(path),
                      Project::DirController.new)
      Project.open_tree(win, tree)
      # adds the directory path to the RecentDirectories plugin
      Redcar::RecentDirectories.store_path(path)
      storage['last_open_dir'] = path
    end
    
    # A list of files previously opened in this session
    #
    # @return [Array<String>] an array of paths
    def self.recent_files
      @recent_files ||= []
    end
    
    private
    
    # restores the directory/files in the last open window
    def self.restore_last_session
      if path = storage['last_open_dir']
        open_dir(path)
      end
      
      if files = Project.storage['files_open_last_session']
        files.each do |path|
          open_file(path)
        end
      end
      
    end
        
    # saves away a list of the currently open files in
    # @param [win]
    def self.save_file_list(win)
      # create a list of open files
      file_list = []
      win.notebooks[0].tabs.each do |tab|
        if tab.document && tab.document.path
          file_list << tab.document.path
        end
      end
      Project.storage['files_open_last_session'] = file_list      
    end
    
    # handles files and/or dirs passed as command line arguments
    def self.handle_startup_arguments
      if ARGV
        dir_args  = ARGV.select {|path| File.directory?(path) }
        file_args = ARGV.select {|path| File.file?(path)      }
        
        dir_args.each {|path| open_dir(path) }
        file_args.each {|path| open_file(path) }
        return (dir_args.any? or file_args.any?)
      end
    end
    
    # Attaches a new listener to tab focus change events, so we can 
    # keep the current_files list.
    def self.init_current_files_hooks
      Redcar.app.add_listener(:tab_focussed) do |tab|
        if tab and tab.document_mirror.respond_to?(:path)
          add_to_recent_files(tab.document_mirror.path)
        end
      end
    end
    
    def self.add_to_recent_files(new_file)
      # sanitize paths for doze
      # like "E:\\installs\\ruby191p376\\bin/rdebug.bat" => "E:/installs/ruby191p376/bin/rdebug.bat"
      new_file = File.expand_path(new_file) 
      unless new_file == @last_file
        recent_files.delete(new_file)
        recent_files << new_file
      
        if @last_file
          recent_files.delete(@last_file)
          recent_files.unshift(@last_file)
        end
      end

      @last_file = new_file
    end
    
    def self.set_tree(win, tree)
      @window_trees[win] = tree
      win.treebook.add_tree(tree)
    end
    
    class FileOpenCommand < Command
      
      def initialize(path = nil)
        @path = path
      end
    
      def execute
        path = get_path
        if path
          if already_open_tab = Project.open_file_tab(path)
            already_open_tab.focus
          else
            Project.open_file(path)
          end
        end
      end
      
      private
      
      def get_path
        @path || begin
          if path = Application::Dialog.open_file(win, :filter_path => Project.filter_path)
            Project.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end
    
    class FileSaveCommand < EditTabCommand

      def execute
        tab = win.focussed_notebook.focussed_tab
        if tab.edit_view.document.mirror
          tab.edit_view.document.save!
        else
          FileSaveAsCommand.new.run
        end
      end
    end
    
    class FileSaveAsCommand < EditTabCommand
      
      def initialize(path = nil)
        @path = path
      end

      def execute
        tab = win.focussed_notebook.focussed_tab
        path = get_path
        if path
          contents = tab.edit_view.document.to_s
          new_mirror = FileMirror.new(path)
          new_mirror.commit(contents)
          tab.edit_view.document.mirror = new_mirror
          Project.refresh_tree(win)
        end
      end
      
      private
      def get_path
        @path || begin
          if path = Application::Dialog.save_file(win, :filter_path => Project.filter_path)
            Project.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end
    
    class DirectoryOpenCommand < Command
          
      def initialize(path=nil)
        @path = path
      end
      
      def execute
        if path = get_path
          Project.open_dir(path, win)
        end
      end
      
      private

      def get_path
        @path || begin
          if path = Application::Dialog.open_directory(win, :filter_path => Project.filter_path)
            Project.storage['last_dir'] = File.dirname(File.expand_path(path))
            path
          end
        end
      end
    end
    
    class DirectoryCloseCommand < ProjectCommand

      def execute
        Project.close_tree(win)
      end
    end
    
    class RefreshDirectoryCommand < ProjectCommand
    
      def execute
        Project.refresh_tree(win)
      end
    end
    
    class FindFileCommand < ProjectCommand
     
      def execute
        dialog = FindFileDialog.new(win)
        dialog.open
      end
    end
    
  end
end
