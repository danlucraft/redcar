
require "project/file_mirror"
require "project/dir_mirror"
require "project/dir_controller"

module Redcar
  class Project
    def self.open_tree(win, tree)
      @window_trees ||= {}
      if @window_trees[win]
        old_tree = @window_trees[win]
        set_tree(win, tree)
        win.treebook.remove_tree(old_tree)
      else
        set_tree(win, tree)
      end
    end
    
    def self.close_tree(win)
      win.treebook.remove_tree(@window_trees[win])
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
        tab  = win.new_tab(Redcar::EditTab)
        path = get_path
        if path
          puts "open file: " + path.to_s
          mirror = FileMirror.new(path)
          tab.edit_view.document.mirror = mirror
        end
        tab.focus
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
        puts "saving document"
        tab.edit_view.document.save!
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
        puts "saving document as #{path}"
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

      def execute
        tree = Tree.new(Project::DirMirror.new(get_path),
                        Project::DirController.new)
        Project.open_tree(win, tree)
      end
      
      private

      def get_path
        @path || begin
          path = Application::Dialog.open_directory(win, :filter_path => File.expand_path("~"))
          File.expand_path(path)
        end
      end
    end
    
    class DirectoryCloseCommand < Command

      def execute
        Project.close_tree(win)
      end
    end
  end
end
