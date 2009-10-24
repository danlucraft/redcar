
require "project/file_mirror"

module Redcar
  class Project
    class FileOpenCommand < Command
      key "Cmd+O"
    
      def execute
        tab = win.new_tab(Redcar::EditTab)
        dialog = Swt::Widgets::FileDialog.new(win.controller.shell, Swt::SWT::OPEN)
        dialog.set_filter_path(File.expand_path("~"))
        path = dialog.open
        puts "open file: " + path.to_s
        if path
          mirror = FileMirror.new(path)
          tab.edit_view.document.mirror = mirror
        end
        tab.focus
      end
    end
    
    class FileSaveCommand < Command
      key "Cmd+S"

      def execute
        tab = win.notebook.tabs.first
        puts "saving document"
        tab.edit_view.document.save!
      end
    end
  end
end