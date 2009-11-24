
require "project/file_mirror"

module Redcar
  class Project
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
  end
end
