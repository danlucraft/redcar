
require "project/file_mirror"

module Redcar
  class Project
    class FileOpenCommand < Command
      key :osx     => "Cmd+O",
          :linux   => "Ctrl+O",
          :windows => "Ctrl+O"
    
      def execute
        tab = win.new_tab(Redcar::EditTab)
        path = Application::Dialog.open_file(win, :filter_path => File.expand_path("~"))
        puts "open file: " + path.to_s
        if path
          mirror = FileMirror.new(path)
          tab.edit_view.document.mirror = mirror
        end
        tab.focus
      end
    end
    
    class FileSaveCommand < EditTabCommand
      key :osx     => "Cmd+S",
          :linux   => "Ctrl+S",
          :windows => "Ctrl+S"

      def execute
        tab = win.notebook.focussed_tab
        puts "saving document"
        tab.edit_view.document.save!
      end
    end
  end
end
