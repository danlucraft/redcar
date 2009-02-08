
module Redcar
  class FindFileCommand < Command
    key "Super+T"
    menu "Project/Find File in Project..."
    sensitive :open_project
    norecord

    def execute
      dialog = FindFileDialog.new
      dialog.show_all
    end
  end
end
