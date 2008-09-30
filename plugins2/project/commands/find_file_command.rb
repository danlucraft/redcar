
module Redcar
  class FindFileCommand < Command
    key "Ctrl+Alt+F"
    menu "Project/Find File in Project..."
    sensitive :open_project

    def execute
      dialog = FindFileDialog.new
      dialog.show_all
    end
  end
end
