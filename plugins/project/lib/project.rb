
require "project/file_mirror"

module Redcar
  class Project
    class FileOpenCommand < Command
      key "Cmd+O"
    
      def execute
        p :open
        tab = win.notebook.new_tab(Redcar::EditTab)
        dialog = Swt::Widgets::FileDialog.new(win.controller.shell, Swt::SWT::OPEN)
        dialog.set_filter_path("/home/danlucraft/")
        path = dialog.open
        puts "open file: " + path.to_s
        if path
          mirror = FileMirror.new(path)
          p mirror
          tab.edit_view.document.mirror = mirror
        end
        tab.focus
      end
    end
  end
end