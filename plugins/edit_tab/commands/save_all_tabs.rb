module Redcar
  class SaveAllTabsCommand < Redcar::TabCommand
    key "Ctrl+Super+S"
    icon :SAVE
    sensitive :open_edit_tabs

    def execute
      win.collect_tabs(Redcar::EditTab).each { |tab| tab.save }
    end
  end
end
