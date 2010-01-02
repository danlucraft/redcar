
require "project/project_command"
require "project/file_mirror"
require "project/find_file_dialog"
require "project/dir_mirror"
require "project/dir_controller"

module Redcar
  class Project
    def self.load
    end
    
    def self.start
      @open_project_sensitivity = 
        Sensitivity.new(:open_project, Redcar.app, false, [:focussed_window]) do
          Redcar.app.focussed_window.treebook.trees.detect {|t| t.tree_mirror.is_a?(DirMirror) }
        end
    end
    
    class << self
      attr_reader :open_project_sensitivity
    end
  
    def self.open_tree(win, tree)
      @window_trees ||= {}
      if @window_trees[win]
        old_tree = @window_trees[win]
        set_tree(win, tree)
        win.treebook.remove_tree(old_tree)
      else
        set_tree(win, tree)
      end
      Project.open_project_sensitivity.recompute
    end
    
    def self.close_tree(win)
      win.treebook.remove_tree(@window_trees[win])
      Project.open_project_sensitivity.recompute
    end
    
    def self.refresh_tree(win)
      @window_trees[win].refresh
    end
    
    def self.open_file_tab(path)
      path = File.expand_path(path)
      all_tabs = Redcar.app.windows.map {|win| win.notebooks}.flatten.map {|nb| nb.tabs }.flatten
      all_tabs.find {|t| t.is_a?(Redcar::EditTab) and t.edit_view.document.mirror and File.expand_path(t.edit_view.document.mirror.path) == path }
    end
    
    private
    
    def self.set_tree(win, tree)
      @window_trees[win] = tree
      win.treebook.add_tree(tree)
    end
    
    class FileOpenCommand < Command
      key :osx     => "Cmd+O",
          :linux   => "Ctrl+O",
          :windows => "Ctrl+O"
      
      def initialize(path = nil)
        @path = path
      end
    
      def execute
        path = get_path
        if path
          if already_open_tab = Project.open_file_tab(path)
            already_open_tab.focus
          else
            tab  = win.new_tab(Redcar::EditTab)
            mirror = FileMirror.new(path)
            tab.edit_view.document.mirror = mirror
            tab.focus
          end
        end
      end
      
      private
      
      def get_path
        @path || begin
          path = Application::Dialog.open_file(win, :filter_path => File.expand_path("~"))
        end
      end
    end
    
    class FileSaveCommand < EditTabCommand
      key :osx     => "Cmd+S",
          :linux   => "Ctrl+S",
          :windows => "Ctrl+S"

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
      key :osx     => "Cmd+Shift+S",
          :linux   => "Ctrl+Shift+S",
          :windows => "Ctrl+Shift+S"
      
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
        end
      end
      
      private
      
      def get_path
        @path || begin
          path = Application::Dialog.save_file(win, :filter_path => File.expand_path("~"))
        end
      end
    end
    
    class DirectoryOpenCommand < Command
      key :osx     => "Cmd+Shift+O",
          :linux   => "Ctrl+Shift+O",
          :windows => "Ctrl+Shift+O"
          
      def initialize(path=nil)
        @path = path
      end
      
      def execute
        if path = get_path
          tree = Tree.new(Project::DirMirror.new(path),
                          Project::DirController.new)
          Project.open_tree(win, tree)
        end
      end
      
      private

      def get_path
        @path || begin
          if path = Application::Dialog.open_directory(win, :filter_path => File.expand_path("~"))
            File.expand_path(path)
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
      key :osx => "Cmd+T",
          :linux => "Ctrl+T",
          :windows => "Ctrl+T"
     
      def execute
        dialog = FindFileDialog.new
        dialog.open
      end
    end
  end
end
